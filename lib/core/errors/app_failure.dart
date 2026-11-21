import 'dart:async';
import 'dart:io';

import 'package:appwrite/appwrite.dart';

/// A user-presentable error. Every repository/service failure is mapped to
/// one of these so screens never show raw exception text. [details] keeps the
/// underlying technical message for the "Show details" affordance.
class AppFailure implements Exception {
  const AppFailure(this.message, {this.code, this.cause, this.details});

  final String message;
  final int? code;
  final Object? cause;
  final String? details;

  bool get isUnauthorized => code == 401;
  bool get isNotFound => code == 404;
  bool get isConflict => code == 409;

  static const offline = "You're offline or the connection is weak. Check your internet and try again.";

  factory AppFailure.from(Object error) {
    if (error is AppFailure) return error;
    if (error is AppwriteException) {
      // The SDK wraps transport errors (DNS, TLS, sockets) without a code.
      if (error.code == null || error.code == 0) return _transport(error.message ?? '', error);
      return AppFailure(_appwriteMessage(error), code: error.code, cause: error, details: error.message);
    }
    if (error is SocketException || error is TimeoutException || error is HttpException ||
        error is HandshakeException || error is TlsException) {
      return _transport(error.toString(), error);
    }
    return AppFailure('Something went wrong. Please try again.', cause: error, details: error.toString());
  }

  static AppFailure _transport(String raw, Object cause) {
    final text = raw.toLowerCase();
    final String message;
    if (text.contains('handshake') || text.contains('certificate') || text.contains('tls')) {
      message = "Couldn't open a secure connection to Oobli. Check your phone's date & time, "
          'VPN or Private DNS settings, then try again.';
    } else if (text.contains('connection abort')) {
      message = 'Your phone interrupted the connection to Oobli. Check that mobile data is allowed for Oobli '
          '(Settings → Apps → Oobli) and that no VPN, firewall or Data Saver is blocking it, then try again.';
    } else if (text.contains('timed out') || text.contains('timeout')) {
      message = 'Oobli is taking too long to respond. Please try again.';
    } else if (text.contains('failed host lookup') || text.contains('socket') ||
        text.contains('network is unreachable') || text.contains('connection refused') ||
        text.contains('connection reset') || text.contains('connection closed') ||
        text.contains('clientexception')) {
      message = offline;
    } else {
      message = "Couldn't reach Oobli's servers. Please try again.";
    }
    return AppFailure(message, cause: cause, details: raw.isEmpty ? cause.runtimeType.toString() : raw);
  }

  static String _appwriteMessage(AppwriteException e) {
    switch (e.type) {
      case 'user_invalid_credentials':
        return 'That email and password do not match. Try again?';
      case 'user_already_exists':
      case 'user_email_already_exists':
        return 'An account with this email already exists. Log in instead.';
      case 'password_recently_used':
      case 'password_personal_data':
        return 'Please choose a different password.';
      case 'general_argument_invalid':
        return e.message ?? 'Some details look invalid. Please check and try again.';
      case 'user_blocked':
        return 'This account has been blocked. Contact support.';
      case 'general_rate_limit_exceeded':
        return 'Too many attempts. Wait a moment and try again.';
    }
    if (e.code == 401) return 'Your session has expired. Please log in again.';
    return e.message ?? 'Something went wrong. Please try again.';
  }

  @override
  String toString() => 'AppFailure($code): $message${details == null ? '' : ' [$details]'}';
}
