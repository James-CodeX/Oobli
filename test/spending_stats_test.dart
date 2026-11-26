import 'package:flutter_test/flutter_test.dart';
import 'package:oobli/data/models/category.dart';
import 'package:oobli/data/models/goal.dart';
import 'package:oobli/data/models/plan.dart';
import 'package:oobli/data/models/transaction.dart';
import 'package:oobli/domain/local_insights.dart';
import 'package:oobli/domain/spending_stats.dart';
import 'package:oobli/state/plan_controller.dart';

final now = DateTime(2026, 11, 21, 18); // a Saturday
int _seq = 0;

Transaction tx(
  double amount,
  DateTime at, {
  TxCategory category = TxCategory.groceries,
  TxChannel channel = TxChannel.till,
  TxDirection direction = TxDirection.out,
  String merchant = 'Naivas',
  bool ai = false,
}) =>
    Transaction(
      id: '${_seq++}',
      fingerprint: 'f$_seq',
      amount: amount,
      direction: direction,
      merchant: merchant,
      category: category,
      channel: channel,
      source: TxSource.mpesa,
      occurredAt: at,
      aiCategorized: ai,
    );

void main() {
  group('SpendingStats', () {
    final stats = SpendingStats([
      tx(1000, now.subtract(const Duration(hours: 2))),
      tx(500, now.subtract(const Duration(hours: 3)), channel: TxChannel.pochi, merchant: 'Mama Mboga'),
      tx(2000, now.subtract(const Duration(days: 7))),
      tx(800, now.subtract(const Duration(days: 1)), category: TxCategory.transport),
      tx(5000, now.subtract(const Duration(days: 2)), category: TxCategory.savings),
      tx(30000, now.subtract(const Duration(days: 3)), category: TxCategory.income, direction: TxDirection.inbound),
    ], now: now);

    test('totals today excluding savings and income', () {
      expect(stats.spentToday, 1500);
    });

    test('compares with the same weekday last week', () {
      expect(stats.sameDayLastWeekChange, closeTo(-0.25, 1e-9));
    });

    test('lastDays returns 7 points ending today', () {
      final days = stats.lastDays(7);
      expect(days, hasLength(7));
      expect(days.last.value, 1500);
      expect(days.last.label, 'S');
    });

    test('groups by category and channel, largest first', () {
      final start = now.subtract(const Duration(days: 6)).copyWith(hour: 0);
      final end = now.add(const Duration(days: 1));
      final cats = stats.byCategory(start, end);
      expect(cats.keys.first, TxCategory.groceries);
      expect(cats[TxCategory.groceries], 1500);
      expect(cats.containsKey(TxCategory.savings), isFalse);
      expect(stats.byChannel(start, end)[TxChannel.pochi], 500);
    });

    test('tracks income and savings separately', () {
      final m = DateTime(2026, 11);
      final e = DateTime(2026, 12);
      expect(stats.incomeBetween(m, e), 30000);
      expect(stats.savedBetween(m, e), 5000);
    });

    test('monthly recap and AI summary are consistent', () {
      final recap = stats.recap(DateTime(2026, 11));
      expect(recap.total, 4300);
      expect(recap.transactionCount, 4);
      final summary = stats.aiSummary(firstName: 'Jared');
      expect(summary['spentToday'], 1500);
      expect(summary['firstName'], 'Jared');
      expect((summary['last7Days'] as List).length, 7);
    });

    test('detects monthly subscriptions', () {
      final s = SpendingStats([
        tx(1100, DateTime(2026, 11, 1), category: TxCategory.entertainment, merchant: 'Netflix'),
        tx(1100, DateTime(2026, 10, 1), category: TxCategory.entertainment, merchant: 'Netflix'),
      ], now: now);
      expect(s.recurringCharges().single.merchant, 'Netflix');
    });

    test('every period: today, yesterday, a week, a month, 6 months and a year', () {
      final s = SpendingStats([
        tx(500, DateTime(2026, 11, 21, 9, 30)), // today 9am
        tx(200, DateTime(2026, 11, 21, 10)),
        tx(300, DateTime(2026, 11, 20, 20)), // yesterday 8pm
        tx(1000, DateTime(2026, 11, 2)),
        tx(4000, DateTime(2026, 7, 15)),
        tx(9000, DateTime(2025, 12, 24)),
      ], now: now);

      final today = s.seriesFor(Period.today(now));
      expect(today, hasLength(7), reason: 'three-hour blocks up to 6pm');
      expect(today[3].value, 700, reason: '9am - 12pm');
      final yesterday = s.seriesFor(Period.yesterday(now));
      expect(yesterday, hasLength(8));
      expect(yesterday[6].value, 300);
      expect(s.seriesFor(Period.week(now)).map((p) => p.value).fold<double>(0, (a, b) => a + b), 1000);

      final november = s.seriesFor(Period.month(now));
      expect(november, hasLength(21), reason: 'one point a day, up to today');
      expect(november[1].value, 1000);
      expect(november[1].label, '', reason: 'only a few days are labelled');
      expect(november[1].tip, 'Nov 02');
      expect(s.seriesFor(Period.month(DateTime(2026, 2))), hasLength(28), reason: 'a past month in full');

      final six = s.seriesFor(Period.sixMonths(now));
      expect(six.map((p) => p.label), ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov']);
      expect(six[1].value, 4000);
      expect(s.seriesFor(Period.year(2026)), hasLength(11), reason: 'January to this month');
      expect(s.seriesFor(Period.year(2025)), hasLength(12));
      expect(s.seriesFor(Period.year(2025)).last.value, 9000);

      expect(s.spendingYears(), [2026, 2025]);
      expect(s.spendingMonths().first.month, DateTime(2026, 11));
      expect(Period.month(DateTime(2025, 12)).label(now), 'Dec 2025');
      expect(Period.week(now).phrase(now), 'this week');
    });

    test('charts always get at least two points', () {
      final firstOfMonth = DateTime(2026, 12, 1, 1);
      final s = SpendingStats([], now: firstOfMonth);
      expect(s.seriesFor(Period.today(firstOfMonth)), hasLength(2));
      expect(s.seriesFor(Period.month(firstOfMonth)), hasLength(2));
      expect(SpendingStats([], now: DateTime(2027, 1, 5)).seriesFor(Period.year(2027)), hasLength(2));
    });
  });

  group('LocalInsights', () {
    test('always produces a headline and at most two cards', () {
      final insights = LocalInsights.build(SpendingStats([tx(100, now)], now: now));
      expect(insights.headline, isNotEmpty);
      expect(insights.cards.length, lessThanOrEqualTo(2));
      expect(insights.isFallback, isTrue);
    });

    test('milestones follow goal progress', () {
      final goal = Goal(
        id: 'g',
        title: 'New MacBook Pro',
        icon: GoalIcon.laptop,
        target: 240000,
        saved: 85000,
        createdAt: DateTime(2026, 10, 12),
        deadline: DateTime(2026, 12, 20),
      );
      final m = LocalInsights.milestones(goal);
      expect(m.map((x) => x.completed), [true, true, false, false]);
      expect(m[1].label, 'Reach KSh 60,000');
    });

    test('wrapped story has badges and a win', () {
      final story = LocalInsights.wrapped(SpendingStats([tx(100, now)], now: now).recap(DateTime(2026, 11)));
      expect(story.badges, isNotEmpty);
      expect(story.winBody, isNotEmpty);
    });
  });

  test('default plan splits income 50/20/20/10', () {
    final rows = PlanController.defaultAllocations(85000, 'laptop');
    expect(rows.map((r) => r.percent), [50, 20, 20, 10]);
    expect(rows.first.amount, 42500);
    expect(rows.map((r) => r.bucket), [PlanBucket.needs, PlanBucket.savings, PlanBucket.flex, PlanBucket.emergency]);
    final roundTrip = PlanAllocation.fromJson(rows[1].toJson());
    expect(roundTrip.bucket, PlanBucket.savings);
  });
}
