import 'package:flutter_test/flutter_test.dart';
import 'package:oobli/data/models/category.dart';
import 'package:oobli/data/models/transaction.dart';
import 'package:oobli/data/services/keyword_categorizer.dart';
import 'package:oobli/data/services/sms_parser.dart';
import 'package:oobli/data/services/transaction_categorizer.dart';

SmsMessage sms(String body, {String sender = 'MPESA'}) =>
    SmsMessage(id: '1', sender: sender, body: body, receivedAt: DateTime(2026, 11, 21, 12));

void main() {
  group('MpesaParser', () {
    test('parses Send Money with phone number as a person transfer', () {
      final p = MpesaParser.parse(sms(
        'TK12ABC3DE Confirmed. Ksh1,200.00 sent to JOHN KAMAU 0712345678 on 20/11/26 at 10:30 AM. '
        'New M-PESA balance is Ksh5,000.00. Transaction cost, Ksh13.00.',
      ))!;
      expect(p.amount, 1200);
      expect(p.direction, TxDirection.out);
      expect(p.channel, TxChannel.send);
      expect(p.merchant, 'John Kamau');
      expect(p.reference, 'TK12ABC3DE');
      expect(p.balance, 5000);
      expect(p.occurredAt, DateTime(2026, 11, 20, 10, 30));
    });

    test('parses Pochi la Biashara (no phone number)', () {
      final p = MpesaParser.parse(sms(
        'TK12ABC3DF Confirmed. Ksh450.00 sent to MAMA MBOGA on 21/11/26 at 10:45 AM. New M-PESA balance is Ksh4,550.00.',
      ))!;
      expect(p.channel, TxChannel.pochi);
      expect(p.merchant, 'Mama Mboga');
      expect(p.amount, 450);
    });

    test('parses Buy Goods till payments', () {
      final p = MpesaParser.parse(sms(
        'TK12ABC3DG Confirmed. Ksh2,100.00 paid to NAIVAS WESTLANDS. on 21/11/26 at 1:15 PM.New M-PESA balance is Ksh2,450.00.',
      ))!;
      expect(p.channel, TxChannel.till);
      expect(p.merchant, 'Naivas Westlands');
      expect(p.occurredAt, DateTime(2026, 11, 21, 13, 15));
    });

    test('parses Paybill with account number', () {
      final p = MpesaParser.parse(sms(
        'TK12ABC3DH Confirmed. Ksh1,000.00 sent to KPLC PREPAID for account 54012345678 on 21/11/26 at 9:15 AM '
        'New M-PESA balance is Ksh1,450.00. Transaction cost, Ksh0.00.',
      ))!;
      expect(p.channel, TxChannel.paybill);
      expect(p.merchant, 'KPLC Prepaid');
    });

    test('parses received money as income', () {
      final p = MpesaParser.parse(sms(
        'TK12ABC3DI Confirmed.You have received Ksh15,000.00 from JANE WANJIKU 0722000111 on 21/11/26 at 3:00 PM '
        'New M-PESA balance is Ksh16,450.00.',
      ))!;
      expect(p.direction, TxDirection.inbound);
      expect(p.category, TxCategory.income);
      expect(p.merchant, 'Jane Wanjiku');
    });

    test('parses airtime, withdrawals, M-Shwari and Fuliza repayments', () {
      expect(
        MpesaParser.parse(sms('TK1 confirmed.You bought Ksh100.00 of airtime on 21/11/26 at 8:00 AM.New M-PESA balance is Ksh900.00.'))!
            .category,
        TxCategory.airtime,
      );
      final withdraw = MpesaParser.parse(sms(
        'TK12ABC3DJ Confirmed.on 21/11/26 at 3:00 PMWithdraw Ksh2,000.00 from 123456 - JOHN AGENT SHOP New M-PESA balance is Ksh500.00.',
      ))!;
      expect(withdraw.channel, TxChannel.withdraw);
      expect(withdraw.amount, 2000);
      expect(
        MpesaParser.parse(sms('TK12ABC3DK Confirmed.Ksh500.00 transferred to M-Shwari account on 21/11/26 at 9:00 AM. M-PESA balance is Ksh1,000.00.'))!
            .category,
        TxCategory.savings,
      );
      expect(
        MpesaParser.parse(sms(
          'TK12ABC3DL Confirmed. Ksh 200.00 from your M-PESA has been used to fully pay your outstanding Fuliza M-PESA. '
          'Available Fuliza M-PESA limit is Ksh 1,000.00.',
        ))!
            .category,
        TxCategory.debt,
      );
    });

    test('ignores failed, reversed and Fuliza notices', () {
      expect(MpesaParser.parse(sms('Failed. Insufficient funds in your M-PESA account to send Ksh5,000.00.')), isNull);
      expect(
        MpesaParser.parse(sms('TK1 Confirmed. Fuliza M-PESA amount is Ksh 200.00. Access Fee charged Ksh 2.00.')),
        isNull,
      );
      expect(MpesaParser.parse(sms('Get 1GB for Ksh50 today! Dial *544#')), isNull);
    });
  });

  group('FinancialSenders', () {
    test('matches M-Pesa and banks, rejects people', () {
      expect(FinancialSenders.isFinancial('MPESA'), isTrue);
      expect(FinancialSenders.isFinancial('M-PESA'), isTrue);
      expect(FinancialSenders.isFinancial('Equity Bank'), isTrue);
      expect(FinancialSenders.isFinancial('KCB'), isTrue);
      expect(FinancialSenders.isFinancial('+254712345678'), isFalse);
      expect(FinancialSenders.isFinancial('Mum'), isFalse);
    });
  });

  group('KeywordCategorizer', () {
    TxCategory? cat(String m, [TxChannel ch = TxChannel.till]) =>
        KeywordCategorizer.categorize(merchant: m, channel: ch, direction: TxDirection.out);

    test('places well-known Kenyan merchants', () {
      expect(cat('Naivas Westlands'), TxCategory.groceries);
      expect(cat('KPLC Prepaid', TxChannel.paybill), TxCategory.utilities);
      expect(cat('Shell Service Station'), TxCategory.transport);
      expect(cat('Netflix'), TxCategory.entertainment);
      expect(cat('Java House'), TxCategory.food);
    });

    test('leaves unknown recipients for the AI', () {
      expect(cat('John Kamau', TxChannel.send), isNull);
    });
  });

  group('transactionFingerprint', () {
    test('is stable for the same M-Pesa reference', () {
      final a = MpesaParser.parse(sms('TK12ABC3DF Confirmed. Ksh450.00 sent to MAMA MBOGA on 21/11/26 at 10:45 AM.'))!;
      final b = MpesaParser.parse(sms('TK12ABC3DF Confirmed. Ksh450.00 sent to MAMA MBOGA on 21/11/26 at 10:45 AM.'))!;
      expect(transactionFingerprint(a), transactionFingerprint(b));
      expect(transactionFingerprint(a).length, 40);
    });
  });

  test('merchantKey strips phone numbers and punctuation', () {
    expect(Transaction.merchantKey('JOHN KAMAU 0712345678'), 'john kamau');
    expect(Transaction.merchantKey('Mama-Mboga!'), 'mama mboga');
  });
}
