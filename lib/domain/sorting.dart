import 'dart:math' as math;

import '../core/utils/formatters.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';
import '../data/services/keyword_categorizer.dart';
import 'money_moves.dart';
import 'natural_search.dart';

/// How Oobli decides what it can file on its own and what to ask about.
///
/// "Oobli files the small, obvious stuff; you decide the big and the unclear."
/// * Sure: the user's own merchant rules, sending money to yourself, message
///   types that only mean one thing (airtime, Fuliza, M-Shwari, cash
///   deposits, withdrawals), well-known merchants, and AI guesses with high
///   confidence on everyday amounts.
/// * Ask: big amounts (unless a rule or the message type settles it), money
///   from people, low-confidence guesses and anything filed as "Other".
abstract final class SortPolicy {
  /// Quick sort shows the last week by default; older items are optional.
  static const recentDays = 7;

  /// The AI must be at least this confident to file without asking.
  static const aiSureConfidence = 0.85;

  /// Never below this, so a quiet week doesn't make KES 300 "big".
  static const minBigAmount = 2000.0;

  /// The amount from which a spend counts as big for this user: the 90th
  /// percentile of their last 60 days of spending (at least KES 2,000).
  static double bigAmount(Iterable<Transaction> txs, DateTime now) {
    final cutoff = now.subtract(const Duration(days: 60));
    final amounts = [
      for (final t in txs)
        if (t.isOutgoing && t.occurredAt.isAfter(cutoff)) t.amount,
    ]..sort();
    if (amounts.length < 10) return minBigAmount;
    return math.max(minBigAmount, amounts[((amounts.length - 1) * 0.9).round()]);
  }

  static bool isBig(Transaction t, double bigAmount) => t.isOutgoing && t.amount >= bigAmount;

  /// Whether an AI guess is safe to file without asking.
  static bool aiIsSure(TxCategory category, double confidence, {required bool big}) =>
      !big && confidence >= aiSureConfidence && category != TxCategory.other;

  /// A category Oobli is certain of for an already-saved transaction, using
  /// only on-device knowledge; null when the user (or the AI) should decide.
  static TxCategory? certain(Transaction t, {required Map<String, TxCategory> rules, String? ownerName}) {
    final inbound = !t.isOutgoing;
    final ruled = rules[Transaction.merchantKey(t.merchant)];
    if (ruled != null && ruled.fits(inbound: inbound)) return ruled;
    if (MoneyMoves.isOwner(t.merchant, ownerName)) return TxCategory.ownTransfer;
    switch (t.channel) {
      case TxChannel.airtime:
        return TxCategory.airtime;
      case TxChannel.fuliza:
        return TxCategory.debt;
      case TxChannel.deposit:
        return TxCategory.ownTransfer;
      case TxChannel.withdraw:
        return t.category; // cash: nothing more to learn from the message
      default:
        break;
    }
    return KeywordCategorizer.categorize(merchant: t.merchant, channel: t.channel, direction: t.direction);
  }
}

/// Which transactions Quick sort shows, in what order.
abstract final class SortQueue {
  static bool isRecent(Transaction t, DateTime now) =>
      !t.occurredAt.isBefore(now.dateOnly.subtract(const Duration(days: SortPolicy.recentDays - 1)));

  /// Waiting for the user from the last week, newest first.
  static List<Transaction> recent(Iterable<Transaction> txs, DateTime now) =>
      _newestFirst(txs.where((t) => !t.confirmed && isRecent(t, now)));

  /// Waiting for the user from before that, newest first.
  static List<Transaction> older(Iterable<Transaction> txs, DateTime now) =>
      _newestFirst(txs.where((t) => !t.confirmed && !isRecent(t, now)));

  /// Today's biggest unsorted spend, if it is big for this user: the one
  /// worth asking about right on the home screen.
  static Transaction? bigOneToday(Iterable<Transaction> txs, DateTime now, double bigAmount) {
    final today = now.dateOnly;
    Transaction? best;
    for (final t in txs) {
      if (t.confirmed || !SortPolicy.isBig(t, bigAmount) || t.occurredAt.isBefore(today)) continue;
      if (best == null || t.amount > best.amount) best = t;
    }
    return best;
  }

  /// Every transaction (sorted or not) matching [query], newest first.
  /// Understands phrases like "boda last week" or "over 5k"; otherwise
  /// matches names, M-Pesa codes, notes, categories and amounts.
  static List<Transaction> search(Iterable<Transaction> txs, String query, DateTime now, {int limit = 150}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final filter = NaturalSearch.parse(q, now: now);
    final digits = q.replaceAll(RegExp(r'[,\s]'), '');
    final amount = RegExp(r'^\d+(\.\d+)?$').hasMatch(digits) ? digits : null;
    bool plain(Transaction t) {
      if (amount != null && t.amount.toStringAsFixed(0).contains(amount.split('.').first)) return true;
      final haystack = '${t.merchant} ${t.reference ?? ''} ${t.note ?? ''} ${t.category.label}'.toLowerCase();
      return q.split(RegExp(r'\s+')).every(haystack.contains);
    }

    return _newestFirst(txs.where(filter?.matches ?? plain)).take(limit).toList();
  }

  static List<Transaction> _newestFirst(Iterable<Transaction> txs) =>
      txs.toList()..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
}
