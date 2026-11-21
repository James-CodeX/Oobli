import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/app_failure.dart';
import 'sms_parser.dart';

final smsInboxServiceProvider = Provider<SmsInboxService>((ref) => SmsInboxService());

/// Reads financial SMS from the Android inbox through a platform channel
/// (see MainActivity.kt). Only messages from known financial senders are
/// returned; personal conversations never leave the native layer.
class SmsInboxService {
  static const _channel = MethodChannel('com.oobli.oobli/sms');

  bool get isSupported => Platform.isAndroid;

  Future<bool> hasPermission() async => isSupported && await Permission.sms.isGranted;

  /// Returns true when access was granted.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> isPermanentlyDenied() async =>
      isSupported && await Permission.sms.isPermanentlyDenied;

  Future<void> openSettings() => openAppSettings();

  Future<List<SmsMessage>> readFinancialMessages({required DateTime since, int limit = 3000}) async {
    if (!await hasPermission()) {
      throw const AppFailure('Oobli needs SMS access to read your M-Pesa messages.');
    }
    try {
      final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('readInbox', {
        'since': since.millisecondsSinceEpoch,
        'senders': FinancialSenders.all,
        'limit': limit,
      });
      return [
        for (final m in raw ?? const <Map<Object?, Object?>>[])
          SmsMessage(
            id: '${m['id']}',
            sender: m['address'] as String? ?? '',
            body: m['body'] as String? ?? '',
            receivedAt: DateTime.fromMillisecondsSinceEpoch((m['date'] as num).toInt()),
          ),
      ];
    } on PlatformException catch (e) {
      throw AppFailure('Could not read your messages: ${e.message ?? e.code}', cause: e);
    }
  }
}
