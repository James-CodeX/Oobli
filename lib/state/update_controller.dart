import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/errors/app_failure.dart';
import '../data/services/update_service.dart';
import 'preferences.dart';

/// The installed version and build number. Overridable for tests.
final installedAppProvider = FutureProvider<({String version, int build})>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return (version: info.version, build: int.tryParse(info.buildNumber) ?? 0);
});

/// Settings switch: look for updates automatically.
final autoUpdateCheckProvider = NotifierProvider<AutoUpdateCheck, bool>(AutoUpdateCheck.new);

class AutoUpdateCheck extends Notifier<bool> {
  @override
  bool build() => ref.read(localStoreProvider).autoUpdateCheck;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(localStoreProvider).setAutoUpdateCheck(value);
    if (value) await ref.read(updateProvider.notifier).check();
  }
}

enum UpdatePhase { idle, checking, downloading, needsPermission, installing, failed }

@immutable
class UpdateState {
  const UpdateState({
    this.available,
    this.phase = UpdatePhase.idle,
    this.progress = 0,
    this.error,
    this.checked = false,
    this.dismissed = false,
  });

  /// A newer version than the one installed, if one was found.
  final AppUpdate? available;
  final UpdatePhase phase;

  /// Download progress, 0 to 1.
  final double progress;
  final String? error;

  /// At least one check finished (so "up to date" means something).
  final bool checked;

  /// The user closed the home-screen banner for [available].
  final bool dismissed;

  bool get busy => phase == UpdatePhase.checking || phase == UpdatePhase.downloading;
  bool get showBanner => available != null && !dismissed;

  UpdateState copyWith({
    AppUpdate? available,
    UpdatePhase? phase,
    double? progress,
    String? error,
    bool? checked,
    bool? dismissed,
  }) =>
      UpdateState(
        available: available ?? this.available,
        phase: phase ?? this.phase,
        progress: progress ?? this.progress,
        error: error,
        checked: checked ?? this.checked,
        dismissed: dismissed ?? this.dismissed,
      );
}

final updateProvider = NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

/// Finds new versions and installs them from inside the app, so nobody has
/// to visit the website for every release.
class UpdateController extends Notifier<UpdateState> {
  /// Automatic checks happen at most this often (on launch and on resume).
  static const autoInterval = Duration(hours: 3);

  DateTime? _lastAuto;

  UpdateService get _service => ref.read(updateServiceProvider);

  @override
  UpdateState build() => const UpdateState();

  /// Looks for a newer version. Automatic checks ([manual] false) respect
  /// the Settings switch, run at most every [autoInterval] and stay silent
  /// on failure. Returns the update found, if any.
  Future<AppUpdate?> check({bool manual = false}) async {
    if (!_service.supported || state.busy) return state.available;
    if (!manual) {
      final now = DateTime.now();
      if (!ref.read(autoUpdateCheckProvider)) return null;
      if (_lastAuto != null && now.difference(_lastAuto!) < autoInterval) return state.available;
      _lastAuto = now;
    }
    if (manual) state = state.copyWith(phase: UpdatePhase.checking);
    try {
      final installed = await ref.read(installedAppProvider.future);
      final latest = await _service.latest();
      final newer = latest != null && latest.isNewerThan(installed.version, installed.build) ? latest : null;
      if (!ref.mounted) return newer;
      state = UpdateState(
        available: newer,
        checked: true,
        dismissed: newer != null && ref.read(localStoreProvider).dismissedUpdate == newer.version,
      );
      return newer;
    } catch (e) {
      debugPrint('Update check failed: $e');
      if (!ref.mounted) return null;
      state = state.copyWith(phase: manual ? UpdatePhase.failed : UpdatePhase.idle, error: manual ? _message(e) : null);
      if (manual) rethrow;
      return null;
    }
  }

  /// Hides the home-screen banner for this version (Settings still offers it).
  Future<void> dismiss() async {
    final update = state.available;
    if (update == null) return;
    state = state.copyWith(dismissed: true);
    await ref.read(localStoreProvider).setDismissedUpdate(update.version);
  }

  /// Downloads the update (with progress) and opens Android's installer.
  Future<void> downloadAndInstall() async {
    final update = state.available;
    if (update == null || state.phase == UpdatePhase.downloading) return;
    state = state.copyWith(phase: UpdatePhase.downloading, progress: 0);
    try {
      final apk = await _service.download(update, onProgress: (p) {
        if (ref.mounted && (p - state.progress >= 0.01 || p == 1)) state = state.copyWith(progress: p);
      });
      if (!ref.mounted) return;
      final result = await _service.install(apk);
      if (!ref.mounted) return;
      state = state.copyWith(
        progress: 1,
        phase: switch (result) {
          InstallResult.needsPermission => UpdatePhase.needsPermission,
          InstallResult.started => UpdatePhase.installing,
          InstallResult.unsupported => UpdatePhase.failed,
        },
        error: result == InstallResult.unsupported ? 'Updates install on Android only.' : null,
      );
    } catch (e) {
      debugPrint('Update download failed: $e');
      if (ref.mounted) state = state.copyWith(phase: UpdatePhase.failed, error: _message(e));
    }
  }

  static String _message(Object e) {
    if (e is AppFailure) return e.message;
    if (AppFailure.isRetryable(e)) return "Couldn't reach the update server. Check your connection and try again.";
    return 'The update failed. Please try again.';
  }
}
