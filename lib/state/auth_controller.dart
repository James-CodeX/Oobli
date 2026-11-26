import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/local/local_cache.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';
import 'preferences.dart';
import 'sync_engine.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserProfile?>(AuthController.new);

/// The signed-in user's id, or null. Data providers watch this so they reset on sign-out.
final currentUserIdProvider =
    Provider<String?>((ref) => ref.watch(authControllerProvider.select((s) => s.value?.id)));

/// Offline-first session: the app never waits on the network to start.
///
/// * No cached session (fresh install, signed out) -> signed out immediately,
///   so onboarding and the auth screen work without internet.
/// * Cached session -> the user is let in at once with the cached profile,
///   and the session is re-validated with Appwrite in the background. Only an
///   explicit 401 signs them out; being offline keeps them in.
class AuthController extends AsyncNotifier<UserProfile?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  LocalStore get _store => ref.read(localStoreProvider);

  @override
  Future<UserProfile?> build() async {
    final cached = UserProfile.fromCache(_store.cachedSession);
    if (cached == null) return null;
    Future.microtask(_revalidate);
    return cached;
  }

  Future<void> _revalidate() async {
    try {
      final fresh = await _repo.currentUser();
      if (!ref.mounted) return;
      if (fresh == null) {
        await _publish(null);
      } else {
        await _publish(await _touchStreak(fresh));
      }
    } catch (e) {
      debugPrint('Session check deferred (offline?): $e');
    }
  }

  /// Sets the state and keeps the local session cache in sync with it.
  Future<void> _publish(UserProfile? user) async {
    state = AsyncData(user);
    if (user == null) {
      await _store.clearSession();
    } else {
      await _store.saveSession(user.toCache());
    }
  }

  Future<void> login({required String email, required String password}) async {
    final user = await _repo.login(email: email, password: password);
    await _publish(await _touchStreak(user));
  }

  Future<void> register({required String name, required String email, required String password}) async {
    final user = await _repo.register(name: name, email: email, password: password);
    await _publish(await _touchStreak(user));
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } finally {
      // Always sign out locally, even if the server could not be reached.
      await _store.clearUserData();
      await ref.read(outboxProvider.notifier).clear();
      await ref.read(localCacheProvider).clear();
      state = const AsyncData(null);
    }
  }

  /// Applies [change] to the profile and persists it to the account prefs.
  Future<void> updateProfile(UserProfile Function(UserProfile current) change) async {
    final current = state.value;
    if (current == null) return;
    final next = change(current);
    await _publish(next); // optimistic
    try {
      await _publish(await _repo.savePrefs(next));
    } catch (e) {
      await _publish(current);
      rethrow;
    }
  }

  Future<void> updateName(String name) async {
    if (state.value == null) return;
    await _publish(await _repo.updateName(name));
  }

  /// Daily-open streak, Duolingo style.
  Future<UserProfile> _touchStreak(UserProfile user) async {
    final fmt = DateFormat('yyyy-MM-dd');
    final now = DateTime.now();
    final today = fmt.format(now);
    if (user.lastActiveDay == today) return user;
    final yesterday = fmt.format(now.subtract(const Duration(days: 1)));
    final streak = user.lastActiveDay == yesterday ? user.streak + 1 : 1;
    final updated = user.copyWith(streak: streak, lastActiveDay: today);
    try {
      return await _repo.savePrefs(updated);
    } catch (e) {
      debugPrint('Could not save streak: $e');
      return updated;
    }
  }
}
