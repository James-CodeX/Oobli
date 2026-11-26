import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oobli/data/models/category.dart';
import 'package:oobli/data/models/transaction.dart';
import 'package:oobli/data/services/ai_service.dart';
import 'package:oobli/data/services/sms_parser.dart';
import 'package:oobli/data/services/transaction_categorizer.dart';
import 'package:oobli/domain/bills.dart';
import 'package:oobli/domain/money_moves.dart';
import 'package:oobli/domain/natural_search.dart';
import 'package:oobli/domain/similar_merchants.dart';
import 'package:oobli/state/auth_controller.dart';
import 'package:oobli/state/sync_engine.dart';
import 'package:oobli/state/transactions_controller.dart';

import 'support/fakes.dart';

var _n = 0;
Transaction tx(
  String merchant,
  double amount,
  DateTime at, {
  TxCategory category = TxCategory.other,
  TxDirection dir = TxDirection.out,
  bool confirmed = false,
  TxChannel channel = TxChannel.send,
  double? balance,
}) =>
    Transaction(
      id: 'x${_n++}',
      fingerprint: 'f$_n',
      amount: amount,
      direction: dir,
      merchant: merchant,
      category: category,
      channel: channel,
      source: TxSource.mpesa,
      occurredAt: at,
      confirmed: confirmed,
      aiCategorized: true,
      balance: balance,
    );

/// AI double: [similarNames] are returned as matches for any request.
class FakeAi implements AiService {
  FakeAi({this.similarNames = const []});
  final List<String> similarNames;
  List<String>? lastCandidates;

  @override
  Future<List<String>> similar({required String merchant, required TxCategory category, required List<String> candidates}) async {
    lastCandidates = candidates;
    return similarNames.where(candidates.contains).toList();
  }

  @override
  Future<Map<String, AiCategory>> categorize(List<Map<String, dynamic>> items, {Map<String, TxCategory> rules = const {}}) async => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime(2026, 11, 22, 12);

  group('own money moves', () {
    test('recognises sending money to yourself', () {
      expect(MoneyMoves.isOwner('JARED WAWERU 0712345678', 'Jared Waweru'), isTrue);
      expect(MoneyMoves.isOwner('Jared Kamau', 'Jared Waweru'), isFalse, reason: 'one shared name is not enough');
      expect(MoneyMoves.isOwner('Jared Waweru', 'Jared'), isFalse);
      expect(MoneyMoves.isOwner('Jared Waweru', null), isFalse);
    });

    test('pairs money that went out and came back', () {
      final out = tx('John Kamau', 2000, now);
      final back = tx('JOHN KAMAU', 2000, now.add(const Duration(hours: 30)), dir: TxDirection.inbound);
      final unrelated = tx('John Kamau', 500, now.add(const Duration(hours: 1)), dir: TxDirection.inbound);
      final moves = MoneyMoves.roundTrips([unrelated, back, out]);
      expect(moves, hasLength(1));
      expect(moves.single.both.map((t) => t.id), [out.id, back.id]);
    });

    test('leaves confirmed, late, savings and different-person pairs alone', () {
      List<MoneyMove> trips(List<Transaction> txs) => MoneyMoves.roundTrips(txs);
      expect(trips([tx('A B', 900, now, confirmed: true), tx('A B', 900, now, dir: TxDirection.inbound)]), isEmpty);
      expect(trips([tx('A B', 900, now), tx('A B', 900, now.add(const Duration(days: 4)), dir: TxDirection.inbound)]), isEmpty);
      expect(trips([
        tx('M-Shwari', 900, now, category: TxCategory.savings),
        tx('M-Shwari', 900, now, category: TxCategory.savings, dir: TxDirection.inbound),
      ]), isEmpty);
      expect(trips([tx('A B', 900, now), tx('C D', 900, now, dir: TxDirection.inbound)]), isEmpty);
    });

    test('cash deposits at an agent are own transfers, not income', () {
      final p = MpesaParser.parse(SmsMessage(
        id: '1',
        sender: 'MPESA',
        body: 'TK12ABC3DK Confirmed. On 21/11/26 at 9:00 AM Give Ksh2,000.00 cash to JANE AGENCIES - Kasarani New M-PESA balance is Ksh5,000.00.',
        receivedAt: now,
      ));
      expect(p?.category, TxCategory.ownTransfer);
      expect(tx('x', 1, now, category: TxCategory.ownTransfer).isSpend, isFalse);
    });

    test('the categoriser files payments to yourself as own transfers', () async {
      final categorizer = TransactionCategorizer(FakeAi());
      final out = await categorizer.categorize([
        ParsedTransaction(
          amount: 1000,
          direction: TxDirection.out,
          merchant: 'Jared Waweru',
          channel: TxChannel.send,
          source: TxSource.mpesa,
          occurredAt: now,
          raw: 'Ksh1,000.00 sent to JARED WAWERU 0712345678',
        ),
      ], rules: const {}, ownerName: 'Jared Waweru');
      expect(out.single.category, TxCategory.ownTransfer);
    });
  });

  group('bill prediction', () {
    DateTime d(int y, int m, int day) => DateTime(y, m, day, 9);

    test('finds monthly bills and predicts the next payment', () {
      final bills = BillPredictor.detect([
        tx('Netflix', 1100, d(2026, 9, 25), category: TxCategory.entertainment),
        tx('Netflix', 1100, d(2026, 10, 25), category: TxCategory.entertainment),
        tx('Netflix', 1100, d(2026, 11, 25).subtract(const Duration(days: 31)), category: TxCategory.entertainment),
        tx('Landlord Kamau', 18000, d(2026, 10, 1), category: TxCategory.rent),
        tx('Landlord Kamau', 18000, d(2026, 11, 1), category: TxCategory.rent),
      ], now: now);
      final rent = bills.firstWhere((b) => b.merchant == 'Landlord Kamau');
      expect(rent.cadence, BillCadence.monthly);
      expect(rent.nextDue, d(2026, 12, 1));
      expect(rent.amount, 18000);
      expect(bills.any((b) => b.merchant == 'Netflix'), isTrue);
    });

    test('weekly chama contributions count, weekly groceries do not', () {
      final bills = BillPredictor.detect([
        for (var w = 0; w < 4; w++) ...[
          tx('Umoja Chama', 500, now.subtract(Duration(days: 3 + 7 * w)), category: TxCategory.savings),
          tx('Naivas', 3000, now.subtract(Duration(days: 2 + 7 * w)), category: TxCategory.groceries),
        ],
      ], now: now);
      expect(bills.map((b) => b.merchant), ['Umoja Chama']);
      expect(bills.single.cadence, BillCadence.weekly);
      expect(bills.single.daysUntil(now), 4);
    });

    test('drops bills that stopped and amounts that jump around', () {
      final bills = BillPredictor.detect([
        tx('Showmax', 900, d(2026, 6, 10), category: TxCategory.entertainment),
        tx('Showmax', 900, d(2026, 7, 10), category: TxCategory.entertainment),
        tx('KPLC', 500, d(2026, 9, 5), category: TxCategory.utilities),
        tx('KPLC', 4000, d(2026, 10, 5), category: TxCategory.utilities),
      ], now: now);
      expect(bills, isEmpty);
    });

    test('warns when the balance will not cover this week', () {
      final f = BillPredictor.forecast([
        tx('Landlord', 18000, d(2026, 10, 25), category: TxCategory.rent),
        tx('Landlord', 18000, d(2026, 9, 25), category: TxCategory.rent, balance: 50000),
        tx('Naivas', 300, now.subtract(const Duration(hours: 2)), category: TxCategory.groceries, balance: 4000),
      ], now: now);
      expect(f.upcoming.single.merchant, 'Landlord');
      expect(f.balance, 4000);
      expect(f.shortfall(), 14000);
    });
  });

  group('similar merchants', () {
    test('matches on meaningful shared words only', () {
      final source = tx('Naivas Westlands', 400, now, category: TxCategory.other);
      final all = [
        source,
        tx('Naivas Kilimani', 900, now),
        tx('Naivas Kilimani', 300, now),
        tx('Westgate Pharmacy', 300, now),
        tx('Kenya Power Ltd', 300, now),
        tx('Naivas Thika Road', 200, now, confirmed: true),
        tx('Naivas Mombasa', 200, now, category: TxCategory.groceries),
      ];
      final candidates = SimilarMerchants.candidates(all, source, TxCategory.groceries);
      expect(candidates.map((g) => g.merchant), isNot(contains('Naivas Thika Road')), reason: 'confirmed by the user');
      expect(candidates.map((g) => g.merchant), isNot(contains('Naivas Mombasa')), reason: 'already groceries');
      final byName = SimilarMerchants.byName(candidates, source);
      expect(byName.map((g) => g.merchant), ['Naivas Kilimani']);
      expect(byName.single.count, 2);
    });

    test('combines name matches with the AI and files them in one go', () async {
      final ai = FakeAi(similarNames: ['Embassava Sacco']);
      final source = tx('Super Metro Sacco', 100, now, category: TxCategory.transport, confirmed: true);
      final items = [
        source,
        tx('City Hoppa Sacco', 80, now),
        tx('Embassava', 70, now),
        tx('Embassava Sacco', 70, now),
        tx('Naivas', 900, now),
      ];
      final txRepo = FakeTxRepo();
      final container = ProviderContainer(overrides: [
        ...await overrides(transactions: items, txRepo: txRepo, ai: ai),
      ]);
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      await container.read(transactionsProvider.future);
      await container.read(merchantRulesProvider.future);
      final notifier = container.read(transactionsProvider.notifier);

      final groups = await notifier.similarTo(source, TxCategory.transport);
      expect(groups.map((g) => g.merchant).toSet(), {'City Hoppa Sacco', 'Embassava Sacco'});
      expect(ai.lastCandidates, isNot(contains('City Hoppa Sacco')), reason: 'name matches are not sent to the AI');

      final changed = await notifier.fileMerchants(groups, TxCategory.transport, direction: TxDirection.out);
      expect(changed, 2);
      final byMerchant = {for (final t in container.read(transactionsProvider).value!) t.merchant: t};
      expect(byMerchant['Embassava Sacco']!.category, TxCategory.transport);
      expect(byMerchant['Embassava']!.category, TxCategory.other);
    });
  });

  group('money moves in the controller', () {
    test('marks round trips for review and saves them', () async {
      final txRepo = FakeTxRepo();
      final items = [
        tx('John Kamau', 2000, now),
        tx('John Kamau', 2000, now.add(const Duration(hours: 5)), dir: TxDirection.inbound),
      ];
      final container = ProviderContainer(overrides: [...await overrides(transactions: items, txRepo: txRepo)]);
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      await container.read(transactionsProvider.future);

      expect(await container.read(transactionsProvider.notifier).detectMoneyMoves(), 2);
      final txs = container.read(transactionsProvider).value!;
      expect(txs.every((t) => t.category == TxCategory.ownTransfer && t.needsReview), isTrue);
      await container.read(outboxProvider.notifier).flush();
      expect(txRepo.writes.values.toSet(), {TxCategory.ownTransfer});
      expect(await container.read(transactionsProvider.notifier).detectMoneyMoves(), 0, reason: 'idempotent');
    });
  });

  group('plain-English search', () {
    test('boda last month', () {
      final f = NaturalSearch.parse('How much did I spend on boda last month?', now: now)!;
      expect(f.categories, {TxCategory.transport});
      expect(f.from, DateTime(2026, 10));
      expect(f.to, DateTime(2026, 11));
      expect(f.direction, TxDirection.out);
      expect(f.label, 'Transport · October');
      expect(f.matches(tx('Pius', 250, DateTime(2026, 10, 9), category: TxCategory.transport)), isTrue);
      expect(f.matches(tx('Pius', 250, DateTime(2026, 11, 2), category: TxCategory.transport)), isFalse);
    });

    test('merchant, year and amount', () {
      final f = NaturalSearch.parse('netflix this year over 1k', now: now)!;
      expect(f.terms, ['netflix']);
      expect(f.minAmount, 1000);
      expect(f.from, DateTime(2026));
      expect(f.matches(tx('Netflix.com', 1100, DateTime(2026, 3, 1))), isTrue);
      expect(f.matches(tx('Netflix.com', 900, DateTime(2026, 3, 1))), isFalse);
    });

    test('money received and month names', () {
      final f = NaturalSearch.parse('salary in october', now: now)!;
      expect(f.direction, TxDirection.inbound);
      expect(f.categories, {TxCategory.income});
      expect(f.from, DateTime(2026, 10));
      final dec = NaturalSearch.parse('rent december', now: now)!;
      expect(dec.from, DateTime(2025, 12), reason: 'the most recent December');
    });

    test('a plain word stays a plain search', () {
      expect(NaturalSearch.parse('naivas', now: now), isNull);
      expect(NaturalSearch.parse('RKP11X02', now: now), isNull);
    });
  });
}
