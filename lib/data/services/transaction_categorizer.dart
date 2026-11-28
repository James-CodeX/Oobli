import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/money_moves.dart';
import '../../domain/sorting.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import 'ai_service.dart';
import 'keyword_categorizer.dart';
import 'sms_parser.dart';

final transactionCategorizerProvider =
    Provider<TransactionCategorizer>((ref) => TransactionCategorizer(ref.watch(aiServiceProvider)));

/// Stable id for de-duplicating the same transaction across syncs.
String transactionFingerprint(ParsedTransaction p) {
  final key = p.sameAs != null
      ? '${p.source.key}|${p.sameAs}'
      : p.reference != null && p.reference!.isNotEmpty
      ? '${p.source.key}|${p.reference}|${p.direction.name}|${p.amount.toStringAsFixed(2)}'
      : '${p.source.key}|${p.merchant.toLowerCase()}|${p.direction.name}|'
          '${p.amount.toStringAsFixed(2)}|'
          '${p.occurredAt.toUtc().toIso8601String().substring(0, 16)}';
  return sha256.convert(utf8.encode(key)).toString().substring(0, 40);
}

/// Categorises parsed transactions in three passes:
/// 1. the user's own corrections (merchant rules) — always win,
/// 2. message-type and keyword rules — instant and offline,
/// 3. Gemini (via the oobli-ai function) for everything else, in bulk.
///
/// What Oobli is sure of is filed as confirmed; only the rest waits in
/// Quick sort (see [SortPolicy]).
class TransactionCategorizer {
  TransactionCategorizer(this._ai);

  final AiService _ai;

  Future<List<Transaction>> categorize(
    List<ParsedTransaction> items, {
    required Map<String, TxCategory> rules,
    String? ownerName,
    double bigAmount = SortPolicy.minBigAmount,
  }) async {
    final results = List<Transaction?>.filled(items.length, null);
    final pending = <int>[];
    final ownMoves = _sameReference(items);

    for (var i = 0; i < items.length; i++) {
      final p = items[i];
      final inbound = p.direction == TxDirection.inbound;
      // M-Pesa sent it and the bank's message proves it landed in the user's
      // own account: settled without asking anyone, and before any rule.
      if (ownMoves.contains(i)) {
        results[i] = _toTransaction(p, TxCategory.ownTransfer, confirmed: true);
        continue;
      }
      // A rule learned for money in never relabels money out, and vice versa.
      final ruled = switch (rules[Transaction.merchantKey(p.merchant)]) {
        final c? when c.fits(inbound: inbound) => c,
        _ => null,
      };
      // Sending to (or receiving from) yourself is moving your own money.
      final self = MoneyMoves.isOwner(p.merchant, ownerName) ? TxCategory.ownTransfer : null;
      final known = ruled ?? self ?? p.category ??
          KeywordCategorizer.categorize(
              merchant: p.merchant, channel: p.channel, direction: p.direction, text: p.raw);
      if (known != null) {
        final guessed = ruled == null && self == null;
        // Money from a person could be pay, a refund or a loan back: ask.
        final unsure = guessed &&
            ((known == TxCategory.income && p.channel == TxChannel.received) ||
                (p.category != null && !p.categorySure));
        results[i] = _toTransaction(p, known, confirmed: !unsure);
      } else {
        pending.add(i);
      }
    }

    if (pending.isNotEmpty) {
      Map<String, AiCategory> ai = const {};
      try {
        ai = await _ai.categorize([
          for (final i in pending)
            {
              'id': '$i',
              'merchant': items[i].merchant,
              'channel': items[i].channel.key,
              'direction': items[i].isIncoming ? 'in' : 'out',
              'amount': items[i].amount,
              'raw': brief(items[i].raw),
            },
        ], rules: rules);
      } catch (e) {
        // Categorisation must never block saving the user's transactions.
        debugPrint('AI categorisation unavailable: $e');
      }
      for (final i in pending) {
        final guess = ai['$i'];
        final fits = guess != null && guess.category.fits(inbound: items[i].isIncoming);
        results[i] = !fits
            ? _toTransaction(items[i], _fallback(items[i]))
            : _toTransaction(
                items[i],
                guess.category,
                merchant: guess.merchant.isEmpty ? null : guess.merchant,
                aiCategorized: true,
                confirmed: SortPolicy.aiIsSure(
                  guess.category,
                  guess.confidence,
                  big: items[i].direction == TxDirection.out && items[i].amount >= bigAmount,
                ),
              );
      }
    }
    return results.cast<Transaction>();
  }

  /// Indexes of M-Pesa sends and the bank credits that carry their M-Pesa
  /// reference ("received in a/c ... M-PESA Ref X"): the user topping up
  /// their own account. See also [MoneyMoves.provenOwn].
  static Set<int> _sameReference(List<ParsedTransaction> items) {
    final credits = <String, int>{
      for (var i = 0; i < items.length; i++)
        if (items[i].source == TxSource.bank &&
            items[i].isIncoming &&
            items[i].category == TxCategory.ownTransfer &&
            items[i].reference != null)
          items[i].reference!: i,
    };
    final out = <int>{};
    for (var i = 0; i < items.length; i++) {
      final p = items[i];
      final credit = credits[p.reference];
      if (credit != null && p.source == TxSource.mpesa && !p.isIncoming) out.addAll([i, credit]);
    }
    return out;
  }

  static final _noise = RegExp(
    r'(?:New )?M-?PESA balance is (?:Ksh|KES)\s?[\d,]+(?:\.\d+)?\.?|'
    r'Transaction cost,? (?:Ksh|KES)\.?\s?[\d,]+(?:\.\d+)?\.?|'
    r'Amount you can transact within the day is (?:Ksh|KES)\s?[\d,]+(?:\.\d+)?\.?|'
    r'To reverse,? forward this SMS to \d+\.?|PIN yako,? SIRI yako\.?',
    caseSensitive: false,
  );

  /// The part of a message that says what happened, for the AI: balances,
  /// costs and slogans only cost tokens.
  @visibleForTesting
  static String brief(String raw) {
    final s = raw.replaceAll(_noise, '').replaceAll(RegExp(r'\s+'), ' ').trim();
    return s.length > 200 ? s.substring(0, 200) : s;
  }

  static TxCategory _fallback(ParsedTransaction p) => switch (p.channel) {
        _ when p.direction == TxDirection.inbound => TxCategory.income,
        TxChannel.send || TxChannel.pochi => TxCategory.transfer,
        _ => TxCategory.other,
      };

  static Transaction _toTransaction(
    ParsedTransaction p,
    TxCategory category, {
    String? merchant,
    bool aiCategorized = false,
    bool confirmed = false,
  }) =>
      Transaction(
        id: '',
        fingerprint: transactionFingerprint(p),
        amount: p.amount,
        direction: p.direction,
        merchant: merchant ?? p.merchant,
        category: category,
        channel: p.channel,
        source: p.source,
        occurredAt: p.occurredAt,
        reference: p.reference,
        rawMessage: p.raw,
        aiCategorized: aiCategorized,
        confirmed: confirmed,
        balance: p.balance,
      );
}

extension on ParsedTransaction {
  bool get isIncoming => direction == TxDirection.inbound;
}
