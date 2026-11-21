import 'dart:async';
import 'dart:io';

import 'package:appwrite/appwrite.dart';

/// A user-presentable error. Every repository/service failure is mapped to
/// one of these so screens never show raw exception text.
class AppFailure implements Exception {
  const AppFailure(this.message, {this.code, this.cause});

  final String message;
  final int? code;
  final Object? cause;

  bool get isUnauthorized => code == 401;
  bool get isNotFound => code == 404;
  bool get isConflict => code == 409;

  factory AppFailure.from(Object error) {
    if (error is AppFailure) return error;
    if (error is AppwriteException) {
      return AppFailure(_appwriteMessage(error), code: error.code, cause: error);
    }
    if (error is SocketException || error is TimeoutException || error is HttpException) {
      return AppFailure(
        "You're offline or the connection is weak. Check your internet and try again.",
        cause: error,
      );
    }
    return AppFailure('Something went wrong. Please try again.', cause: error);
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
    if (e.code == null || e.code == 0) {
      return "You're offline or the connection is weak. Check your internet and try again.";
    }
    if (e.code == 401) return 'Your session has expired. Please log in again.';
    return e.message ?? 'Something went wrong. Please try again.';
  }

  @override
  String toString() => 'AppFailure($code): $message';
}
