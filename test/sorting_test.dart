import 'package:flutter_test/flutter_test.dart';
import 'package:oobli/data/models/category.dart';
import 'package:oobli/data/models/transaction.dart';
import 'package:oobli/data/services/ai_service.dart';
import 'package:oobli/data/services/sms_parser.dart';
import 'package:oobli/data/services/transaction_categorizer.dart';
import 'package:oobli/domain/sorting.dart';

final now = DateTime(2026, 11, 26, 14);

Transaction tx(
  String merchant,
  double amount, {
  int daysAgo = 0,
  bool confirmed = false,
  TxChannel channel = TxChannel.send,
  TxDirection dir = TxDirection.out,
  TxCategory category = TxCategory.transfer,
  String? ref,
}) =>
    Transaction(
      id: '$merchant-$amount-$daysAgo',
      fingerprint: '$merchant-$amount-$daysAgo',
      amount: amount,
      direction: dir,
      merchant: merchant,
      category: category,
      channel: channel,
      source: TxSource.mpesa,
      occurredAt: now.subtract(Duration(days: daysAgo, hours: 1)),
      confirmed: confirmed,
      reference: ref,
    );

class AnswerAll implements AiService {
  AnswerAll(this.category, this.confidence);
  final TxCategory category;
  final double confidence;

  @override
  Future<Map<String, AiCategory>> categorize(List<Map<String, dynamic>> items,
          {Map<String, TxCategory> rules = const {}}) async =>
      {for (final i in items) i['id'] as String: AiCategory(category: category, merchant: '', confidence: confidence)};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ParsedTransaction parsed(String merchant, double amount,
        {TxChannel channel = TxChannel.till, TxDirection dir = TxDirection.out, TxCategory? category}) =>
    ParsedTransaction(
      amount: amount,
      direction: dir,
      merchant: merchant,
      channel: channel,
      source: TxSource.mpesa,
      occurredAt: now,
      raw: 'sms',
      category: category,
    );

void main() {
  group('Quick sort queue', () {
    final txs = [
      tx('Today', 300),
      tx('Six days ago', 300, daysAgo: 6),
      tx('Eight days ago', 300, daysAgo: 8),
      tx('Sorted', 300, confirmed: true),
    ];

    test('shows the last 7 days, newest first; older ones separately', () {
      expect(SortQueue.recent(txs, now).map((t) => t.merchant), ['Today', 'Six days ago']);
      expect(SortQueue.older(txs, now).map((t) => t.merchant), ['Eight days ago']);
    });

    test('"big" follows the user\'s own spending, never below KES 2,000', () {
      expect(SortPolicy.bigAmount(txs, now), 2000, reason: 'too little history');
      final busy = [for (var i = 0; i < 20; i++) tx('Shop $i', 1000.0 + i * 500, daysAgo: i)];
      expect(SortPolicy.bigAmount(busy, now), 9500);
    });

    test("today's biggest unsorted spend is the one asked about", () {
      final day = [
        tx('Rent', 25000),
        tx('Bigger but sorted', 40000, confirmed: true),
        tx('Yesterday', 30000, daysAgo: 1),
        tx('Small', 500),
      ];
      expect(SortQueue.bigOneToday(day, now, 2000)?.merchant, 'Rent');
      expect(SortQueue.bigOneToday([tx('Small', 500)], now, 2000), isNull);
    });

    test('search finds names, M-Pesa codes, amounts and phrases, sorted or not', () {
      final all = [
        tx('Naivas Westlands', 4250, ref: 'RL82XJ91', category: TxCategory.groceries, confirmed: true),
        tx('Uber', 650, daysAgo: 3, category: TxCategory.transport, channel: TxChannel.till),
        tx('John Kamau', 1200, daysAgo: 10),
      ];
      expect(SortQueue.search(all, 'naivas', now).single.merchant, 'Naivas Westlands');
      expect(SortQueue.search(all, 'rl82xj91', now).single.merchant, 'Naivas Westlands');
      expect(SortQueue.search(all, '1,200', now).single.merchant, 'John Kamau');
      expect(SortQueue.search(all, 'transport this week', now).single.merchant, 'Uber');
      expect(SortQueue.search(all, 'zzz', now), isEmpty);
    });
  });

  group('what Oobli files on its own', () {
    test('certain from the phone alone', () {
      expect(SortPolicy.certain(tx('Naivas Westlands', 900, channel: TxChannel.till), rules: const {}),
          TxCategory.groceries);
      expect(SortPolicy.certain(tx('Safaricom', 100, channel: TxChannel.airtime), rules: const {}), TxCategory.airtime);
      expect(SortPolicy.certain(tx('Peter Otieno', 5000), rules: {'peter otieno': TxCategory.rent}), TxCategory.rent);
      expect(SortPolicy.certain(tx('Jared Waweru', 5000), rules: const {}, ownerName: 'Jared Waweru'),
          TxCategory.ownTransfer);
      expect(SortPolicy.certain(tx('John Kamau', 600), rules: const {}), isNull, reason: 'a person: ask');
    });

    test('AI guesses: only confident, everyday, and not "Other"', () {
      expect(SortPolicy.aiIsSure(TxCategory.food, 0.9, big: false), isTrue);
      expect(SortPolicy.aiIsSure(TxCategory.food, 0.7, big: false), isFalse);
      expect(SortPolicy.aiIsSure(TxCategory.rent, 0.99, big: true), isFalse);
      expect(SortPolicy.aiIsSure(TxCategory.other, 0.99, big: false), isFalse);
    });

    test('at import: known merchants filed, unclear and big ones left for the user', () async {
      final sure = TransactionCategorizer(AnswerAll(TxCategory.food, 0.95));
      final out = await sure.categorize([
        parsed('Naivas', 900),
        parsed('Mama Oliech', 450),
        parsed('Mama Oliech', 9000),
        parsed('Jane Wanjiku 0712345678', 3000,
            channel: TxChannel.received, dir: TxDirection.inbound, category: TxCategory.income),
      ], rules: const {}, bigAmount: 2000);
      expect(out[0].confirmed, isTrue, reason: 'known merchant');
      expect(out[1].confirmed, isTrue, reason: 'confident AI, everyday amount');
      expect(out[2].confirmed, isFalse, reason: 'big: the user decides');
      expect(out[3].confirmed, isFalse, reason: 'money from a person could be anything');

      final unsure = TransactionCategorizer(AnswerAll(TxCategory.food, 0.5));
      expect((await unsure.categorize([parsed('Mama Oliech', 450)], rules: const {})).single.confirmed, isFalse);
    });
  });
}
