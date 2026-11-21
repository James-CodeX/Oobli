import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/network/retry.dart';
import '../appwrite/appwrite_providers.dart';
import '../models/user_profile.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(accountProvider)));

class AuthRepository {
  AuthRepository(this._account);

  final Account _account;

  /// The current session's user, or `null` when signed out.
  Future<UserProfile?> currentUser() async {
    try {
      return _toProfile(await withNetworkRetry(_account.get));
    } on AppwriteException catch (e) {
      if (e.code == 401) return null;
      throw AppFailure.from(e);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<UserProfile> login({required String email, required String password}) async {
    try {
      await withNetworkRetry(() => _account.createEmailPasswordSession(email: email.trim(), password: password));
      return _toProfile(await withNetworkRetry(_account.get));
    } on AppwriteException catch (e) {
      // A stale session blocks new logins; clear it and retry once.
      if (e.type == 'user_session_already_exists') {
        await _account.deleteSession(sessionId: 'current');
        return login(email: email, password: password);
      }
      throw AppFailure.from(e);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await withNetworkRetry(() => _account.create(
            userId: ID.unique(),
            email: email.trim(),
            password: password,
            name: name.trim(),
          ));
    } on AppwriteException catch (e) {
      // "Already exists" after a retry usually means our first attempt went
      // through but its response was lost; logging in completes sign-up.
      if (e.code != 409) throw AppFailure.from(e);
      try {
        return await login(email: email, password: password);
      } on AppFailure {
        throw AppFailure.from(e);
      }
    } catch (e) {
      throw AppFailure.from(e);
    }
    return login(email: email, password: password);
  }

  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      if (e.code != 401) throw AppFailure.from(e);
    }
  }

  Future<UserProfile> savePrefs(UserProfile profile) async {
    try {
      final user = await _account.updatePrefs(prefs: profile.toPrefs());
      return _toProfile(user);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<UserProfile> updateName(String name) async {
    try {
      return _toProfile(await _account.updateName(name: name.trim()));
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  UserProfile _toProfile(models.User user) => UserProfile.fromAccount(
        id: user.$id,
        name: user.name,
        email: user.email,
        createdAt: user.$createdAt,
        prefs: Map<String, dynamic>.from(user.prefs.data),
      );
}
