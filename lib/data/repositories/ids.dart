import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Deterministic, globally unique row ids (Appwrite ids are unique per table
/// across all users, so the user id is part of the hash input).
/// Result: a letter prefix + 35 hex chars = 36 chars, the Appwrite maximum.
String deterministicId(String prefix, List<String> parts) {
  final digest = sha1.convert(utf8.encode(parts.join('|'))).toString();
  return '$prefix${digest.substring(0, 35)}';
}
