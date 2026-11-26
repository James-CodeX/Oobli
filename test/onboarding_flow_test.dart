import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oobli/data/models/category.dart';
import 'package:oobli/data/models/transaction.dart';
import 'package:oobli/domain/spending_stats.dart';
import 'package:oobli/features/onboarding/gamified_setup_screen.dart';
import 'package:oobli/features/onboarding/meet_oobli_screen.dart';
import 'package:oobli/ui/widgets/mascot.dart';

import 'support/fakes.dart';

Transaction tx(double amount, DateTime at) => Transaction(
      id: '$at',
      fingerprint: '$at',
      amount: amount,
      direction: TxDirection.out,
      merchant: 'Shop',
      category: TxCategory.shopping,
      channel: TxChannel.till,
      source: TxSource.mpesa,
      occurredAt: at,
      confirmed: true,
    );

void main() {
  setUpAll(loadFonts);

  Future<void> open(WidgetTester tester, Widget screen, {bool signedIn = false}) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(harness(screen, await overrides(signedIn: signedIn)));
    await settle(tester);
  }

  MascotMood mood(WidgetTester tester) => tester.widget<OobliMascot>(find.byType(OobliMascot).first).mood;

  testWidgets('Oobli starts asleep; a tap wakes him, then two slides to Get Started', (tester) async {
    await open(tester, const MeetOobliScreen());
    expect(mood(tester), MascotMood.sleeping);
    expect(find.text('Get Started'), findsNothing);

    await tester.tap(find.byType(OobliMascot).first);
    await settle(tester);
    expect(find.text("Hi, I'm Oobli"), findsOneWidget);
    expect(mood(tester), MascotMood.winking);

    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('I read your M-Pesa'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await settle(tester);
    expect(find.text('Mama Oliech'), findsOneWidget, reason: 'the SMS turned into a sorted transaction');

    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Plans that stick'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('setup: Oobli changes with each question and cheers a chosen goal', (tester) async {
    await open(tester, const GamifiedSetupScreen(), signedIn: true);
    expect(find.text('What matters most?'), findsOneWidget);
    expect(mood(tester), MascotMood.thinking);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('How much comes in this month?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    expect(find.text('Saving for something?'), findsOneWidget);
    expect(mood(tester), MascotMood.love);
    await tester.tap(find.text('Coast Trip'));
    await settle(tester);
    expect(mood(tester), MascotMood.celebrating);
    expect(find.text("Let's go"), findsOneWidget);
  });

  test("today's pace: quiet, calm, usual or high against a usual day", () {
    final now = DateTime(2026, 11, 26, 18); // a Thursday
    final history = [
      for (var w = 1; w <= 8; w++) tx(1000, DateTime(2026, 11, 26 - 7 * w, 12)), // usual Thursday: 1,000
    ];
    DayPace pace(double today) =>
        SpendingStats([...history, if (today > 0) tx(today, DateTime(2026, 11, 26, 9))], now: now).todayPace;
    expect(pace(0), DayPace.quiet);
    expect(pace(500), DayPace.calm);
    expect(pace(1000), DayPace.usual);
    expect(pace(2000), DayPace.high);
  });
}
