import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oobli/core/errors/app_failure.dart';
import 'package:oobli/data/models/category.dart';
import 'package:oobli/data/models/transaction.dart';
import 'package:oobli/state/auth_controller.dart';
import 'package:oobli/state/transactions_controller.dart';

import 'support/fakes.dart';

Transaction tx(String id, String merchant, {bool confirmed = false, TxDirection dir = TxDirection.out}) => Transaction(
      id: id,
      fingerprint: id,
      amount: 250,
      direction: dir,
      merchant: merchant,
      category: TxCategory.transfer,
      channel: TxChannel.send,
      source: TxSource.mpesa,
      occurredAt: DateTime(2026, 11, 20),
      aiCategorized: true,
      confirmed: confirmed,
    );

void main() {
  late FakeTxRepo txRepo;
  late FakeRuleRepo ruleRepo;
  late ProviderContainer container;

  Future<void> setUpWith(List<Transaction> items) async {
    txRepo = FakeTxRepo();
    ruleRepo = FakeRuleRepo();
    container = ProviderContainer(overrides: [
      ...await overrides(transactions: items, txRepo: txRepo, ruleRepo: ruleRepo),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    await container.read(transactionsProvider.future);
    await container.read(merchantRulesProvider.future);
  }

  Map<String, Transaction> current() => {for (final t in container.read(transactionsProvider).value!) t.id: t};

  test('files one transaction instantly and saves it in the background', () async {
    await setUpWith([tx('a', 'Pius Kinuthia'), tx('b', 'Pius Kinuthia')]);
    final notifier = container.read(transactionsProvider.notifier);

    final pending = notifier.quickCategorize(current()['a']!, TxCategory.transport);
    // Visible before the write finishes.
    expect(current()['a']!.category, TxCategory.transport);
    expect(current()['a']!.confirmed, isTrue);
    expect(container.read(unsortedCountProvider), 1);

    expect(await pending, 1);
    expect(txRepo.writes, {'a': TxCategory.transport});
    expect(current()['b']!.confirmed, isFalse, reason: 'remember is off');
    expect(ruleRepo.saved, isEmpty);
  });

  test('remember sorts the same merchant and learns the rule', () async {
    await setUpWith([
      tx('a', 'Pius Kinuthia'),
      tx('b', 'PIUS KINUTHIA'),
      tx('c', 'Pius Kinuthia', confirmed: true),
      tx('d', 'Pius Kinuthia', dir: TxDirection.inbound),
      tx('e', 'Naivas'),
    ]);
    final count = await container
        .read(transactionsProvider.notifier)
        .quickCategorize(current()['a']!, TxCategory.transport, remember: true);

    expect(count, 2);
    expect(txRepo.writes.keys, unorderedEquals(['a', 'b']));
    expect(current()['c']!.category, TxCategory.transfer, reason: 'already confirmed: left alone');
    expect(current()['d']!.confirmed, isFalse, reason: 'money received is not touched');
    expect(current()['e']!.confirmed, isFalse);
    expect(ruleRepo.saved, {'Pius Kinuthia': TxCategory.transport});
  });

  test('rolls back when the save fails', () async {
    await setUpWith([tx('a', 'Pius Kinuthia'), tx('b', 'Pius Kinuthia')]);
    txRepo.fail = true;
    final notifier = container.read(transactionsProvider.notifier);

    await expectLater(
      notifier.quickCategorize(current()['a']!, TxCategory.transport, remember: true),
      throwsA(isA<AppFailure>()),
    );
    expect(current()['a']!.category, TxCategory.transfer);
    expect(current()['a']!.confirmed, isFalse);
    expect(current()['b']!.confirmed, isFalse);
    expect(ruleRepo.saved, isEmpty);
  });

  test('remember on money received learns bank withdrawals only for money in', () async {
    await setUpWith([
      tx('a', 'Equity Bank', dir: TxDirection.inbound),
      tx('b', 'Equity Bank', dir: TxDirection.inbound),
      tx('c', 'Equity Bank'),
    ]);
    final count = await container
        .read(transactionsProvider.notifier)
        .quickCategorize(current()['a']!, TxCategory.bankWithdrawal, remember: true);
    expect(count, 2);
    expect(current()['b']!.category, TxCategory.bankWithdrawal);
    expect(current()['c']!.confirmed, isFalse, reason: 'paying the bank is not touched');
    expect(ruleRepo.saved, {'Equity Bank': TxCategory.bankWithdrawal});
  });

  test('remember on money received does not learn shared categories', () async {
    await setUpWith([tx('a', 'John', dir: TxDirection.inbound), tx('b', 'John', dir: TxDirection.inbound)]);
    final count = await container
        .read(transactionsProvider.notifier)
        .quickCategorize(current()['a']!, TxCategory.transfer, remember: true);
    expect(count, 1);
    expect(ruleRepo.saved, isEmpty, reason: "a 'transfer' rule would also relabel paying John");
  });
}
