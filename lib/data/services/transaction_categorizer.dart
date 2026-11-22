import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import 'ai_service.dart';
import 'keyword_categorizer.dart';
import 'sms_parser.dart';

final transactionCategorizerProvider =
    Provider<TransactionCategorizer>((ref) => TransactionCategorizer(ref.watch(aiServiceProvider)));

/// Stable id for de-duplicating the same transaction across syncs.
String transactionFingerprint(ParsedTransaction p) {
  final key = p.reference != null && p.reference!.isNotEmpty
      ? '${p.source.key}|${p.reference}|${p.direction.name}|${p.amount.toStringAsFixed(2)}'
      : '${p.source.key}|${p.merchant.toLowerCase()}|${p.direction.name}|'
          '${p.amount.toStringAsFixed(2)}|'
          '${p.occurredAt.toUtc().toIso8601String().substring(0, 16)}';
  return sha256.convert(utf8.encode(key)).toString().substring(0, 40);
}

/// Categorises parsed transactions in three passes:
/// 1. the user's own corrections (merchant rules) — always win,
/// 2. message-type and keyword rules — instant and offline,
/// 3. Gemini (via the oobli-ai function) for everything else.
class TransactionCategorizer {
  TransactionCategorizer(this._ai);

  final AiService _ai;

  Future<List<Transaction>> categorize(
    List<ParsedTransaction> items, {
    required Map<String, TxCategory> rules,
  }) async {
    final results = List<Transaction?>.filled(items.length, null);
    final pending = <int>[];

    for (var i = 0; i < items.length; i++) {
      final p = items[i];
      final inbound = p.direction == TxDirection.inbound;
      // A rule learned for money in never relabels money out, and vice versa.
      final ruled = switch (rules[Transaction.merchantKey(p.merchant)]) {
        final c? when c.fits(inbound: inbound) => c,
        _ => null,
      };
      final known = ruled ?? p.category ??
          KeywordCategorizer.categorize(merchant: p.merchant, channel: p.channel, direction: p.direction);
      if (known != null) {
        results[i] = _toTransaction(p, known, confirmed: ruled != null);
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
              );
      }
    }
    return results.cast<Transaction>();
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
