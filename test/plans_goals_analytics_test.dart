import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oobli/core/theme/oobli_colors.dart';
import 'package:oobli/data/models/goal.dart';
import 'package:oobli/features/analytics/analytics_screen.dart';
import 'package:oobli/features/dashboard/dashboard_screen.dart';
import 'package:oobli/features/goals/goals_screen.dart';
import 'package:oobli/features/plans/plans_screen.dart';

import 'support/fakes.dart';

/// Behaviour of the period buttons, the plan's spending history and reached
/// goals (no golden images, so these run in CI).
void main() {
  setUpAll(loadFonts);

  Future<void> open(WidgetTester tester, Widget screen, {List<Goal>? goals, bool plan = true}) async {
    usePhoneViewport(tester, height: 1600);
    await tester.pumpWidget(harness(screen, await overrides(plan: plan ? fixturePlan() : null, goals: goals)));
    await settle(tester);
  }

  testWidgets('Plans: the income form only shows before there is a plan', (tester) async {
    await open(tester, const PlansScreen(), plan: false);
    expect(find.text('Expected income this month'), findsOneWidget);
    expect(find.text('Draft my plan'), findsOneWidget);

    await open(tester, const PlansScreen());
    expect(find.text('Expected income this month'), findsNothing);
    expect(find.text('Where the money goes'), findsOneWidget);
    expect(find.text('Activate Plan'), findsOneWidget);
  });

  testWidgets('Plans: a bucket shows its payments, and one tap re-files a payment', (tester) async {
    await open(tester, const PlansScreen());
    await tester.tap(find.text('Fixed Needs'));
    await settle(tester);

    expect(find.text('Tap one to change its category'), findsOneWidget);
    expect(find.text('KPLC Prepaid'), findsOneWidget, reason: 'utilities are a need');
    expect(find.text('Java House'), findsNothing, reason: 'eating out is a want');

    await tester.tap(find.text('KPLC Prepaid'));
    await settle(tester);
    await tester.tap(find.text('Entertainment'));
    await settle(tester);

    expect(find.text('KPLC Prepaid moved to Entertainment'), findsOneWidget);
    expect(find.text('KPLC Prepaid'), findsNothing, reason: 'no longer a need');

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('KPLC Prepaid'), findsOneWidget, reason: 'back where it was');
  });

  testWidgets('Goals: a reached goal is one small row that opens its history', (tester) async {
    await open(tester, const GoalsScreen(), goals: [
      Goal(id: 'g1', title: 'New Laptop', icon: GoalIcon.laptop, target: 45000, saved: 45000,
          createdAt: DateTime(2026, 11, 1), isPrimary: true),
      Goal(id: 'g2', title: 'Coast Trip', icon: GoalIcon.travel, target: 30000, saved: 21000,
          createdAt: DateTime(2026, 9, 1), tone: Tone.accent),
    ]);

    expect(find.text('Achieved'), findsOneWidget);
    expect(find.text('KSh 45,000 reached'), findsOneWidget);
    expect(find.text('Coast Trip'), findsWidgets, reason: 'the goal still in progress takes the spotlight');
    expect(find.text('New goal'), findsOneWidget, reason: 'creating a goal is a floating button');

    await tester.tap(find.text('New Laptop'));
    await settle(tester);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Add to goal'), findsNothing, reason: 'nothing left to add');
  });

  testWidgets('Analytics: one set of buttons drives both charts', (tester) async {
    await open(tester, const AnalyticsScreen());
    expect(find.text('this week'), findsOneWidget, reason: 'donut centre');

    await tester.tap(find.text('Yesterday'));
    await settle(tester);
    expect(find.text('yesterday'), findsOneWidget);

    await tester.tap(find.text('6 months'));
    await settle(tester);
    expect(find.text('6 months'), findsWidgets);

    await tester.tap(find.text('Month'));
    await settle(tester);
    expect(find.text('Choose a month'), findsOneWidget);
    await tester.tap(find.text('Choose a month')); // nothing picked: still 6 months
    await tester.tapAt(const Offset(20, 20));
    await settle(tester);

    await tester.tap(find.text('Groceries'));
    await settle(tester);
    expect(find.text('Tap one to change its category'), findsOneWidget);
    expect(find.text('Mama Mboga'), findsWidgets);
  });

  testWidgets('Home: "Where it went" switches between today, yesterday and this week', (tester) async {
    await open(tester, const DashboardScreen());
    expect(find.text('this week'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await settle(tester);
    expect(find.text('today'), findsOneWidget);
    await tester.tap(find.text('Yesterday'));
    await settle(tester);
    expect(find.text('yesterday'), findsOneWidget);
  });
}
