import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore(ref.watch(sharedPreferencesProvider)));

/// Device-local settings and caches (never anything that must sync).
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const _seenIntro = 'seen_intro';
  static const _themeMode = 'theme_mode';
  static const _aiCorrections = 'ai_corrections';
  static const _dismissedSuggestions = 'dismissed_suggestions';
  static const _session = 'session_profile';
  static const _quickSortRemember = 'quick_sort_remember';
  static const _replayOnboarding = 'replay_onboarding';
  static const _autoUpdateCheck = 'auto_update_check';
  static const _dismissedUpdate = 'dismissed_update';

  bool get seenIntro => _prefs.getBool(_seenIntro) ?? false;
  Future<void> setSeenIntro() => _prefs.setBool(_seenIntro, true);

  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_prefs.getString(_themeMode)] ?? ThemeMode.system;
  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString(_themeMode, mode.name);

  /// Quick sort's "Remember for this merchant" switch (on by default).
  bool get quickSortRemember => _prefs.getBool(_quickSortRemember) ?? true;
  Future<void> setQuickSortRemember(bool value) => _prefs.setBool(_quickSortRemember, value);

  /// Play onboarding again on the next launch (cleared once it's finished).
  bool get replayOnboarding => _prefs.getBool(_replayOnboarding) ?? false;
  Future<void> setReplayOnboarding(bool value) => _prefs.setBool(_replayOnboarding, value);

  /// Look for a new Oobli version on launch (Settings switch, on by default).
  bool get autoUpdateCheck => _prefs.getBool(_autoUpdateCheck) ?? true;
  Future<void> setAutoUpdateCheck(bool value) => _prefs.setBool(_autoUpdateCheck, value);

  /// The update version whose home-screen banner the user closed.
  String? get dismissedUpdate => _prefs.getString(_dismissedUpdate);
  Future<void> setDismissedUpdate(String version) => _prefs.setString(_dismissedUpdate, version);

  int get aiCorrections => _prefs.getInt(_aiCorrections) ?? 0;
  Future<void> incrementAiCorrections() => _prefs.setInt(_aiCorrections, aiCorrections + 1);

  Set<String> get dismissedSuggestions =>
      (_prefs.getStringList(_dismissedSuggestions) ?? const []).toSet();
  Future<void> dismissSuggestion(String merchantKey) =>
      _prefs.setStringList(_dismissedSuggestions, [...dismissedSuggestions, merchantKey]);

  /// The signed-in user as of the last successful contact with Appwrite.
  /// Lets the app start instantly and offline; `null` means "signed out".
  Map<String, dynamic>? get cachedSession {
    final raw = _prefs.getString(_session);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  Future<void> saveSession(Map<String, dynamic> profile) => _prefs.setString(_session, jsonEncode(profile));

  Future<void> clearSession() => _prefs.remove(_session);

  /// Small JSON cache keyed by [name]; [key] identifies the input it was built from.
  Map<String, dynamic>? readCache(String name, String key) {
    final raw = _prefs.getString('cache_$name');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded['key'] == key ? decoded['value'] as Map<String, dynamic> : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> writeCache(String name, String key, Map<String, dynamic> value) =>
      _prefs.setString('cache_$name', jsonEncode({'key': key, 'value': value}));

  Future<void> clearCache(String name) => _prefs.remove('cache_$name');

  Future<void> clearUserData() async {
    for (final k in _prefs.getKeys().where((k) => k.startsWith('cache_')).toList()) {
      await _prefs.remove(k);
    }
    await _prefs.remove(_aiCorrections);
    await _prefs.remove(_dismissedSuggestions);
    await _prefs.remove(_session);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(localStoreProvider).themeMode;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(localStoreProvider).setThemeMode(mode);
  }
}

/// Installed version, e.g. "1.1.2" (set from the release tag at build time).
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

/// "Replay onboarding" setting.
///
/// [enabled] is the switch in Settings. [active] is whether this run of the
/// app is replaying: it is read once at launch, so turning the switch on
/// takes effect next time Oobli opens rather than yanking you out of Settings.
/// Finishing the flow turns both off.
@immutable
class OnboardingReplay {
  const OnboardingReplay({required this.enabled, required this.active});

  final bool enabled;
  final bool active;
}

final onboardingReplayProvider =
    NotifierProvider<OnboardingReplayController, OnboardingReplay>(OnboardingReplayController.new);

class OnboardingReplayController extends Notifier<OnboardingReplay> {
  LocalStore get _store => ref.read(localStoreProvider);

  @override
  OnboardingReplay build() {
    final on = _store.replayOnboarding;
    return OnboardingReplay(enabled: on, active: on);
  }

  Future<void> setEnabled(bool value) async {
    state = OnboardingReplay(enabled: value, active: state.active);
    await _store.setReplayOnboarding(value);
  }

  /// Called when the user completes onboarding.
  Future<void> finish() async {
    if (!state.enabled && !state.active) return;
    state = const OnboardingReplay(enabled: false, active: false);
    await _store.setReplayOnboarding(false);
  }
}
