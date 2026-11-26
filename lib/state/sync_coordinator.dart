import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'auth_controller.dart';
import 'sync_engine.dart';
import 'transactions_controller.dart';

/// True whenever the phone has a network interface up (Wi-Fi, mobile data…).
/// Overridable for tests.
final networkUpProvider = Provider<Stream<bool>>((ref) {
  try {
    return Connectivity()
        .onConnectivityChanged
        .map((results) => results.any((r) => r != ConnectivityResult.none))
        .handleError((Object e) => debugPrint('Connectivity events unavailable: $e'));
  } catch (e) {
    debugPrint('Connectivity events unavailable: $e');
    return const Stream<bool>.empty();
  }
});

/// Keeps the phone and the server in step while the user is signed in:
/// * the moment the network comes back, upload waiting changes, pull what
///   changed and read new M-Pesa messages;
/// * the same when the app returns to the foreground (at most once a minute);
/// * while offline, quietly try again every 30 seconds (some networks are
///   "connected" but can't reach the internet, e.g. a broken Private DNS).
///
/// Watched by the home shell, so it runs whenever the main app is open.
final syncCoordinatorProvider = Provider<void>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return;

  DateTime? lastCatchUp;
  var running = false;
  Future<void> catchUp({bool force = false}) async {
    final now = DateTime.now();
    if (running || (!force && lastCatchUp != null && now.difference(lastCatchUp!) < const Duration(minutes: 1))) {
      return;
    }
    running = true;
    lastCatchUp = now;
    try {
      final online = await ref.read(transactionsProvider.notifier).refresh();
      final profile = ref.read(authControllerProvider).value;
      if (online && (profile?.smsSyncEnabled ?? false)) {
        await ref.read(smsSyncControllerProvider.notifier).sync(silent: true);
      }
    } catch (e) {
      debugPrint('Catch-up failed: $e');
    } finally {
      running = false;
    }
  }

  var wasUp = true;
  final sub = ref.read(networkUpProvider).listen((up) {
    if (up && !wasUp) unawaited(catchUp(force: true));
    if (!up) ref.read(netStatusProvider.notifier).offline();
    wasUp = up;
  });

  final lifecycle = AppLifecycleListener(onResume: () => unawaited(catchUp()));

  final retry = Timer.periodic(const Duration(seconds: 30), (_) {
    if (ref.read(netStatusProvider).offline) unawaited(catchUp(force: true));
  });

  ref.onDispose(() {
    sub.cancel();
    lifecycle.dispose();
    retry.cancel();
  });
});
