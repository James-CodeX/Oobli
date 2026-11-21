import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';
import 'preferences.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserProfile?>(AuthController.new);

/// The signed-in user's id, or null. Data providers watch this so they reset on sign-out.
final currentUserIdProvider =
    Provider<String?>((ref) => ref.watch(authControllerProvider.select((s) => s.value?.id)));

class AuthController extends AsyncNotifier<UserProfile?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<UserProfile?> build() async {
    final user = await _repo.currentUser();
    if (user == null) return null;
    return _touchStreak(user);
  }

  Future<void> login({required String email, required String password}) async {
    final user = await _repo.login(email: email, password: password);
    state = AsyncData(await _touchStreak(user));
  }

  Future<void> register({required String name, required String email, required String password}) async {
    final user = await _repo.register(name: name, email: email, password: password);
    state = AsyncData(await _touchStreak(user));
  }

  Future<void> logout() async {
    await _repo.logout();
    await ref.read(localStoreProvider).clearUserData();
    state = const AsyncData(null);
  }

  /// Applies [change] to the profile and persists it to the account prefs.
  Future<void> updateProfile(UserProfile Function(UserProfile current) change) async {
    final current = state.value;
    if (current == null) return;
    final next = change(current);
    state = AsyncData(next); // optimistic
    try {
      state = AsyncData(await _repo.savePrefs(next));
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> updateName(String name) async {
    if (state.value == null) return;
    state = AsyncData(await _repo.updateName(name));
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
