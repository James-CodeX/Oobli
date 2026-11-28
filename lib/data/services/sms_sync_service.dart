import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/sorting.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import 'ai_service.dart';
import 'sms_inbox_service.dart';
import 'sms_parser.dart';
import 'transaction_categorizer.dart';

final smsSyncServiceProvider = Provider<SmsSyncService>(
  (ref) => SmsSyncService(
    inbox: ref.watch(smsInboxServiceProvider),
    ai: ref.watch(aiServiceProvider),
    categorizer: ref.watch(transactionCategorizerProvider),
    repository: ref.watch(transactionRepositoryProvider),
  ),
);

@immutable
class SyncResult {
  const SyncResult({required this.scanned, required this.added});

  final int scanned;
  final List<Transaction> added;
}

/// Reads new financial SMS, turns them into categorised transactions and
/// stores them in Appwrite (duplicates are skipped by fingerprint).
class SmsSyncService {
  SmsSyncService({
    required this._inbox,
    required this._ai,
    required this._categorizer,
    required this._repository,
  });

  final SmsInboxService _inbox;
  final AiService _ai;
  final TransactionCategorizer _categorizer;
  final TransactionRepository _repository;

  static final _moneyWords = RegExp(
    r'(ksh|kes)\s?[\d,]+.*(debited|credited|sent|paid|received|withdrawn|purchase|'
    r'transferred|deposited|payment)|(debited|credited|sent|paid|received|withdrawn|purchase|'
    r'transferred|deposited|payment).*(ksh|kes)\s?[\d,]+',
    caseSensitive: false,
  );

  Future<SyncResult> sync({
    required String userId,
    required DateTime since,
    required Map<String, TxCategory> rules,
    String? ownerName,
    double? bigAmount,
  }) async {
    final messages = await _inbox.readFinancialMessages(since: since);
    final parsed = <ParsedTransaction>[];
    final needsAi = <SmsMessage>[];

    for (final sms in messages) {
      if (!FinancialSenders.isFinancial(sms.sender)) continue;
      final isMpesa = FinancialSenders.isMpesa(sms.sender);
      // Bank offers and notices: nothing to record, and no AI call.
      if (!isMpesa && BankParser.isNoise(sms)) continue;
      final p = isMpesa ? MpesaParser.parse(sms) : BankParser.parse(sms);
      if (p != null) {
        parsed.add(p);
        continue;
      }
      if (_moneyWords.hasMatch(sms.body)) needsAi.add(sms);
    }

    if (needsAi.isNotEmpty) parsed.addAll(await _parseWithAi(needsAi));

    // The same SMS can be read twice across overlapping syncs, and a bank can
    // send two messages for one payment: keep one, preferably with a code.
    final unique = <String, ParsedTransaction>{};
    for (final p in parsed) {
      unique.update(
        transactionFingerprint(p),
        (kept) => kept.reference == null && p.reference != null ? p : kept,
        ifAbsent: () => p,
      );
    }

    final transactions = await _categorizer.categorize(
      unique.values.toList(),
      rules: rules,
      ownerName: ownerName,
      bigAmount: bigAmount ?? SortPolicy.minBigAmount,
    );
    final added = await _repository.createMany(userId, transactions);
    return SyncResult(scanned: messages.length, added: added);
  }

  Future<List<ParsedTransaction>> _parseWithAi(List<SmsMessage> messages) async {
    final byId = {for (final m in messages) m.id: m};
    try {
      final extracted = await _ai.parseSms(messages);
      return [
        for (final entry in extracted.entries)
          if (byId[entry.key] case final sms?) _fromAi(entry.value, sms),
      ];
    } catch (e) {
      // Bank parsing is best-effort; M-Pesa messages were already handled on-device.
      debugPrint('AI SMS parsing unavailable: $e');
      return const [];
    }
  }

  static ParsedTransaction _fromAi(Map<String, dynamic> v, SmsMessage sms) {
    final merchant = (v['merchant'] as String? ?? '').trim();
    final reference = (v['reference'] as String? ?? '').trim();
    final balance = (v['balance'] as num?)?.toDouble();
    final category = TxCategory.fromKey(v['category'] as String?);
    return ParsedTransaction(
      amount: (v['amount'] as num).toDouble(),
      direction: v['direction'] == 'in' ? TxDirection.inbound : TxDirection.out,
      merchant: merchant.isEmpty ? sms.sender : merchant,
      channel: TxChannel.fromKey(v['channel'] as String?),
      source: FinancialSenders.isMpesa(sms.sender) ? TxSource.mpesa : TxSource.bank,
      occurredAt: DateTime.tryParse(v['occurredAt'] as String? ?? '')?.toLocal() ?? sms.receivedAt,
      raw: sms.body,
      reference: reference.isEmpty ? null : reference,
      balance: balance == null || balance < 0 ? null : balance,
      // "other" from the parser means "unsure": let the categoriser decide.
      category: category == TxCategory.other ? null : category,
    );
  }
}
