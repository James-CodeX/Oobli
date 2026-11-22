import '../core/utils/formatters.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';

enum BillCadence {
  weekly(7, 'weekly'),
  monthly(30, 'monthly');

  const BillCadence(this.days, this.label);

  final int days;
  final String label;
}

/// A payment that repeats on a schedule (rent, KPLC, Netflix, chama...).
class Bill {
  const Bill({
    required this.merchant,
    required this.category,
    required this.amount,
    required this.cadence,
    required this.lastPaid,
    required this.nextDue,
    required this.count,
  });

  final String merchant;
  final TxCategory category;

  /// Typical amount (median of recent payments).
  final double amount;
  final BillCadence cadence;
  final DateTime lastPaid;
  final DateTime nextDue;

  /// How many payments the pattern is based on.
  final int count;

  int daysUntil(DateTime today) => nextDue.dateOnly.difference(today.dateOnly).inDays;
}

/// Bills due soon plus the last known M-Pesa balance, for "will I cover it?".
class BillForecast {
  const BillForecast({required this.upcoming, required this.today, this.balance, this.balanceAt});

  static const empty = BillForecast(upcoming: [], today: null);

  /// Due within the horizon (or a few days overdue), soonest first.
  final List<Bill> upcoming;
  final DateTime? today;

  /// Balance from the most recent SMS that reported one.
  final double? balance;
  final DateTime? balanceAt;

  double dueWithin(int days) => upcoming
      .where((b) => today != null && b.daysUntil(today!) <= days)
      .fold(0.0, (s, b) => s + b.amount);

  /// How much more is due in the next [days] than the balance covers.
  double? shortfall({int days = 7}) {
    final due = dueWithin(days);
    if (balance == null || due <= balance!) return null;
    return due - balance!;
  }
}

/// Finds repeating payments and predicts the next one. Purely local, so it
/// works offline and costs nothing.
abstract final class BillPredictor {
  /// Only these categories can be bills; groceries every week is a habit, not a bill.
  static const _billLike = {
    TxCategory.rent,
    TxCategory.utilities,
    TxCategory.entertainment,
    TxCategory.education,
    TxCategory.airtime,
    TxCategory.debt,
    TxCategory.savings,
    TxCategory.transfer,
    TxCategory.health,
  };

  /// Categories where a weekly rhythm is a commitment (chama, weekly bundles).
  static const _weeklyOk = {TxCategory.savings, TxCategory.debt, TxCategory.transfer, TxCategory.airtime};

  static List<Bill> detect(Iterable<Transaction> transactions, {required DateTime now}) {
    final groups = <String, List<Transaction>>{};
    for (final t in transactions) {
      if (!t.isOutgoing || !_billLike.contains(t.category)) continue;
      final key = Transaction.merchantKey(t.merchant);
      if (key.isEmpty) continue;
      groups.putIfAbsent(key, () => []).add(t);
    }

    final today = now.dateOnly;
    final bills = <Bill>[];
    for (final txs in groups.values) {
      final payments = _collapse(txs);
      if (payments.length < 2) continue;

      final recent = payments.length > 3 ? payments.sublist(payments.length - 3) : payments;
      final amount = _median(recent.map((t) => t.amount).toList());
      if (recent.any((t) => (t.amount - amount).abs() > amount * 0.35)) continue;

      final gaps = [
        for (var i = 1; i < payments.length; i++)
          payments[i].occurredAt.dateOnly.difference(payments[i - 1].occurredAt.dateOnly).inDays,
      ];
      final category = payments.last.category;
      final cadence = _cadence(gaps, weeklyOk: _weeklyOk.contains(category));
      if (cadence == null) continue;
      // Two payments are enough for a steady monthly bill; otherwise want three.
      if (payments.length < 3 && cadence == BillCadence.weekly) continue;

      final last = payments.last.occurredAt;
      final next = cadence == BillCadence.monthly ? _nextMonth(last) : last.add(const Duration(days: 7));
      // Missed by more than half a cycle: the bill has probably stopped.
      if (today.difference(next.dateOnly).inDays > cadence.days ~/ 2) continue;

      bills.add(Bill(
        merchant: payments.last.merchant,
        category: category,
        amount: amount,
        cadence: cadence,
        lastPaid: last,
        nextDue: next,
        count: payments.length,
      ));
    }
    bills.sort((a, b) => a.nextDue.compareTo(b.nextDue));
    return bills;
  }

  static BillForecast forecast(List<Transaction> transactions, {required DateTime now, int horizonDays = 14}) {
    final today = now.dateOnly;
    final upcoming = detect(transactions, now: now)
        .where((b) => b.daysUntil(today) >= -3 && b.daysUntil(today) <= horizonDays)
        .toList();
    Transaction? latest;
    for (final t in transactions) {
      if (t.balance == null || t.source == TxSource.manual) continue;
      if (latest == null || t.occurredAt.isAfter(latest.occurredAt)) latest = t;
    }
    return BillForecast(upcoming: upcoming, today: today, balance: latest?.balance, balanceAt: latest?.occurredAt);
  }

  /// Several payments within 3 days are one bill payment (split or retried).
  static List<Transaction> _collapse(List<Transaction> txs) {
    final sorted = [...txs]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final out = <Transaction>[];
    for (final t in sorted) {
      if (out.isNotEmpty && t.occurredAt.difference(out.last.occurredAt).inDays < 3) {
        final prev = out.removeLast();
        out.add(t.copyWith(amount: prev.amount + t.amount));
      } else {
        out.add(t);
      }
    }
    return out;
  }

  static BillCadence? _cadence(List<int> gaps, {required bool weeklyOk}) {
    bool fits(int lo, int hi) => gaps.where((g) => g >= lo && g <= hi).length >= (gaps.length * 0.75).ceil();
    if (fits(26, 35)) return BillCadence.monthly;
    if (weeklyOk && fits(6, 8)) return BillCadence.weekly;
    return null;
  }

  static DateTime _nextMonth(DateTime d) {
    final lastDay = DateTime(d.year, d.month + 2, 0).day;
    return DateTime(d.year, d.month + 1, d.day > lastDay ? lastDay : d.day, d.hour, d.minute);
  }

  static double _median(List<double> xs) {
    final s = [...xs]..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) / 2;
  }
}
