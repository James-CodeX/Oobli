import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/network/resilient_http_overrides.dart';
import 'data/local/local_cache.dart';
import 'state/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // IPv4-first connections with fallback; must be set before any HttpClient exists.
  HttpOverrides.global = ResilientHttpOverrides();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  final cache = await FileCache.open();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localCacheProvider.overrideWithValue(cache),
      ],
      child: const OobliApp(),
    ),
  );
}
