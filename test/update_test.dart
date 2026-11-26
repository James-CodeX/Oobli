import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oobli/data/services/update_service.dart';
import 'package:oobli/features/dashboard/dashboard_screen.dart';
import 'package:oobli/features/settings/settings_screen.dart';
import 'package:oobli/state/preferences.dart';
import 'package:oobli/state/update_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

const release = AppUpdate(
  version: '1.5.0',
  build: 31,
  apkUrl: 'https://example.invalid/oobli.apk',
  size: 1000,
  sha256: '',
  notes: 'In-app updates\n\n- Oobli tells you when a new version is out.\n- One tap downloads and installs it.\n',
);

/// Pretends to be Android with [published] on the server.
class FakeUpdates extends UpdateService {
  FakeUpdates({this.published = release, this.result = InstallResult.started});

  AppUpdate? published;
  InstallResult result;
  int checks = 0;
  int installs = 0;

  @override
  bool get supported => true;

  @override
  Future<AppUpdate?> latest() async {
    checks++;
    return published;
  }

  @override
  Future<File> download(AppUpdate update, {void Function(double progress)? onProgress}) async {
    onProgress?.call(0.5);
    onProgress?.call(1);
    return File('oobli-${update.version}.apk');
  }

  @override
  Future<InstallResult> install(File apk) async {
    installs++;
    return result;
  }
}

void main() {
  group('AppUpdate', () {
    test('compares versions like people do', () {
      expect(release.isNewerThan('1.4.0', 30), isTrue);
      expect(release.isNewerThan('1.4.9', 99), isTrue, reason: 'the version wins over the build number');
      expect(release.isNewerThan('1.10.0', 5), isFalse, reason: '10 is more than 5, not "1" less');
      expect(release.isNewerThan('1.5.0', 31), isFalse, reason: 'same release');
      expect(release.isNewerThan('1.5.0', 29), isTrue, reason: 'same version, rebuilt');
      expect(release.isNewerThan('2.0.0', 1), isFalse);
    });

    test('reads the release notes into a headline and bullet points', () {
      expect(release.headline, 'In-app updates');
      expect(release.highlights, ['Oobli tells you when a new version is out.', 'One tap downloads and installs it.']);
    });
  });

  group('UpdateController', () {
    late FakeUpdates server;
    late SharedPreferences prefs;

    Future<ProviderContainer> app({Map<String, Object> saved = const {}}) async {
      SharedPreferences.setMockInitialValues(saved);
      prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        updateServiceProvider.overrideWithValue(server),
        installedAppProvider.overrideWith((ref) async => (version: '1.4.0', build: 30)),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    setUp(() => server = FakeUpdates());

    test('finds a newer version and offers it on the home screen', () async {
      final c = await app();
      expect(await c.read(updateProvider.notifier).check(), release);
      expect(c.read(updateProvider).showBanner, isTrue);
    });

    test('says nothing when already up to date', () async {
      server.published = const AppUpdate(version: '1.4.0', build: 30, apkUrl: '', size: 0, sha256: '', notes: '');
      final c = await app();
      expect(await c.read(updateProvider.notifier).check(manual: true), isNull);
      expect(c.read(updateProvider).checked, isTrue);
      expect(c.read(updateProvider).showBanner, isFalse);
    });

    test('automatic checks follow the Settings switch and run at most every few hours', () async {
      final c = await app(saved: {'auto_update_check': false});
      await c.read(updateProvider.notifier).check();
      expect(server.checks, 0, reason: 'switched off');
      await c.read(updateProvider.notifier).check(manual: true);
      expect(server.checks, 1, reason: '"Check for updates" always works');

      await c.read(autoUpdateCheckProvider.notifier).set(true);
      expect(prefs.getBool('auto_update_check'), isTrue);
      expect(server.checks, 2, reason: 'turning it on checks straight away');
      await c.read(updateProvider.notifier).check();
      expect(server.checks, 2, reason: 'not again so soon');
    });

    test('"Later" hides the banner for that version only', () async {
      final c = await app();
      await c.read(updateProvider.notifier).check();
      await c.read(updateProvider.notifier).dismiss();
      expect(c.read(updateProvider).showBanner, isFalse);
      expect(c.read(updateProvider).available, release, reason: 'Settings still offers it');

      final next = await app(saved: {'dismissed_update': '1.5.0'});
      await next.read(updateProvider.notifier).check();
      expect(next.read(updateProvider).showBanner, isFalse, reason: 'remembered');

      server.published = const AppUpdate(version: '1.6.0', build: 40, apkUrl: '', size: 0, sha256: '', notes: '');
      final later = await app(saved: {'dismissed_update': '1.5.0'});
      await later.read(updateProvider.notifier).check();
      expect(later.read(updateProvider).showBanner, isTrue, reason: 'a newer version shows again');
    });

    test('downloads and opens the installer; asks for permission the first time', () async {
      server.result = InstallResult.needsPermission;
      final c = await app();
      await c.read(updateProvider.notifier).check();
      await c.read(updateProvider.notifier).downloadAndInstall();
      expect(c.read(updateProvider).phase, UpdatePhase.needsPermission);

      server.result = InstallResult.started;
      await c.read(updateProvider.notifier).downloadAndInstall();
      expect(c.read(updateProvider).phase, UpdatePhase.installing);
      expect(c.read(updateProvider).progress, 1);
      expect(server.installs, 2);
    });
  });

  group('screens', () {
    setUpAll(loadFonts);

    Future<void> open(WidgetTester tester, Widget screen, FakeUpdates server) async {
      usePhoneViewport(tester, height: 1600);
      await tester.pumpWidget(harness(screen, [
        ...await overrides(),
        updateServiceProvider.overrideWithValue(server),
        installedAppProvider.overrideWith((ref) async => (version: '1.4.0', build: 30)),
      ]));
      await settle(tester);
    }

    testWidgets('home shows "a new Oobli is ready" and opens the update', (tester) async {
      final server = FakeUpdates();
      await open(tester, const DashboardScreen(), server);
      final element = tester.element(find.byType(DashboardScreen));
      await ProviderScope.containerOf(element).read(updateProvider.notifier).check();
      await settle(tester);

      expect(find.text('Oobli 1.5.0 is ready'), findsOneWidget);
      await tester.tap(find.text('Update'));
      await settle(tester);
      expect(find.text('Oobli tells you when a new version is out.'), findsOneWidget);
      expect(find.text('You have 1.4.0'), findsOneWidget);

      await tester.tap(find.textContaining('Download and install'));
      await settle(tester);
      expect(server.installs, 1);
      expect(find.textContaining('Tap "Update" on the Android screen'), findsOneWidget);
    });

    testWidgets('Settings: check now, and a switch for automatic checks', (tester) async {
      final server = FakeUpdates(published: null);
      await open(tester, const SettingsScreen(), server);
      expect(find.text('Check automatically'), findsOneWidget);

      await tester.tap(find.text('Check for updates'));
      await settle(tester);
      expect(find.text("You're on the latest version (v1.4.0)"), findsOneWidget);

      await tester.tap(find.text('Check automatically'));
      await settle(tester);
      expect(find.textContaining('Off: use'), findsOneWidget);
    });
  });
}
