import 'package:flutter/foundation.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import 'keyword_categorizer.dart';

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
    this.categorySure = true,
    this.sameAs,
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

  /// False when [category] is only the likely answer, so the user is asked.
  final bool categorySure;

  /// Messages that describe the same payment share this key, so it is stored
  /// once (a bank's "request received" and its "payment received").
  final String? sameAs;
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
      // M-Shwari holds savings and lends: the message says which this was.
      result = build(m!.group(1), 'M-Shwari', TxChannel.other, TxDirection.out,
          category: KeywordCategorizer.mentionsLoan(body) ? TxCategory.debt : TxCategory.savings);
    } else if ((m = _fromMshwari.firstMatch(body)) != null) {
      result = build(m!.group(1), 'M-Shwari', TxChannel.other, TxDirection.inbound,
          category: KeywordCategorizer.mentionsLoan(body) ? TxCategory.debt : TxCategory.savings);
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

/// On-device reader for the bank messages whose meaning is clear from their
/// wording: money arriving from M-Pesa, loan repayments and disbursements,
/// and moves in and out of savings. Anything else goes to the AI.
abstract final class BankParser {
  static const _amt = r'(?:KES|Ksh)\.?\s?([\d,]+(?:\.\d{1,2})?)';
  static const _ci = false;

  /// Offers, limits, notices and failures: never a money movement.
  static final _noise = RegExp(
    r'borrow up to|can now borrow|loan limit|limit has been|you (?:now )?qualify|pre-?approved|'
    r'apply (?:now|for)|will be unavailable|maintenance|failed|unsuccessful|declined|insufficient|'
    r'reversed|reversal',
    caseSensitive: _ci,
  );

  // A real code has a digit, so "Transaction Completed" yields none.
  static final _code = RegExp(r'^\s*((?=[A-Z0-9]*\d)[A-Z0-9]{10,20})\s+(?:[Cc]ompleted|[Cc]onfirmed)');
  static final _fromMpesa = RegExp(
    '$_amt\\s+received in a/?\\s?c\\b.*?M-?PESA Ref\\.?:?\\s*([A-Z0-9]{8,12})',
    caseSensitive: _ci,
  );
  static final _repaid = [
    RegExp('repayment (?:request )?of $_amt', caseSensitive: _ci),
    RegExp('payment of $_amt for [^.]{0,60}\\bloan\\b', caseSensitive: _ci),
    RegExp('$_amt [^.]{0,40}(?:repaid|paid) (?:to|towards) [^.]{0,40}\\bloan\\b', caseSensitive: _ci),
  ];
  static final _borrowed = [
    RegExp('(?:loan|advance) (?:amount )?of $_amt (?:has been |was )?(?:disbursed|credited|deposited|sent)',
        caseSensitive: _ci),
    RegExp('$_amt (?:loan|salary advance) (?:has been |was )?(?:disbursed|credited|deposited)', caseSensitive: _ci),
  ];

  /// "KES 2,000.00 transferred to KCB M-PESA account" (into savings).
  static final _toSavings = RegExp('$_amt\\s+transferred to (.+?) account', caseSensitive: _ci);

  /// "You have transferred KES 2,000.00 from your M-PESA savings Account to M-PESA".
  static final _fromSavings = RegExp('transferred\\s+$_amt\\s+from your (.+?) to ', caseSensitive: _ci);
  static final _savingsPlace = RegExp(r'savings|kcb m-?pesa|m-?shwari|\block\b', caseSensitive: _ci);

  static final _dmy = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2,4})\s+(?:at\s+)?(\d{1,2}):(\d{2})(?::\d{2})?\s*([AP]M)?',
      caseSensitive: _ci);
  static final _ymd = RegExp(r'(\d{4})-(\d{2})-(\d{2})\s+(\d{1,2}):(\d{2})(?::\d{2})?\s*([AP]M)?', caseSensitive: _ci);

  /// Whether the message is a bank notice that records no money movement.
  static bool isNoise(SmsMessage sms) => _noise.hasMatch(sms.body);

  /// The transaction in [sms], or `null` when its wording is not one Oobli
  /// knows (the AI reads those).
  static ParsedTransaction? parse(SmsMessage sms) {
    final body = sms.body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (_noise.hasMatch(body)) return null;
    final bank = bankName(sms.sender);
    final occurredAt = _date(body) ?? sms.receivedAt;
    final code = _code.firstMatch(body)?.group(1)?.toUpperCase();

    ParsedTransaction? build(
      String? amount,
      String merchant,
      TxDirection direction,
      TxCategory category, {
      TxChannel channel = TxChannel.bank,
      String? reference,
      bool sure = true,
      String? sameAs,
    }) {
      final value = double.tryParse((amount ?? '').replaceAll(',', ''));
      if (value == null || value <= 0) return null;
      return ParsedTransaction(
        amount: value,
        direction: direction,
        merchant: merchant,
        channel: channel,
        source: TxSource.bank,
        occurredAt: occurredAt,
        raw: sms.body,
        reference: reference ?? code,
        category: category,
        categorySure: sure,
        sameAs: sameAs,
      );
    }

    // Banks often send two messages for one loan payment; store it once.
    String sameLoan(TxDirection d, String? amount) =>
        'loan|$bank|${d.name}|${double.tryParse((amount ?? '').replaceAll(',', ''))}|'
        '${occurredAt.year}-${occurredAt.month}-${occurredAt.day}';

    RegExpMatch? m;
    if ((m = _fromMpesa.firstMatch(body)) != null) {
      // Usually the user topping up their own account from M-Pesa, but anyone
      // can pay in: sure only once the matching M-Pesa send is found.
      return build(m!.group(1), 'M-Pesa to $bank', TxDirection.inbound, TxCategory.ownTransfer,
          reference: m.group(2)!.toUpperCase(), sure: false);
    }
    for (final r in _repaid) {
      if ((m = r.firstMatch(body)) != null) {
        return build(m!.group(1), '$bank loan', TxDirection.out, TxCategory.debt,
            sameAs: sameLoan(TxDirection.out, m.group(1)));
      }
    }
    for (final r in _borrowed) {
      if ((m = r.firstMatch(body)) != null) {
        return build(m!.group(1), '$bank loan', TxDirection.inbound, TxCategory.debt,
            sameAs: sameLoan(TxDirection.inbound, m.group(1)));
      }
    }
    final loan = KeywordCategorizer.mentionsLoan(body);
    if ((m = _toSavings.firstMatch(body)) != null && _savingsPlace.hasMatch(m!.group(2)!)) {
      return build(m.group(1), _savingsName(m.group(2)!, bank), TxDirection.out,
          loan ? TxCategory.debt : TxCategory.savings, channel: TxChannel.other);
    }
    if ((m = _fromSavings.firstMatch(body)) != null && _savingsPlace.hasMatch(m!.group(2)!)) {
      return build(m.group(1), _savingsName(m.group(2)!, bank), TxDirection.inbound,
          loan ? TxCategory.debt : TxCategory.savings, channel: TxChannel.other);
    }
    return null;
  }

  static String _savingsName(String place, String bank) {
    final p = place.toLowerCase();
    if (RegExp(r'kcb m-?pesa').hasMatch(p) || bank == 'KCB M-Pesa') return 'KCB M-Pesa';
    if (RegExp(r'm-?shwari').hasMatch(p)) return 'M-Shwari';
    return '$bank savings';
  }

  static const _names = {
    'kcbmpesa': 'KCB M-Pesa',
    'kcb': 'KCB',
    'equity': 'Equity Bank',
    'coop': 'Co-op Bank',
    'ncba': 'NCBA',
    'absa': 'Absa',
    'stanbic': 'Stanbic',
    'imbank': 'I&M Bank',
    'familybank': 'Family Bank',
    'dtb': 'DTB',
    'stanchart': 'Standard Chartered',
    'standardchartered': 'Standard Chartered',
    'nationalbank': 'National Bank',
    'sidian': 'Sidian Bank',
    'kingdombank': 'Kingdom Bank',
    'faulu': 'Faulu',
    'hfgroup': 'HF Group',
    'gulfbank': 'Gulf African Bank',
    'creditbank': 'Credit Bank',
    'primebank': 'Prime Bank',
  };

  /// A readable bank name for an SMS sender id ("KCB M-PESA" -> "KCB M-Pesa").
  static String bankName(String sender) {
    final s = FinancialSenders.normalise(sender);
    for (final e in _names.entries) {
      if (s.contains(e.key)) return e.value;
    }
    return sender.trim();
  }

  static DateTime? _date(String body) {
    int hour(String h, String? ampm) {
      var v = int.parse(h);
      if (ampm == null) return v;
      v %= 12;
      return ampm.toUpperCase() == 'PM' ? v + 12 : v;
    }

    final ymd = _ymd.firstMatch(body);
    if (ymd != null) {
      final month = int.parse(ymd.group(2)!), day = int.parse(ymd.group(3)!);
      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      return DateTime(int.parse(ymd.group(1)!), month, day, hour(ymd.group(4)!, ymd.group(6)), int.parse(ymd.group(5)!));
    }
    final dmy = _dmy.firstMatch(body);
    if (dmy == null) return null;
    final day = int.parse(dmy.group(1)!), month = int.parse(dmy.group(2)!);
    var year = int.parse(dmy.group(3)!);
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day, hour(dmy.group(4)!, dmy.group(6)), int.parse(dmy.group(5)!));
  }
}
