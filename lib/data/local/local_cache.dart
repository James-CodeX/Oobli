import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// The on-device copy of the user's data. main() overrides this with a
/// [FileCache]; tests use the in-memory default.
final localCacheProvider = Provider<LocalCache>((ref) => MemoryCache());

/// A small JSON document store: one document per name. Used so the app can
/// show the last known numbers instantly and offline.
abstract class LocalCache {
  Future<Map<String, dynamic>?> read(String name);
  Future<void> write(String name, Map<String, dynamic> value);
  Future<void> remove(String name);
  Future<void> clear();
}

/// Documents stored as files in the app's private support directory.
/// Writes go to a temp file first and are renamed into place, so a crash
/// mid-write never leaves a half-written cache.
class FileCache implements LocalCache {
  FileCache(this._dir);

  final Directory _dir;
  final _chains = <String, Future<void>>{};

  static Future<LocalCache> open() async {
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/oobli_cache');
      await dir.create(recursive: true);
      return FileCache(dir);
    } catch (e) {
      debugPrint('Offline cache unavailable, keeping data in memory: $e');
      return MemoryCache();
    }
  }

  File _file(String name) => File('${_dir.path}/${name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.json');

  /// Runs file operations for one document in order.
  Future<T> _serial<T>(String name, Future<T> Function() op) {
    final previous = _chains[name] ?? Future<void>.value();
    final next = previous.then((_) => op(), onError: (_) => op());
    _chains[name] = next.then<void>((_) {}, onError: (_) {});
    return next;
  }

  @override
  Future<Map<String, dynamic>?> read(String name) => _serial(name, () async {
        final file = _file(name);
        if (!await file.exists()) return null;
        try {
          return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Ignoring unreadable cache "$name": $e');
          return null;
        }
      });

  @override
  Future<void> write(String name, Map<String, dynamic> value) => _serial(name, () async {
        final file = _file(name);
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsString(jsonEncode(value), flush: true);
        await tmp.rename(file.path);
      });

  @override
  Future<void> remove(String name) => _serial(name, () async {
        final file = _file(name);
        if (await file.exists()) await file.delete();
      });

  @override
  Future<void> clear() async {
    if (!await _dir.exists()) return;
    await for (final entity in _dir.list()) {
      if (entity is File) await entity.delete();
    }
  }
}

/// Keeps documents in memory (as JSON text, so it behaves like the file store).
class MemoryCache implements LocalCache {
  final _data = <String, String>{};

  @override
  Future<Map<String, dynamic>?> read(String name) async {
    final raw = _data[name];
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> write(String name, Map<String, dynamic> value) async => _data[name] = jsonEncode(value);

  @override
  Future<void> remove(String name) async => _data.remove(name);

  @override
  Future<void> clear() async => _data.clear();
}

/// Shows the saved copy of [name] at once and refreshes it from the server in
/// the background ([onFresh] receives the new value). With nothing saved yet,
/// waits for the server. Used for small documents: rules, goals, the plan.
Future<T> cacheFirst<T>({
  required LocalCache cache,
  required String name,
  required Future<T> Function() fetch,
  required Object? Function(T value) encode,
  required T Function(Object? json) decode,
  required void Function(T value) onFresh,
}) async {
  Future<T> load() async {
    final value = await fetch();
    unawaited(cache.write(name, {'v': encode(value)}).catchError((Object e) {
      debugPrint('Could not save "$name" offline: $e');
    }));
    return value;
  }

  final saved = await cache.read(name);
  if (saved == null || !saved.containsKey('v')) return load();
  T cached;
  try {
    cached = decode(saved['v']);
  } catch (e) {
    debugPrint('Ignoring outdated cache "$name": $e');
    return load();
  }
  unawaited(load().then(onFresh, onError: (Object e) => debugPrint('Background refresh of "$name" failed: $e')));
  return cached;
}
