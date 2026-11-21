import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oobli/app/router.dart';
import 'package:oobli/core/theme/app_theme.dart';
import 'package:oobli/state/preferences.dart';

import 'support/fakes.dart';

void main() {
  test('switching on takes effect next launch; finishing turns it off', () async {
    final container = ProviderContainer(overrides: await overrides());
    addTearDown(container.dispose);
    final notifier = container.read(onboardingReplayProvider.notifier);

    await notifier.setEnabled(true);
    var replay = container.read(onboardingReplayProvider);
    expect(replay.enabled, isTrue);
    expect(replay.active, isFalse, reason: 'does not interrupt the current session');
    expect(container.read(localStoreProvider).replayOnboarding, isTrue);

    // Next launch reads the stored switch.
    final relaunch = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(container.read(sharedPreferencesProvider)),
    ]);
    addTearDown(relaunch.dispose);
    expect(relaunch.read(onboardingReplayProvider).active, isTrue);

    await relaunch.read(onboardingReplayProvider.notifier).finish();
    replay = relaunch.read(onboardingReplayProvider);
    expect(replay.enabled, isFalse);
    expect(replay.active, isFalse);
    expect(relaunch.read(localStoreProvider).replayOnboarding, isFalse);
  });

  Future<GoRouter> launch(WidgetTester tester, {required bool replay}) async {
    final container = ProviderContainer(
      overrides: await overrides(prefs: {'replay_onboarding': replay, 'seen_intro': true}),
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    return router;
  }

  String location(GoRouter router) => router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('a signed-in user replaying starts at the intro with Continue', (tester) async {
    final router = await launch(tester, replay: true);
    expect(location(router), Routes.welcome);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('I already have an account'), findsNothing);

    // Can't wander off to the home screens until it's finished.
    router.go(Routes.feed);
    await tester.pump();
    expect(location(router), Routes.welcome);

    await tester.tap(find.text('Continue'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(location(router), Routes.smsPermission);
  });

  testWidgets('without the switch, a signed-in user lands on the feed', (tester) async {
    final router = await launch(tester, replay: false);
    expect(location(router), Routes.feed);
  });
}
