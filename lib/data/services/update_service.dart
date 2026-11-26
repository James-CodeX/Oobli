import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../../core/network/retry.dart';

/// A newer Oobli published by the Release workflow (`latest.json` in the
/// public `downloads` bucket).
@immutable
class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.build,
    required this.apkUrl,
    required this.size,
    required this.sha256,
    required this.notes,
  });

  final String version;
  final int build;
  final String apkUrl;
  final int size;
  final String sha256;

  /// The release's commit message: a title line, then details.
  final String notes;

  factory AppUpdate.fromJson(Map<String, dynamic> j) => AppUpdate(
        version: j['version'] as String,
        build: (j['build'] as num?)?.toInt() ?? 0,
        apkUrl: j['apk'] as String,
        size: (j['size'] as num?)?.toInt() ?? 0,
        sha256: (j['sha256'] as String? ?? '').toLowerCase(),
        notes: j['notes'] as String? ?? '',
      );

  /// First line of the notes: what this release is about.
  String get headline => notes.split('\n').first.trim();

  /// The "- " bullet points from the notes, without the dash.
  List<String> get highlights => [
        for (final line in notes.split('\n'))
          if (line.trimLeft().startsWith('- ')) line.trimLeft().substring(2).trim(),
      ];

  /// Whether this is newer than the installed [version] (+[build]).
  bool isNewerThan(String version, int build) {
    final a = _parts(this.version);
    final b = _parts(version);
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return this.build > build && build > 0;
  }

  static List<int> _parts(String v) {
    final nums = v.split('+').first.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    return [for (var i = 0; i < 3; i++) i < nums.length ? nums[i] : 0];
  }
}

/// What happened when Oobli asked Android to install a downloaded update.
enum InstallResult { started, needsPermission, unsupported }

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

/// Finds, downloads and hands updates to the Android package installer.
/// Android checks the APK is signed with the same key as the installed app,
/// so only genuine Oobli releases can replace it.
class UpdateService {
  static const _channel = MethodChannel('com.oobli.oobli/update');

  static String get manifestUrl =>
      '${AppConfig.appwriteEndpoint}/storage/buckets/downloads/files/oobli-latest/view'
      '?project=${AppConfig.appwriteProjectId}';

  bool get supported => !kIsWeb && Platform.isAndroid;

  /// The newest published release, or null if none is published yet.
  Future<AppUpdate?> latest() => withNetworkRetry(() async {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
        try {
          // A changing query string so no cache hands back yesterday's answer.
          final url = Uri.parse('$manifestUrl&t=${DateTime.now().millisecondsSinceEpoch ~/ 60000}');
          final res = await (await client.getUrl(url)).close();
          if (res.statusCode == 404) return null;
          if (res.statusCode != 200) throw HttpException('Update check failed (${res.statusCode})');
          final body = await res.transform(utf8.decoder).join();
          return AppUpdate.fromJson(jsonDecode(body) as Map<String, dynamic>);
        } finally {
          client.close(force: true);
        }
      });

  /// Downloads [update]'s APK, reporting progress from 0 to 1. Reuses an
  /// earlier complete download, and checks the size and SHA-256.
  Future<File> download(AppUpdate update, {void Function(double progress)? onProgress}) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/updates');
    await dir.create(recursive: true);
    final file = File('${dir.path}/oobli-${update.version}.apk');
    if (await file.exists() && await _matches(file, update)) {
      onProgress?.call(1);
      return file;
    }
    // Old downloads are dead weight.
    await for (final f in dir.list()) {
      if (f is File) await f.delete().catchError((_) => f);
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    final part = File('${file.path}.part');
    try {
      final res = await (await client.getUrl(Uri.parse(update.apkUrl))).close().timeout(requestTimeout);
      if (res.statusCode != 200) throw HttpException('Download failed (${res.statusCode})');
      final total = update.size > 0 ? update.size : res.contentLength;
      final sink = part.openWrite();
      final digest = _DigestSink();
      final hasher = sha256.startChunkedConversion(digest);
      var received = 0;
      try {
        // A stalled connection fails instead of hanging forever.
        await for (final chunk in res.timeout(const Duration(seconds: 30))) {
          sink.add(chunk);
          hasher.add(chunk);
          received += chunk.length;
          if (total > 0) onProgress?.call((received / total).clamp(0, 1).toDouble());
        }
      } finally {
        await sink.close();
        hasher.close();
      }
      if (update.size > 0 && received != update.size) {
        throw const AppFailure('The download was cut short. Please try again.');
      }
      if (update.sha256.isNotEmpty && digest.value.toString() != update.sha256) {
        throw const AppFailure("The download didn't match the release. Please try again.");
      }
      return await part.rename(file.path);
    } catch (_) {
      if (await part.exists()) await part.delete();
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> _matches(File file, AppUpdate update) async {
    if (update.size > 0 && await file.length() != update.size) return false;
    if (update.sha256.isEmpty) return true;
    return (await sha256.bind(file.openRead()).first).toString() == update.sha256;
  }

  /// Opens Android's installer for [apk]. The first time, Android asks the
  /// user to let Oobli install apps; then this returns [needsPermission].
  Future<InstallResult> install(File apk) async {
    if (!supported) return InstallResult.unsupported;
    final allowed = await _channel.invokeMethod<bool>('canInstall') ?? true;
    if (!allowed) {
      await _channel.invokeMethod<void>('openInstallSettings');
      return InstallResult.needsPermission;
    }
    await _channel.invokeMethod<void>('install', {'path': apk.path});
    return InstallResult.started;
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
