@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oobli/features/activity/activity_screen.dart';
import 'package:oobli/features/analytics/analytics_screen.dart';
import 'package:oobli/features/auth/auth_screen.dart';
import 'package:oobli/features/dashboard/dashboard_screen.dart';
import 'package:oobli/features/goals/goals_screen.dart';
import 'package:oobli/features/onboarding/gamified_setup_screen.dart';
import 'package:oobli/features/onboarding/meet_oobli_screen.dart';
import 'package:oobli/features/onboarding/sms_permission_screen.dart';
import 'package:oobli/features/onboarding/splash_screen.dart';
import 'package:oobli/features/plans/plans_screen.dart';
import 'package:oobli/features/settings/settings_screen.dart';
import 'package:oobli/features/transactions/quick_sort_screen.dart';
import 'package:oobli/features/wrapped/wrapped_screen.dart';

import 'support/fakes.dart';

/// Renders every screen with fixture data, checks key content and writes a
/// golden image per screen (`flutter test --update-goldens` to regenerate).
void main() {
  setUpAll(loadFonts);

  Future<void> render(
    WidgetTester tester,
    Widget screen,
    String golden, {
    double height = 956,
    bool withPlan = true,
    ThemeMode mode = ThemeMode.dark,
  }) async {
    usePhoneViewport(tester, height: height);
    await tester.pumpWidget(harness(screen, await overrides(plan: withPlan ? fixturePlan() : null), mode: mode));
    // Decode asset images for real (they load asynchronously in widget tests).
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await settle(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$golden.png'));
  }

  testWidgets('Meet Oobli', (tester) async {
    await render(tester, const MeetOobliScreen(), 'meet_oobli');
    expect(find.text('Meet Oobli'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });

  testWidgets('Auth', (tester) async {
    await render(tester, const AuthScreen(), 'auth');
    expect(find.text('Create Account'), findsOneWidget);
    await tester.tap(find.text('Create Account'));
    await settle(tester);
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('SMS Sync Permissions', (tester) async {
    await render(tester, const SmsPermissionScreen(), 'sms_permissions', height: 1000);
    expect(find.text('Grant Access'), findsOneWidget);
    expect(find.text('Privacy First'), findsOneWidget);
  });

  testWidgets('Gamified Setup', (tester) async {
    await render(tester, const GamifiedSetupScreen(), 'gamified_setup');
    expect(find.text('Kill the Debt'), findsOneWidget);
    await tester.tap(find.text('Smart Saving'));
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Anticipated Income'), findsOneWidget);
  });

  testWidgets('Oobli Says dashboard', (tester) async {
    await render(tester, const DashboardScreen(), 'dashboard', height: 1400);
    expect(find.text('Oobli says...'), findsOneWidget);
    expect(find.text("Today's Flow"), findsOneWidget);
    expect(find.text('Where it went'), findsOneWidget);
    expect(find.text('View analytics'), findsOneWidget);
    expect(find.text('Subscription Alert'), findsNothing);
    expect(find.text('Recent M-Pesa'), findsOneWidget);
    expect(find.text('Ask Oobli'), findsOneWidget);
  });

  testWidgets('Activity', (tester) async {
    await render(tester, const ActivityScreen(), 'activity', height: 1000);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('Naivas Supermarket'), findsOneWidget);
    expect(find.textContaining('Is this'), findsWidgets);
  });

  testWidgets('Quick sort: one tap files a transaction and opens the next', (tester) async {
    final total = fixtureTransactions().length;
    await render(tester, const QuickSortScreen(), 'quick_sort');
    expect(find.text('Quick sort'), findsOneWidget);
    expect(find.text('Remember for this merchant'), findsOneWidget);
    expect(find.text('$total left'), findsOneWidget);
    // The newest transaction is open with every spending category.
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Fees & Charges'), findsOneWidget);

    await tester.tap(find.text('Fees & Charges'));
    await settle(tester);
    expect(find.text('${total - 1} left'), findsOneWidget);
    // Naivas is filed and scrolled away; Mama Mboga Pochi is open next.
    expect(find.text('Oobli guessed Food & Dining'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Fees & Charges'), findsOneWidget);
  });

  testWidgets('Analytics', (tester) async {
    await render(tester, const AnalyticsScreen(), 'analytics', height: 1400);
    expect(find.text('Oobli Analytics'), findsOneWidget);
    expect(find.text('Yes, Recategorize'), findsOneWidget);
    expect(find.text('Distribution'), findsOneWidget);
  });

  testWidgets('Oobli Plans', (tester) async {
    await render(tester, const PlansScreen(), 'plans', height: 1450);
    expect(find.textContaining('Draft Plan'), findsOneWidget);
    expect(find.text('Fixed Needs'), findsOneWidget);
    expect(find.text('Activate Plan'), findsOneWidget);
  });

  testWidgets('Oobli Goals', (tester) async {
    await render(tester, const GoalsScreen(), 'goals', height: 1200);
    expect(find.text('New MacBook Pro'), findsOneWidget);
    expect(find.text('Milestones'), findsOneWidget);
    expect(find.text('Coast Trip'), findsOneWidget);
  });

  testWidgets('Oobli Wrapped', (tester) async {
    await render(tester, const WrappedScreen(), 'wrapped', height: 1700);
    expect(find.text('Oobli Wrapped'), findsOneWidget);
    expect(find.text('Where it went'), findsOneWidget);
  });

  testWidgets('Settings & Profile', (tester) async {
    await render(tester, const SettingsScreen(), 'settings', height: 1320);
    expect(find.text('Jared Waweru'), findsOneWidget);
    expect(find.text('12 Days'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
    expect(find.text('Oobli v1.1.2'), findsOneWidget);
  });

  testWidgets('Dashboard in light theme', (tester) async {
    await render(tester, const DashboardScreen(), 'dashboard_light', height: 1400, mode: ThemeMode.light);
    expect(find.text('Recent M-Pesa'), findsOneWidget);
  });

  testWidgets('Splash follows the theme', (tester) async {
    await render(tester, const SplashScreen(), 'splash_dark');
    await render(tester, const SplashScreen(), 'splash_light', mode: ThemeMode.light);
    expect(find.bySemanticsLabel('Oobli'), findsOneWidget);
  });

  testWidgets('Light theme screens', (tester) async {
    await render(tester, const MeetOobliScreen(), 'meet_oobli_light', mode: ThemeMode.light);
    await render(tester, const PlansScreen(), 'plans_light', height: 1450, mode: ThemeMode.light);
    await render(tester, const SettingsScreen(), 'settings_light', height: 1320, mode: ThemeMode.light);
    expect(find.text('Sign Out'), findsOneWidget);
  });
}
