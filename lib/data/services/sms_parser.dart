import 'package:flutter/foundation.dart';

import '../models/category.dart';
import '../models/transaction.dart';

/// A raw SMS as read from the device inbox.
@immutable
class SmsMessage {
  const SmsMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.receivedAt,
  });

  final String id;
  final String sender;
  final String body;
  final DateTime receivedAt;
}

/// A transaction extracted from an SMS, before categorisation/storage.
@immutable
class ParsedTransaction {
  const ParsedTransaction({
    required this.amount,
    required this.direction,
    required this.merchant,
    required this.channel,
    required this.source,
    required this.occurredAt,
    required this.raw,
    this.reference,
    this.balance,
    this.category,
  });

  final double amount;
  final TxDirection direction;
  final String merchant;
  final TxChannel channel;
  final TxSource source;
  final DateTime occurredAt;
  final String raw;
  final String? reference;
  final double? balance;

  /// Set when the message type alone determines the category (airtime, M-Shwari, Fuliza).
  final TxCategory? category;
}

/// Known financial senders. Matching is done on a normalised (alphanumeric,
/// lower-case) sender id so "M-PESA", "MPESA" and "Mpesa" all match.
abstract final class FinancialSenders {
  static const mpesa = ['mpesa'];
  static const banks = [
    'equity', 'kcb', 'coop', 'ncba', 'absa', 'stanbic', 'imbank', 'familybank',
    'dtb', 'stanchart', 'standardchartered', 'nationalbank', 'sidian',
    'kingdombank', 'faulu', 'hfgroup', 'gulfbank', 'creditbank', 'primebank',
  ];

  static String normalise(String sender) =>
      sender.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static bool isMpesa(String sender) => mpesa.contains(normalise(sender));

  static bool isBank(String sender) {
    final s = normalise(sender);
    return banks.any(s.contains);
  }

  static bool isFinancial(String sender) => isMpesa(sender) || isBank(sender);

  /// All sender patterns, passed to the native inbox reader so personal
  /// messages are filtered out before they ever reach Dart.
  static List<String> get all => [...mpesa, ...banks];
}

/// Deterministic parser for Safaricom M-Pesa confirmation messages.
/// Returns `null` for messages that are not completed money movements
/// (failed, reversed, Fuliza notices, promotions) or that it cannot parse.
abstract final class MpesaParser {
  static const _amt = r'Ksh\s?([\d,]+(?:\.\d{1,2})?)';
  static final _ref = RegExp(r'^\s*([A-Z0-9]{10})\s+confirmed', caseSensitive: false);
  static final _date = RegExp(
    r'on\s+(\d{1,2})/(\d{1,2})/(\d{2,4})\s+at\s+(\d{1,2}):(\d{2})\s*([AP]M)',
    caseSensitive: false,
  );
  static final _balance = RegExp('balance is $_amt', caseSensitive: false);
  static final _phone = RegExp(r'\s+(?:\+?254|0)[17]\d{8}$|\s+\d{3,4}\*{3}\d{3}$');

  static final _paidTo = RegExp('$_amt\\s+paid to\\s+(.+?)\\.?\\s+on\\s+\\d', caseSensitive: false);
  static final _paybill = RegExp(
    '$_amt\\s+sent to\\s+(.+?)\\s+for account\\s+(.+?)\\s+on\\s+\\d',
    caseSensitive: false,
  );
  static final _sentTo = RegExp('$_amt\\s+sent to\\s+(.+?)\\s+on\\s+\\d', caseSensitive: false);
  static final _received = RegExp(
    'received\\s+$_amt\\s+from\\s+(.+?)\\s+on\\s+\\d',
    caseSensitive: false,
  );
  static final _withdraw = RegExp(
    'withdraw\\s*$_amt\\s+from\\s+(.+?)\\s+New M-?PESA',
    caseSensitive: false,
  );
  static final _deposit = RegExp('Give\\s+$_amt\\s+cash to\\s+(.+?)\\s+New M-?PESA', caseSensitive: false);
  static final _airtime = RegExp('bought\\s+$_amt\\s+of airtime', caseSensitive: false);
  static final _toMshwari = RegExp('$_amt\\s+transferred to M-?Shwari', caseSensitive: false);
  static final _fromMshwari = RegExp('$_amt\\s+transferred from M-?Shwari', caseSensitive: false);
  static final _fulizaRepay = RegExp(
    '$_amt\\s+from your M-?PESA has been used to (?:fully |partially )?pay your outstanding Fuliza',
    caseSensitive: false,
  );
  static final _ignore = RegExp(
    r'failed|reversed|reversal|insufficient|Fuliza M-?PESA amount is|you have cancelled',
    caseSensitive: false,
  );

  static ParsedTransaction? parse(SmsMessage sms) {
    final body = sms.body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (_ignore.hasMatch(body)) {
      // Fuliza repayment notices mention Fuliza but are real outflows.
      if (!_fulizaRepay.hasMatch(body)) return null;
    }

    final reference = _ref.firstMatch(body)?.group(1)?.toUpperCase();
    final occurredAt = _parseDate(body) ?? sms.receivedAt;
    final balance = _money(_balance.firstMatch(body)?.group(1));

    ParsedTransaction build(
      String? amount,
      String merchant,
      TxChannel channel,
      TxDirection direction, {
      TxCategory? category,
    }) =>
        ParsedTransaction(
          amount: _money(amount) ?? 0,
          direction: direction,
          merchant: _cleanName(merchant),
          channel: channel,
          source: TxSource.mpesa,
          occurredAt: occurredAt,
          raw: sms.body,
          reference: reference,
          balance: balance,
          category: category,
        );

    ParsedTransaction? result;
    RegExpMatch? m;
    if ((m = _fulizaRepay.firstMatch(body)) != null) {
      result = build(m!.group(1), 'Fuliza M-Pesa', TxChannel.fuliza, TxDirection.out,
          category: TxCategory.debt);
    } else if ((m = _toMshwari.firstMatch(body)) != null) {
      result = build(m!.group(1), 'M-Shwari', TxChannel.other, TxDirection.out,
          category: TxCategory.savings);
    } else if ((m = _fromMshwari.firstMatch(body)) != null) {
      result = build(m!.group(1), 'M-Shwari', TxChannel.other, TxDirection.inbound,
          category: TxCategory.savings);
    } else if ((m = _airtime.firstMatch(body)) != null) {
      result = build(m!.group(1), 'Safaricom Airtime', TxChannel.airtime, TxDirection.out,
          category: TxCategory.airtime);
    } else if ((m = _paidTo.firstMatch(body)) != null) {
      result = build(m!.group(1), m.group(2)!, TxChannel.till, TxDirection.out);
    } else if ((m = _paybill.firstMatch(body)) != null) {
      result = build(m!.group(1), m.group(2)!, TxChannel.paybill, TxDirection.out);
    } else if ((m = _sentTo.firstMatch(body)) != null) {
      final recipient = m!.group(2)!;
      // Send Money includes the recipient's phone number; Pochi la Biashara does not.
      final isPerson = _phone.hasMatch(recipient);
      result = build(m.group(1), recipient, isPerson ? TxChannel.send : TxChannel.pochi,
          TxDirection.out);
    } else if ((m = _received.firstMatch(body)) != null) {
      // From a person (has a phone number): income. From a business or bank:
      // let the categoriser decide (bank withdrawal, loan, salary...).
      final sender = m!.group(2)!;
      result = build(m.group(1), sender, TxChannel.received, TxDirection.inbound,
          category: _phone.hasMatch(sender) ? TxCategory.income : null);
    } else if ((m = _withdraw.firstMatch(body)) != null) {
      final agent = m!.group(2)!;
      final name = agent.contains(' - ') ? agent.split(' - ').last : agent;
      result = build(m.group(1), 'Cash withdrawal · $name', TxChannel.withdraw, TxDirection.out,
          category: TxCategory.other);
    } else if ((m = _deposit.firstMatch(body)) != null) {
      // Depositing cash at an agent moves your own money into M-Pesa.
      result = build(m!.group(1), 'Cash deposit · ${m.group(2)}', TxChannel.deposit,
          TxDirection.inbound, category: TxCategory.ownTransfer);
    }

    if (result == null || result.amount <= 0) return null;
    return result;
  }

  static double? _money(String? s) =>
      s == null ? null : double.tryParse(s.replaceAll(',', ''));

  static DateTime? _parseDate(String body) {
    final m = _date.firstMatch(body);
    if (m == null) return null;
    final day = int.parse(m.group(1)!);
    final month = int.parse(m.group(2)!);
    var year = int.parse(m.group(3)!);
    if (year < 100) year += 2000;
    var hour = int.parse(m.group(4)!) % 12;
    if (m.group(6)!.toUpperCase() == 'PM') hour += 12;
    final minute = int.parse(m.group(5)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day, hour, minute);
  }

  /// "JOHN KAMAU 0712345678" -> "John Kamau"; "NAIVAS WESTLANDS." -> "Naivas Westlands".
  static String _cleanName(String raw) {
    final noPhone = raw.replaceAll(_phone, '').replaceAll(RegExp(r'[.\s]+$'), '').trim();
    return noPhone.split(RegExp(r'\s+')).map(_titleCase).join(' ');
  }

  static String _titleCase(String w) {
    if (w.isEmpty) return w;
    const keepUpper = {'KPLC', 'KCB', 'DTB', 'NHIF', 'SHA', 'KRA', 'NCBA', 'ATM', 'SGR', 'II'};
    if (keepUpper.contains(w.toUpperCase())) return w.toUpperCase();
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }
}
