import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
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

  bool get seenIntro => _prefs.getBool(_seenIntro) ?? false;
  Future<void> setSeenIntro() => _prefs.setBool(_seenIntro, true);

  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_prefs.getString(_themeMode)] ?? ThemeMode.system;
  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString(_themeMode, mode.name);

  int get aiCorrections => _prefs.getInt(_aiCorrections) ?? 0;
  Future<void> incrementAiCorrections() => _prefs.setInt(_aiCorrections, aiCorrections + 1);

  Set<String> get dismissedSuggestions =>
      (_prefs.getStringList(_dismissedSuggestions) ?? const []).toSet();
  Future<void> dismissSuggestion(String merchantKey) =>
      _prefs.setStringList(_dismissedSuggestions, [...dismissedSuggestions, merchantKey]);

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
