import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../data/models/category.dart';
import '../data/models/goal.dart';
import '../data/models/plan.dart';
import '../data/models/transaction.dart';

enum FlowRange {
  week('This Week'),
  month('Last Month'),
  year('Yearly');

  const FlowRange(this.label);

  final String label;
}

@immutable
class SeriesPoint {
  const SeriesPoint(this.label, this.value);

  final String label;
  final double value;
}

@immutable
class Recipient {
  const Recipient({required this.merchant, required this.total, required this.count, required this.category});

  final String merchant;
  final double total;
  final int count;
  final TxCategory category;
}

/// Pure, synchronous analytics over the user's transactions. Everything the
/// charts, insights and AI prompts need is derived here (and unit tested).
class SpendingStats {
  SpendingStats(List<Transaction> transactions, {DateTime? now})
      : now = now ?? DateTime.now(),
        all = List.unmodifiable(
          [...transactions]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)),
        );

  final DateTime now;

  /// Newest first.
  final List<Transaction> all;

  DateTime get today => now.dateOnly;

  Iterable<Transaction> _spendsBetween(DateTime start, DateTime end) =>
      all.where((t) => t.isSpend && !t.occurredAt.isBefore(start) && t.occurredAt.isBefore(end));

  double spentBetween(DateTime start, DateTime end) =>
      _spendsBetween(start, end).fold(0, (s, t) => s + t.amount);

  double spentOn(DateTime day) => spentBetween(day.dateOnly, day.dateOnly.add(const Duration(days: 1)));

  double get spentToday => spentOn(today);

  double incomeBetween(DateTime start, DateTime end) => all
      .where((t) => !t.isOutgoing && t.category == TxCategory.income &&
          !t.occurredAt.isBefore(start) && t.occurredAt.isBefore(end))
      .fold(0, (s, t) => s + t.amount);

  double savedBetween(DateTime start, DateTime end) => all
      .where((t) => t.category == TxCategory.savings &&
          !t.occurredAt.isBefore(start) && t.occurredAt.isBefore(end))
      .fold(0, (s, t) => s + (t.isOutgoing ? t.amount : -t.amount));

  /// Daily spend for the last [days] days, oldest first, ending today.
  List<SeriesPoint> lastDays(int days) => [
        for (var i = days - 1; i >= 0; i--)
          () {
            final day = today.subtract(Duration(days: i));
            return SeriesPoint(Fmt.weekdayLetter(day), spentOn(day));
          }(),
      ];

  /// Rolling 7-day spend vs the 7 days before it (e.g. -0.12 = 12% lower).
  double? get weekOverWeekChange {
    final end = today.add(const Duration(days: 1));
    final thisWeek = spentBetween(end.subtract(const Duration(days: 7)), end);
    final lastWeek = spentBetween(
      end.subtract(const Duration(days: 14)),
      end.subtract(const Duration(days: 7)),
    );
    if (lastWeek <= 0) return null;
    return (thisWeek - lastWeek) / lastWeek;
  }

  /// Today vs the same weekday last week.
  double? get sameDayLastWeekChange {
    final last = spentOn(today.subtract(const Duration(days: 7)));
    if (last <= 0) return null;
    return (spentToday - last) / last;
  }

  ({DateTime start, DateTime end}) rangeFor(FlowRange range) {
    final end = today.add(const Duration(days: 1));
    return switch (range) {
      FlowRange.week => (start: end.subtract(const Duration(days: 7)), end: end),
      FlowRange.month => (start: end.subtract(const Duration(days: 28)), end: end),
      FlowRange.year => (start: DateTime(today.year - 1, today.month + 1), end: end),
    };
  }

  List<SeriesPoint> series(FlowRange range) {
    switch (range) {
      case FlowRange.week:
        return lastDays(7);
      case FlowRange.month:
        final end = today.add(const Duration(days: 1));
        return [
          for (var w = 3; w >= 0; w--)
            SeriesPoint(
              'W${4 - w}',
              spentBetween(
                end.subtract(Duration(days: 7 * (w + 1))),
                end.subtract(Duration(days: 7 * w)),
              ),
            ),
        ];
      case FlowRange.year:
        return [
          for (var m = 11; m >= 0; m--)
            () {
              final start = DateTime(today.year, today.month - m);
              final end = DateTime(today.year, today.month - m + 1);
              return SeriesPoint(Fmt.monthName(start).substring(0, 1), spentBetween(start, end));
            }(),
        ];
    }
  }

  Map<TxCategory, double> byCategory(DateTime start, DateTime end) {
    final out = <TxCategory, double>{};
    for (final t in _spendsBetween(start, end)) {
      out[t.category] = (out[t.category] ?? 0) + t.amount;
    }
    return _sorted(out);
  }

  Map<TxChannel, double> byChannel(DateTime start, DateTime end) {
    final out = <TxChannel, double>{};
    for (final t in _spendsBetween(start, end)) {
      out[t.channel] = (out[t.channel] ?? 0) + t.amount;
    }
    return _sorted(out);
  }

  static Map<K, double> _sorted<K>(Map<K, double> m) =>
      Map.fromEntries(m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));

  /// People/traders the user sends to most (Send Money + Pochi), largest first.
  List<Recipient> topRecipients(DateTime start, DateTime end, {int limit = 5}) {
    final groups = <String, List<Transaction>>{};
    for (final t in _spendsBetween(start, end)) {
      if (t.channel != TxChannel.send && t.channel != TxChannel.pochi) continue;
      groups.putIfAbsent(Transaction.merchantKey(t.merchant), () => []).add(t);
    }
    final list = groups.values
        .map((txs) => Recipient(
              merchant: txs.first.merchant,
              total: txs.fold(0, (s, t) => s + t.amount),
              count: txs.length,
              category: txs.first.category,
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list.take(limit).toList();
  }

  /// Merchants charged in at least two different months with near-equal
  /// amounts in entertainment/utilities: likely subscriptions.
  List<({String merchant, double amount, DateTime last})> recurringCharges() {
    final groups = <String, List<Transaction>>{};
    for (final t in all) {
      if (!t.isSpend) continue;
      if (t.category != TxCategory.entertainment && t.category != TxCategory.utilities) continue;
      groups.putIfAbsent(Transaction.merchantKey(t.merchant), () => []).add(t);
    }
    final out = <({String merchant, double amount, DateTime last})>[];
    for (final txs in groups.values) {
      final months = txs.map((t) => Fmt.monthKey(t.occurredAt)).toSet();
      if (months.length < 2) continue;
      final first = txs.first.amount;
      if (txs.every((t) => (t.amount - first).abs() <= first * 0.1)) {
        out.add((merchant: txs.first.merchant, amount: first, last: txs.first.occurredAt));
      }
    }
    return out;
  }

  /// Average spend per weekday (1 = Monday) over the last 8 weeks.
  Map<int, double> weekdayAverages() {
    final start = today.subtract(const Duration(days: 56));
    final totals = <int, double>{};
    for (final t in _spendsBetween(start, today.add(const Duration(days: 1)))) {
      totals[t.occurredAt.weekday] = (totals[t.occurredAt.weekday] ?? 0) + t.amount;
    }
    return totals.map((k, v) => MapEntry(k, v / 8));
  }

  int get aiCategorizedCount => all.where((t) => t.aiCategorized).length;

  int get needsReviewCount => all.where((t) => t.needsReview).length;

  /// Share of AI categorisations the user kept (corrections are counted in prefs).
  double aiAccuracy(int corrections) {
    final ai = aiCategorizedCount;
    if (ai + corrections == 0) return 1;
    return ai / (ai + corrections);
  }

  // ---------- monthly recap ----------

  MonthRecap recap(DateTime month) {
    final start = month.monthStart;
    final end = DateTime(start.year, start.month + 1);
    final prevStart = DateTime(start.year, start.month - 1);
    final spends = _spendsBetween(start, end).toList();
    final byDay = <int, double>{};
    for (final t in spends) {
      byDay[t.occurredAt.weekday] = (byDay[t.occurredAt.weekday] ?? 0) + t.amount;
    }
    final peak = byDay.entries.isEmpty
        ? null
        : byDay.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return MonthRecap(
      month: start,
      total: spends.fold(0, (s, t) => s + t.amount),
      income: incomeBetween(start, end),
      saved: savedBetween(start, end),
      transactionCount: spends.length,
      aiCategorized: spends.where((t) => t.aiCategorized).length,
      categories: byCategory(start, end),
      previousCategories: byCategory(prevStart, start),
      previousTotal: spentBetween(prevStart, start),
      peakWeekday: peak,
      channels: byChannel(start, end),
    );
  }

  /// Most recent month with any spending (current month if it has data).
  DateTime latestRecapMonth() {
    final current = today.monthStart;
    final previous = DateTime(current.year, current.month - 1);
    final hasPrevious = spentBetween(previous, current) > 0;
    final hasCurrent = spentBetween(current, today.add(const Duration(days: 1))) > 0;
    if (hasPrevious && today.day <= 7) return previous;
    if (hasCurrent) return current;
    return hasPrevious ? previous : current;
  }

  // ---------- AI context ----------

  /// Compact JSON for the insights/chat prompts (no raw SMS, no references).
  Map<String, dynamic> aiSummary({Goal? primaryGoal, Plan? plan, String? firstName}) {
    final end = today.add(const Duration(days: 1));
    final weekStart = end.subtract(const Duration(days: 7));
    final monthStart = today.monthStart;
    final prevMonthStart = DateTime(monthStart.year, monthStart.month - 1);
    Map<String, double> keyed<K extends Enum>(Map<K, double> m, String Function(K) name) =>
        {for (final e in m.entries) name(e.key): e.value.roundToDouble()};

    return {
      'firstName': ?firstName,
      'today': Fmt.weekdayName(today),
      'spentToday': spentToday,
      'spentSameDayLastWeek': spentOn(today.subtract(const Duration(days: 7))),
      'last7Days': [for (final p in lastDays(7)) p.value],
      'thisWeekTotal': spentBetween(weekStart, end),
      'lastWeekTotal': spentBetween(weekStart.subtract(const Duration(days: 7)), weekStart),
      'thisMonthTotal': spentBetween(monthStart, end),
      'lastMonthTotal': spentBetween(prevMonthStart, monthStart),
      'incomeThisMonth': incomeBetween(monthStart, end),
      'savedThisMonth': savedBetween(monthStart, end),
      'categoriesThisWeek': keyed(byCategory(weekStart, end), (c) => c.key),
      'categoriesLastWeek': keyed(
        byCategory(weekStart.subtract(const Duration(days: 7)), weekStart),
        (c) => c.key,
      ),
      'categoriesThisMonth': keyed(byCategory(monthStart, end), (c) => c.key),
      'channelsThisWeek': keyed(byChannel(weekStart, end), (c) => c.key),
      'channelsLastWeek': keyed(
        byChannel(weekStart.subtract(const Duration(days: 7)), weekStart),
        (c) => c.key,
      ),
      'weekdayAverages': {
        for (final e in weekdayAverages().entries)
          Fmt.weekdayName(DateTime(2024, 1, e.key)): e.value.roundToDouble(),
      },
      'topRecipientsThisMonth': [
        for (final r in topRecipients(monthStart, end))
          {'merchant': r.merchant, 'total': r.total, 'count': r.count, 'category': r.category.key},
      ],
      'recurringCharges': [
        for (final r in recurringCharges())
          {'merchant': r.merchant, 'amount': r.amount, 'lastCharged': Fmt.shortDate(r.last)},
      ],
      if (primaryGoal != null)
        'primaryGoal': {
          'title': primaryGoal.title,
          'target': primaryGoal.target,
          'saved': primaryGoal.saved,
          if (primaryGoal.deadline != null) 'deadline': Fmt.shortDate(primaryGoal.deadline!),
        },
      if (plan != null)
        'plan': {
          'status': plan.status.name,
          'income': plan.income,
          for (final a in plan.allocations) a.bucket.name: a.amount,
        },
    };
  }

  /// History summary used when drafting a plan.
  Map<String, dynamic> planHistory() {
    final monthStart = today.monthStart;
    final prev = DateTime(monthStart.year, monthStart.month - 1);
    final threeMonthsAgo = DateTime(monthStart.year, monthStart.month - 3);
    final months = <String, double>{
      for (var i = 3; i >= 1; i--)
        Fmt.monthKey(DateTime(monthStart.year, monthStart.month - i)): spentBetween(
          DateTime(monthStart.year, monthStart.month - i),
          DateTime(monthStart.year, monthStart.month - i + 1),
        ),
    };
    return {
      'monthlySpend': months,
      'lastMonthCategories': {
        for (final e in byCategory(prev, monthStart).entries) e.key.key: e.value.roundToDouble(),
      },
      'threeMonthCategoryAverages': {
        for (final e in byCategory(threeMonthsAgo, monthStart).entries)
          e.key.key: (e.value / 3).roundToDouble(),
      },
      'lastMonthChannels': {
        for (final e in byChannel(prev, monthStart).entries) e.key.key: e.value.roundToDouble(),
      },
    };
  }
}

@immutable
class MonthRecap {
  const MonthRecap({
    required this.month,
    required this.total,
    required this.income,
    required this.saved,
    required this.transactionCount,
    required this.aiCategorized,
    required this.categories,
    required this.previousCategories,
    required this.previousTotal,
    required this.peakWeekday,
    required this.channels,
  });

  final DateTime month;
  final double total;
  final double income;
  final double saved;
  final int transactionCount;
  final int aiCategorized;
  final Map<TxCategory, double> categories;
  final Map<TxCategory, double> previousCategories;
  final double previousTotal;
  final int? peakWeekday;
  final Map<TxChannel, double> channels;

  bool get isEmpty => transactionCount == 0;

  Map<String, dynamic> toAiJson() => {
        'month': Fmt.monthYear(month),
        'totalSpent': total,
        'income': income,
        'saved': saved,
        'transactions': transactionCount,
        'aiRecategorized': aiCategorized,
        'categories': {for (final e in categories.entries) e.key.key: e.value.roundToDouble()},
        'previousMonthCategories': {
          for (final e in previousCategories.entries) e.key.key: e.value.roundToDouble(),
        },
        'previousMonthTotal': previousTotal,
        if (peakWeekday != null) 'peakWeekday': Fmt.weekdayName(DateTime(2024, 1, peakWeekday!)),
        'channels': {for (final e in channels.entries) e.key.key: e.value.roundToDouble()},
      };
}
