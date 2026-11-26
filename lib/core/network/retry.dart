import 'dart:async';
import 'dart:io';

import 'package:appwrite/appwrite.dart';

/// True for brief transport hiccups worth retrying: dropped/aborted/reset
/// connections and timeouts. HTTP errors (4xx/5xx with a code) never qualify.
bool isTransientNetworkError(Object error) {
  if (error is SocketException || error is TimeoutException || error is HandshakeException) return true;
  if (error is HttpException) return true;
  if (error is AppwriteException && (error.code == null || error.code == 0)) {
    final m = (error.message ?? '').toLowerCase();
    return m.contains('connection abort') || m.contains('connection reset') ||
        m.contains('connection closed') || m.contains('broken pipe') ||
        m.contains('timed out') || m.contains('handshake') || m.contains('socketexception');
  }
  return false;
}

/// How long one request may take before it counts as failed. Without a
/// limit, a mobile network that accepts the connection but never answers
/// leaves screens loading forever.
const requestTimeout = Duration(seconds: 15);

/// Runs [action] once, failing with a [TimeoutException] after [timeout].
/// For writes that must not be repeated blindly.
Future<T> withDeadline<T>(Future<T> Function() action, {Duration timeout = requestTimeout}) =>
    action().timeout(timeout, onTimeout: () => throw TimeoutException('The request timed out', timeout));

/// Runs [action], retrying transient network failures (including timeouts)
/// with short backoff. Each attempt is limited to [timeout].
Future<T> withNetworkRetry<T>(
  Future<T> Function() action, {
  int retries = 2,
  Duration baseDelay = const Duration(milliseconds: 600),
  Duration timeout = requestTimeout,
}) async {
  for (var attempt = 0;; attempt++) {
    try {
      return await withDeadline(action, timeout: timeout);
    } catch (e) {
      if (attempt >= retries || !isTransientNetworkError(e)) rethrow;
      await Future<void>.delayed(baseDelay * (attempt + 1));
    }
  }
}
