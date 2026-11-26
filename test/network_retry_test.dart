import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oobli/core/errors/app_failure.dart';
import 'package:oobli/core/network/resilient_http_overrides.dart';
import 'package:oobli/core/network/retry.dart';

void main() {
  const abort = 'ClientException with SocketException: Software caused connection abort '
      '(OS Error: Software caused connection abort, errno = 103), address = sgp.cloud.appwrite.io';

  test('retries transient connection aborts, then succeeds', () async {
    var calls = 0;
    final result = await withNetworkRetry(() async {
      calls++;
      if (calls < 3) throw AppwriteException(abort);
      return 'ok';
    }, baseDelay: Duration.zero);
    expect(result, 'ok');
    expect(calls, 3);
  });

  test('does not retry HTTP errors such as invalid credentials', () async {
    var calls = 0;
    await expectLater(
      withNetworkRetry(() async {
        calls++;
        throw AppwriteException('Invalid credentials', 401, 'user_invalid_credentials');
      }, baseDelay: Duration.zero),
      throwsA(isA<AppwriteException>()),
    );
    expect(calls, 1);
  });

  test('gives up after the retry budget', () async {
    var calls = 0;
    await expectLater(
      withNetworkRetry(() async {
        calls++;
        throw AppwriteException(abort);
      }, retries: 2, baseDelay: Duration.zero),
      throwsA(isA<AppwriteException>()),
    );
    expect(calls, 3);
  });

  test('a request that never answers times out and is retried, then fails', () async {
    var calls = 0;
    await expectLater(
      withNetworkRetry(() {
        calls++;
        return Completer<String>().future; // a network that accepts but never replies
      }, retries: 1, baseDelay: Duration.zero, timeout: const Duration(milliseconds: 20)),
      throwsA(isA<TimeoutException>()),
    );
    expect(calls, 2);
    expect(AppFailure.from(TimeoutException('x')).message, isNot(contains('TimeoutException')));
  });

  test('writes run once under a deadline', () async {
    await expectLater(
      withDeadline(() => Completer<void>().future, timeout: const Duration(milliseconds: 20)),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('connection aborts get actionable guidance, not "offline"', () {
    final f = AppFailure.from(AppwriteException(abort));
    expect(f.message, contains('mobile data is allowed for Oobli'));
    expect(f.details, contains('errno = 103'));
  });

  test('literal IP hosts are not resolved', () async {
    final a = await ResilientHttpOverrides.orderedAddresses('151.101.3.52');
    expect(a.single.address, '151.101.3.52');
  });
}
