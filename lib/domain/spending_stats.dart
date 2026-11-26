import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../data/models/category.dart';
import '../data/models/goal.dart';
import '../data/models/plan.dart';
import '../data/models/transaction.dart';
import 'bills.dart';

/// How today's spending is going (drives Oobli's face on the home screen).
enum DayPace { quiet, calm, usual, high }

enum PeriodKind { today, yesterday, week, month, sixMonths, year }

/// A span of time the charts can show: today, yesterday, the last 7 days, a
/// calendar month, the last 6 months or a calendar year. [end] is exclusive.
@immutable
class Period {
  const Period._(this.kind, this.start, this.end);

  final PeriodKind kind;
  final DateTime start;
  final DateTime end;

  factory Period.today(DateTime now) {
    final d = now.dateOnly;
    return Period._(PeriodKind.today, d, d.add(const Duration(days: 1)));
  }

  factory Period.yesterday(DateTime now) {
    final d = now.dateOnly;
    return Period._(PeriodKind.yesterday, d.subtract(const Duration(days: 1)), d);
  }

  /// The last 7 days, today included.
  factory Period.week(DateTime now) {
    final end = now.dateOnly.add(const Duration(days: 1));
    return Period._(PeriodKind.week, end.subtract(const Duration(days: 7)), end);
  }

  factory Period.month(DateTime month) {
    final start = month.monthStart;
    return Period._(PeriodKind.month, start, DateTime(start.year, start.month + 1));
  }

  /// This month and the five before it.
  factory Period.sixMonths(DateTime now) {
    final m = now.monthStart;
    return Period._(PeriodKind.sixMonths, DateTime(m.year, m.month - 5), DateTime(m.year, m.month + 1));
  }

  factory Period.year(int year) => Period._(PeriodKind.year, DateTime(year), DateTime(year + 1));

  /// Short name for buttons and headings: "Today", "This week", "November",
  /// "Oct 2025", "6 months", "2026".
  String label(DateTime now) => switch (kind) {
        PeriodKind.today => 'Today',
        PeriodKind.yesterday => 'Yesterday',
        PeriodKind.week => 'This week',
        PeriodKind.month => start.year == now.year ? Fmt.monthName(start) : Fmt.monthShortYear(start),
        PeriodKind.sixMonths => '6 months',
        PeriodKind.year => '${start.year}',
      };

  /// Fits after an amount: "KES 4,000 today", "… in November".
  String phrase(DateTime now) => switch (kind) {
        PeriodKind.today => 'today',
        PeriodKind.yesterday => 'yesterday',
        PeriodKind.week => 'this week',
        PeriodKind.sixMonths => 'in 6 months',
        _ => 'in ${label(now)}',
      };

  @override
  bool operator ==(Object other) => other is Period && other.kind == kind && other.start == start;

  @override
  int get hashCode => Object.hash(kind, start);
}

@immutable
class SeriesPoint {
  const SeriesPoint(this.label, this.value, {this.tip});

  /// Axis label (may be empty to keep a crowded axis readable).
  final String label;
  final double value;

  /// Tooltip title; defaults to [label].
  final String? tip;
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

  /// Spend over [p], as points for the flow chart (always at least two).
  List<SeriesPoint> seriesFor(Period p) {
    final tomorrow = today.add(const Duration(days: 1));
    final points = <SeriesPoint>[];
    switch (p.kind) {
      case PeriodKind.today:
      case PeriodKind.yesterday:
        // Three-hour blocks; today stops at the current block.
        const names = ['12a', '3a', '6a', '9a', '12p', '3p', '6p', '9p'];
        const tips = ['Midnight – 3 AM', '3 – 6 AM', '6 – 9 AM', '9 AM – 12 PM', '12 – 3 PM', '3 – 6 PM', '6 – 9 PM',
          '9 PM – midnight'];
        final last = p.kind == PeriodKind.today ? now.hour ~/ 3 : 7;
        for (var i = 0; i <= math.max(last, 1); i++) {
          final s = p.start.add(Duration(hours: i * 3));
          points.add(SeriesPoint(names[i], spentBetween(s, s.add(const Duration(hours: 3))), tip: tips[i]));
        }
      case PeriodKind.week:
        for (var d = p.start; d.isBefore(p.end); d = DateTime(d.year, d.month, d.day + 1)) {
          points.add(SeriesPoint(Fmt.weekdayLetter(d), spentOn(d), tip: '${Fmt.weekdayName(d)}, ${Fmt.shortDate(d)}'));
        }
      case PeriodKind.month:
        final end = p.end.isAfter(tomorrow) ? tomorrow : p.end;
        for (var d = p.start; d.isBefore(end) || points.length < 2; d = DateTime(d.year, d.month, d.day + 1)) {
          final label = const {1, 8, 15, 22, 29}.contains(d.day) ? '${d.day}' : '';
          points.add(SeriesPoint(label, spentOn(d), tip: Fmt.shortDate(d)));
        }
      case PeriodKind.sixMonths:
      case PeriodKind.year:
        for (var m = p.start; m.isBefore(p.end) && (!m.isAfter(today) || points.length < 2);
            m = DateTime(m.year, m.month + 1)) {
          final label = p.kind == PeriodKind.year ? Fmt.monthName(m).substring(0, 1) : Fmt.monthShort(m);
          points.add(SeriesPoint(label, spentBetween(m, DateTime(m.year, m.month + 1)), tip: Fmt.monthYear(m)));
        }
    }
    return points;
  }

  /// Months that have any spending, newest first (for the month picker).
  List<({DateTime month, double total})> spendingMonths() {
    final totals = <DateTime, double>{};
    for (final t in all) {
      if (t.isSpend) totals.update(t.occurredAt.monthStart, (v) => v + t.amount, ifAbsent: () => t.amount);
    }
    totals.putIfAbsent(today.monthStart, () => 0);
    final months = totals.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final m in months) (month: m, total: totals[m]!)];
  }

  /// Years that have any spending, newest first.
  List<int> spendingYears() =>
      {today.year, for (final t in all) if (t.isSpend) t.occurredAt.year}.toList()..sort((a, b) => b - a);

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

  /// What a typical day like today costs: the average for this weekday over
  /// the last 8 weeks, or the daily average of the last 4 weeks. Null with
  /// too little history to tell.
  double? get usualForToday {
    final weekday = weekdayAverages()[today.weekday] ?? 0;
    if (weekday > 0) return weekday;
    final daily = spentBetween(today.subtract(const Duration(days: 28)), today) / 28;
    return daily > 0 ? daily : null;
  }

  /// How today compares with [usualForToday]: "calm" (no spending yet or
  /// well below usual), "usual", or "high" (half again over usual or more).
  DayPace get todayPace {
    final usual = usualForToday;
    final spent = spentToday;
    if (usual == null) return spent > 0 ? DayPace.usual : DayPace.quiet;
    if (spent <= 0) return DayPace.quiet;
    if (spent >= usual * 1.5) return DayPace.high;
    if (spent <= usual * 0.8) return DayPace.calm;
    return DayPace.usual;
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
      'upcomingBills': [
        for (final b in BillPredictor.forecast(all, now: now).upcoming.take(5))
          {'merchant': b.merchant, 'amount': b.amount.roundToDouble(), 'due': Fmt.shortDate(b.nextDue), 'cadence': b.cadence.label},
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
