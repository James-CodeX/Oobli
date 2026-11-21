import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oobli/core/errors/app_failure.dart';
import 'package:oobli/data/models/user_profile.dart';
import 'package:oobli/data/repositories/auth_repository.dart';
import 'package:oobli/state/auth_controller.dart';
import 'package:oobli/state/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository double: [onCurrentUser] decides what the server "says".
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.onCurrentUser);

  final Future<UserProfile?> Function() onCurrentUser;
  int currentUserCalls = 0;

  @override
  Future<UserProfile?> currentUser() {
    currentUserCalls++;
    return onCurrentUser();
  }

  @override
  Future<UserProfile> savePrefs(UserProfile profile) async => profile;

  @override
  Future<UserProfile> login({required String email, required String password}) async => user;

  @override
  Future<UserProfile> register({required String name, required String email, required String password}) async =>
      user;

  @override
  Future<void> logout() async {}

  @override
  Future<UserProfile> updateName(String name) async => user.copyWith(name: name);
}

final user = UserProfile(
  id: 'u1',
  name: 'Jared Waweru',
  email: 'jared@example.com',
  createdAt: DateTime(2026, 6, 1),
  onboardingComplete: true,
);

Future<ProviderContainer> container(FakeAuthRepository repo, {UserProfile? cached}) async {
  SharedPreferences.setMockInitialValues(
    cached == null ? {} : {'session_profile': '{"id":"u1","name":"Jared Waweru","email":"jared@example.com",'
        '"createdAt":"2026-06-01T00:00:00.000Z","prefs":{"onboardingComplete":true}}'},
  );
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    authRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('fresh install is signed out instantly without touching the network', () async {
    final repo = FakeAuthRepository(() => throw StateError('network must not be called'));
    final c = await container(repo);
    expect(await c.read(authControllerProvider.future), isNull);
    await Future<void>.delayed(Duration.zero);
    expect(repo.currentUserCalls, 0);
  });

  test('cached session opens instantly and survives being offline', () async {
    final repo = FakeAuthRepository(() async => throw AppwriteException('Failed host lookup'));
    final c = await container(repo, cached: user);
    final profile = await c.read(authControllerProvider.future);
    expect(profile?.id, 'u1');
    expect(profile?.onboardingComplete, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repo.currentUserCalls, 1);
    expect(c.read(authControllerProvider).value?.id, 'u1');
  });

  test('cached session is cleared when the server says it expired', () async {
    final repo = FakeAuthRepository(() async => null);
    final c = await container(repo, cached: user);
    expect((await c.read(authControllerProvider.future))?.id, 'u1');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.read(authControllerProvider).value, isNull);
    expect(c.read(localStoreProvider).cachedSession, isNull);
  });

  group('AppFailure transport errors', () {
    test('DNS / socket failures read as offline', () {
      expect(AppFailure.from(AppwriteException('ClientException with SocketException: Failed host lookup')).message,
          AppFailure.offline);
    });

    test('TLS failures are not reported as offline and keep details', () {
      final f = AppFailure.from(AppwriteException('HandshakeException: CERTIFICATE_VERIFY_FAILED'));
      expect(f.message, contains('secure connection'));
      expect(f.details, contains('CERTIFICATE_VERIFY_FAILED'));
    });

    test('unknown transport errors are generic, not offline', () {
      final f = AppFailure.from(AppwriteException('Bad state: something odd'));
      expect(f.message, isNot(AppFailure.offline));
      expect(f.details, 'Bad state: something odd');
    });
  });
}
