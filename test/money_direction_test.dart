import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oobli/data/models/category.dart';
import 'package:oobli/data/models/transaction.dart';
import 'package:oobli/data/services/ai_service.dart';
import 'package:oobli/data/services/keyword_categorizer.dart';
import 'package:oobli/data/services/sms_parser.dart';
import 'package:oobli/data/services/transaction_categorizer.dart';
import 'package:oobli/domain/duplicates.dart';
import 'package:oobli/domain/money_moves.dart';
import 'package:oobli/state/auth_controller.dart';
import 'package:oobli/state/sync_engine.dart';
import 'package:oobli/state/transactions_controller.dart';

import 'support/fakes.dart';

// Real KCB and KCB M-PESA messages, with names, accounts and codes changed.
const loanOffer = 'Dear JANE, your KCB Salary advance limit has been reviewed. You can now borrow up to KES 70,700.00.';
const fromMpesa = 'Ksh 13000.00 received in a/c JANE WANJIRU MWANGI 123***4567 on 27/11/2026 11:15 AM. '
    'M-PESA Ref UKRAB12CDE. To reverse, forward this SMS to 16120';
const repayRequest = 'MBNXY1ABCD2EFGH3 Completed. Your MOBI LOAN REPAYMENT request of KES 25,125.00 at '
    '2026-11-27 03:22:38 PM has been received successfully.';
const repayReceived = 'Dear JANE, your payment of KES 25125.0 for KCB Mobile Loan 1162000000000001 has been received. '
    'The loan is now fully paid. PIN yako, SIRI yako.';
const maintenance = 'Dear Customer, to enable scheduled system maintenance, KCB MPESA services will be unavailable '
    'tomorrow 21st Nov 2026 from 3:00 AM to 4:00 AM. We apologize for any inconvenience.';
const toKcbMpesa = 'Confirmed. KES 2,000.00 transferred to KCB M-PESA account. Your KCB M-PESA account balance is KES 2,000.03.';
const fromKcbMpesa = 'Confirmed. You have transferred KES 2,000.00 from your M-PESA savings Account to M-PESA. '
    'Your M-PESA savings Account balance is KES 0.03.';
// The M-Pesa side of the 13,000 top-up (same reference as [fromMpesa]).
const mpesaToKcb = 'UKRAB12CDE Confirmed. Ksh13,000.00 sent to KCB for account 1234567 on 27/11/26 at 11:15 AM '
    'New M-PESA balance is Ksh100.00. Transaction cost, Ksh0.00.';

SmsMessage sms(String body, {String sender = 'KCB', DateTime? at}) =>
    SmsMessage(id: body.hashCode.toString(), sender: sender, body: body, receivedAt: at ?? DateTime(2026, 11, 27, 15, 22));

/// Answers every AI request with [category], and counts what it was asked.
class CountingAi implements AiService {
  CountingAi(this.category);
  final TxCategory category;
  final asked = <Map<String, dynamic>>[];

  @override
  Future<Map<String, AiCategory>> categorize(List<Map<String, dynamic>> items,
      {Map<String, TxCategory> rules = const {}}) async {
    asked.addAll(items);
    return {for (final i in items) i['id'] as String: AiCategory(category: category, merchant: '', confidence: 0.9)};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('labels say which way the money went', () {
    test('savings and loans', () {
      expect(TxCategory.savings.labelFor(inbound: false), 'Added to savings');
      expect(TxCategory.savings.labelFor(inbound: true), 'Taken from savings');
      expect(TxCategory.debt.labelFor(inbound: true), 'Loan received');
      expect(TxCategory.debt.labelFor(inbound: false), 'Loan repaid');
    });

    test('other categories keep their name', () {
      expect(TxCategory.food.labelFor(inbound: false), 'Food & Dining');
      expect(TxCategory.ownTransfer.labelFor(inbound: true), 'Own transfer');
    });
  });

  group('BankParser', () {
    test('skips offers and notices without asking the AI', () {
      expect(BankParser.isNoise(sms(loanOffer)), isTrue);
      expect(BankParser.isNoise(sms(maintenance, sender: 'KCB M-PESA')), isTrue);
      expect(BankParser.isNoise(sms(repayRequest)), isFalse);
      expect(BankParser.isNoise(sms(fromMpesa)), isFalse, reason: '"To reverse" is not a reversal');
    });

    test('money from M-Pesa into the account is a likely own transfer', () {
      final p = BankParser.parse(sms(fromMpesa))!;
      expect(p.amount, 13000);
      expect(p.direction, TxDirection.inbound);
      expect(p.category, TxCategory.ownTransfer);
      expect(p.categorySure, isFalse, reason: 'anyone can pay in; sure only once the M-Pesa send matches');
      expect(p.reference, 'UKRAB12CDE');
      expect(p.merchant, 'M-Pesa to KCB');
      expect(p.occurredAt, DateTime(2026, 11, 27, 11, 15));
    });

    test('both loan repayment messages are one repayment', () {
      final a = BankParser.parse(sms(repayRequest))!;
      final b = BankParser.parse(sms(repayReceived, at: DateTime(2026, 11, 27, 15, 23)))!;
      for (final p in [a, b]) {
        expect(p.amount, 25125);
        expect(p.direction, TxDirection.out);
        expect(p.category, TxCategory.debt);
        expect(p.merchant, 'KCB loan');
      }
      expect(a.reference, 'MBNXY1ABCD2EFGH3');
      expect(a.occurredAt, DateTime(2026, 11, 27, 15, 22));
      expect(transactionFingerprint(a), transactionFingerprint(b));
    });

    test('a loan paid out to the user is money in', () {
      final p = BankParser.parse(sms('Dear JANE, your KCB loan of KES 20,000.00 has been disbursed to your account.'))!;
      expect(p.direction, TxDirection.inbound);
      expect(p.category, TxCategory.debt);
      expect(p.amount, 20000);
    });

    test('KCB M-PESA savings move both ways', () {
      final into = BankParser.parse(sms(toKcbMpesa, sender: 'KCB M-PESA'))!;
      expect(into.direction, TxDirection.out);
      expect(into.category, TxCategory.savings);
      expect(into.merchant, 'KCB M-Pesa');
      expect(into.amount, 2000);

      final back = BankParser.parse(sms(fromKcbMpesa, sender: 'KCB M-PESA'))!;
      expect(back.direction, TxDirection.inbound);
      expect(back.category, TxCategory.savings);
      expect(back.merchant, 'KCB M-Pesa');
    });

    test('a word is never taken for a transaction code', () {
      final p = BankParser.parse(sms('Transaction Completed. Your loan repayment of KES 500.00 has been received.'))!;
      expect(p.reference, isNull);
      expect(p.category, TxCategory.debt);
    });

    test('unknown wording is left for the AI', () {
      expect(BankParser.parse(sms('Your account 123***4567 has been debited with KES 1,500.00 at ACME LTD.')), isNull);
    });
  });

  group('savings or loan, from the message', () {
    test('M-Shwari loan wording is a loan, not savings', () {
      final repay = MpesaParser.parse(sms(
        'TK12ABC3DJ Confirmed. Ksh1,050.00 transferred to M-Shwari account on 21/11/26 at 9:00 AM. '
        'Your M-Shwari loan has been fully repaid.',
        sender: 'MPESA',
      ))!;
      expect(repay.category, TxCategory.debt);
      final save = MpesaParser.parse(sms(
        'TK12ABC3DK Confirmed. Ksh500.00 transferred to M-Shwari account on 21/11/26 at 9:00 AM. '
        'M-Shwari balance is Ksh1,500.00.',
        sender: 'MPESA',
      ))!;
      expect(save.category, TxCategory.savings);
    });

    test('KCB M-Pesa needs the message to tell savings from a loan', () {
      TxCategory? cat(String? text) => KeywordCategorizer.categorize(
          merchant: 'KCB M-PESA', channel: TxChannel.received, direction: TxDirection.inbound, text: text);
      expect(cat(null), isNull);
      expect(cat('You have received Ksh3,000.00 from KCB M-PESA. Your KCB M-PESA loan is due on 1/12/26.'),
          TxCategory.debt);
      expect(KeywordCategorizer.mentionsLoan('Your KCB Salary advance limit is KES 5,000'), isTrue);
      expect(KeywordCategorizer.mentionsLoan('Your M-Shwari loan limit is Ksh 2,000'), isFalse);
    });
  });

  group('categoriser', () {
    test('a bank credit with the M-Pesa reference settles both sides, with no AI', () async {
      final ai = CountingAi(TxCategory.debt);
      final out = await TransactionCategorizer(ai).categorize([
        MpesaParser.parse(sms(mpesaToKcb, sender: 'MPESA'))!,
        BankParser.parse(sms(fromMpesa))!,
      ], rules: const {});
      expect(ai.asked, isEmpty);
      for (final t in out) {
        expect(t.category, TxCategory.ownTransfer);
        expect(t.confirmed, isTrue);
      }
    });

    test('a bank credit alone is filed as own transfer but asked about', () async {
      final out = await TransactionCategorizer(CountingAi(TxCategory.income))
          .categorize([BankParser.parse(sms(fromMpesa))!], rules: const {});
      expect(out.single.category, TxCategory.ownTransfer);
      expect(out.single.confirmed, isFalse);
    });

    test('the AI gets the message, trimmed to what matters', () async {
      final ai = CountingAi(TxCategory.transfer);
      await TransactionCategorizer(ai).categorize([MpesaParser.parse(sms(mpesaToKcb, sender: 'MPESA'))!], rules: const {});
      expect(ai.asked.single['raw'], 'UKRAB12CDE Confirmed. Ksh13,000.00 sent to KCB for account 1234567 on 27/11/26 at 11:15 AM');
    });
  });

  group('MoneyMoves.explained', () {
    Transaction tx(String id, double amount, TxDirection dir, TxCategory cat,
            {TxSource source = TxSource.mpesa, String merchant = 'KCB', String? ref, DateTime? at, bool confirmed = false}) =>
        Transaction(
          id: id,
          fingerprint: id,
          amount: amount,
          direction: dir,
          merchant: merchant,
          category: cat,
          channel: source == TxSource.bank ? TxChannel.bank : TxChannel.paybill,
          source: source,
          occurredAt: at ?? DateTime(2026, 11, 27, 11, 15),
          reference: ref,
          confirmed: confirmed,
        );

    test('matches an M-Pesa send to the bank credit saved in another sync', () {
      final send = tx('send', 13000, TxDirection.out, TxCategory.debt, ref: 'UKRAB12CDE');
      final credit = tx('credit', 13000, TxDirection.inbound, TxCategory.ownTransfer,
          source: TxSource.bank, merchant: 'M-Pesa to KCB', ref: 'UKRAB12CDE');
      final fixed = {for (final t in MoneyMoves.explained([send, credit])) t.id: t};
      expect(fixed['send']!.category, TxCategory.ownTransfer);
      expect(fixed['send']!.confirmed, isTrue);
      expect(fixed['credit']!.confirmed, isTrue);
      expect(MoneyMoves.explained(fixed.values), isEmpty, reason: 'nothing left to fix');
    });

    test('an M-Pesa payment funding a bank loan repayment is not counted twice', () {
      final paid = tx('paid', 25125, TxDirection.out, TxCategory.debt, at: DateTime(2026, 11, 27, 15, 20));
      final repaid = tx('repaid', 25125, TxDirection.out, TxCategory.debt,
          source: TxSource.bank, merchant: 'KCB loan', at: DateTime(2026, 11, 27, 15, 22));
      final fixed = MoneyMoves.explained([paid, repaid]);
      expect(fixed.single.id, 'paid');
      expect(fixed.single.category, TxCategory.ownTransfer);
      expect(fixed.single.confirmed, isFalse, reason: 'a likely answer: the user is asked');
    });

    test('leaves what the user confirmed alone', () {
      final send = tx('send', 13000, TxDirection.out, TxCategory.debt, ref: 'UKRAB12CDE', confirmed: true);
      final credit = tx('credit', 13000, TxDirection.inbound, TxCategory.ownTransfer,
          source: TxSource.bank, ref: 'UKRAB12CDE', confirmed: true);
      expect(MoneyMoves.explained([send, credit]), isEmpty);
    });
  });

  group('one payment, several messages', () {
    final at = DateTime(2026, 11, 27, 15, 22);
    Transaction row(String id, String merchant, double amount,
            {TxSource source = TxSource.bank,
            TxDirection dir = TxDirection.out,
            TxCategory cat = TxCategory.debt,
            String? ref,
            bool ai = false,
            Duration after = Duration.zero,
            String? note}) =>
        Transaction(
          id: id,
          fingerprint: id,
          amount: amount,
          direction: dir,
          merchant: merchant,
          category: cat,
          channel: source == TxSource.bank ? TxChannel.bank : TxChannel.paybill,
          source: source,
          occurredAt: at.add(after),
          reference: ref,
          aiCategorized: ai,
          confirmed: true,
          note: note,
        );

    // What the app held: two rows from the old AI reading, one from 1.6.2.
    final kcb = [
      row('old1', 'KCB Mobile Loan', 25125, ai: true),
      row('old2', 'KCB Mobi Loan', 25125, ref: 'MBNXY1ABCD2EFGH3', ai: true),
      row('new', 'KCB loan', 25125, ref: 'MBNXY1ABCD2EFGH3', after: const Duration(seconds: 38)),
    ];

    test('the three KCB repayment rows are one payment', () {
      final groups = Duplicates.find([...kcb, row('fuliza', 'Fuliza M-Pesa', 277, source: TxSource.mpesa, ref: 'UKR1')]);
      expect(groups, hasLength(1));
      expect(groups.single.keep.id, 'new', reason: 'has a code and was read on the phone');
      expect(groups.single.extra.map((t) => t.id), unorderedEquals(['old1', 'old2']));
    });

    test('real separate payments stay separate', () {
      expect(Duplicates.find([
        row('a', 'Fuliza M-Pesa', 500, source: TxSource.mpesa, ref: 'UKR1'),
        row('b', 'Fuliza M-Pesa', 500, source: TxSource.mpesa, ref: 'UKR2'),
      ]), isEmpty, reason: 'two M-Pesa codes are two payments');
      expect(Duplicates.find([row('a', 'KCB loan', 500), row('b', 'Equity loan', 500)]), isEmpty,
          reason: 'different lenders');
      expect(Duplicates.find([row('a', 'KCB loan', 500), row('b', 'KCB loan', 500, after: const Duration(minutes: 6))]),
          isEmpty, reason: 'more than 5 minutes apart');
      expect(Duplicates.find([row('a', 'KCB loan', 500), row('b', 'KCB loan', 500, dir: TxDirection.inbound)]),
          isEmpty, reason: 'one borrowed, one repaid');
      expect(Duplicates.find([
        row('a', 'Java House', 500, cat: TxCategory.food),
        row('b', 'Java House', 500, cat: TxCategory.food),
      ]), isEmpty, reason: 'only loan and savings messages are merged');
    });

    test('the same savings move told by M-Pesa and KCB M-PESA', () {
      final groups = Duplicates.find([
        row('mpesa', 'KCB M-PESA', 2000, source: TxSource.mpesa, cat: TxCategory.savings, ref: 'UKR9'),
        row('bank', 'KCB M-Pesa', 2000, cat: TxCategory.savings, after: const Duration(minutes: 1)),
      ]);
      expect(groups.single.keep.id, 'mpesa');
    });

    test('M-Pesa to KCB with no shared reference is still one own transfer', () {
      final send = row('send', 'KCB', 13000, source: TxSource.mpesa, cat: TxCategory.debt, ref: 'UKR5')
          .copyWith(confirmed: false);
      final credit = row('credit', 'M-Pesa to KCB', 13000, dir: TxDirection.inbound, cat: TxCategory.ownTransfer,
              after: const Duration(minutes: 2))
          .copyWith(confirmed: false);
      final fixed = {for (final t in MoneyMoves.explained([send, credit])) t.id: t};
      expect(fixed['send']!.category, TxCategory.ownTransfer);
      expect(fixed['send']!.confirmed, isTrue);
      expect(fixed['credit']!.confirmed, isTrue);
    });

    test('the controller removes the copies everywhere and keeps notes', () async {
      final txRepo = FakeTxRepo();
      final rows = [kcb[0].copyWith(note: 'cleared it'), kcb[1], kcb[2]];
      final container = ProviderContainer(overrides: [...await overrides(transactions: rows, txRepo: txRepo)]);
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      await container.read(transactionsProvider.future);

      expect(await container.read(transactionsProvider.notifier).removeDuplicates(), 2);
      final left = container.read(transactionsProvider).value!;
      expect(left.single.id, 'new');
      expect(left.single.note, 'cleared it');
      await container.read(outboxProvider.notifier).flush();
      expect(txRepo.patches['old1']?['deleted'], isTrue);
      expect(txRepo.patches['old2']?['deleted'], isTrue);
      expect(await container.read(transactionsProvider.notifier).removeDuplicates(), 0, reason: 'idempotent');
    });
  });
}
