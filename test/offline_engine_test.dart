import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oobli/core/errors/app_failure.dart';
import 'package:oobli/data/local/local_cache.dart';
import 'package:oobli/data/models/category.dart';
import 'package:oobli/data/models/transaction.dart';
import 'package:oobli/data/repositories/merchant_rule_repository.dart';
import 'package:oobli/data/repositories/transaction_repository.dart';
import 'package:oobli/data/services/ai_service.dart';
import 'package:oobli/state/auth_controller.dart';
import 'package:oobli/state/preferences.dart';
import 'package:oobli/state/sync_engine.dart';
import 'package:oobli/state/transactions_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

/// A pretend Appwrite table with server-side `$updatedAt` times.
class FakeServer implements TransactionRepository {
  final rows = <String, Transaction>{};
  final updated = <String, DateTime>{};
  var clock = DateTime.utc(2026, 11, 26, 8);
  bool offline = false;
  int fullPulls = 0;
  final deltaSince = <DateTime>[];

  void put(Transaction t) {
    clock = clock.add(const Duration(seconds: 1));
    rows[t.id] = t;
    updated[t.id] = clock;
  }

  void _check() {
    if (offline) throw const AppFailure(AppFailure.offline);
  }

  DateTime? _latest(Iterable<String> ids) =>
      ids.map((id) => updated[id]!).fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);

  @override
  Future<TxPull> fetchSince(String userId, DateTime since) async {
    _check();
    fullPulls++;
    return TxPull([for (final t in rows.values) if (!t.deleted) t], _latest(rows.keys));
  }

  @override
  Future<TxPull> fetchChanged(String userId, DateTime after) async {
    _check();
    deltaSince.add(after);
    final ids = [for (final e in updated.entries) if (e.value.isAfter(after)) e.key];
    return TxPull([for (final id in ids) rows[id]!], _latest(ids));
  }

  @override
  Future<void> patch(String txId, Map<String, dynamic> data) async {
    _check();
    put(rows[txId]!.applyPatch(data));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// AI double that answers from a table and counts how many items it saw.
class ScriptedAi implements AiService {
  ScriptedAi(this.answers);
  final Map<String, AiCategory> answers; // by merchant
  int asked = 0;

  @override
  Future<Map<String, AiCategory>> categorize(List<Map<String, dynamic>> items,
      {Map<String, TxCategory> rules = const {}}) async {
    asked += items.length;
    return {
      for (final i in items)
        i['id'] as String: ?answers[i['merchant']],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final now = DateTime.now();

Transaction tx(String id, String merchant,
        {double amount = 300, TxCategory category = TxCategory.transfer, bool confirmed = false, int daysAgo = 0}) =>
    Transaction(
      id: id,
      fingerprint: 'fp-$id',
      amount: amount,
      direction: TxDirection.out,
      merchant: merchant,
      category: category,
      channel: TxChannel.send,
      source: TxSource.mpesa,
      occurredAt: now.subtract(Duration(days: daysAgo, minutes: 5)),
      confirmed: confirmed,
    );

void main() {
  late FakeServer server;
  late LocalCache cache;
  late SharedPreferences prefs;

  setUp(() async {
    server = FakeServer();
    cache = MemoryCache(); // shared across "app launches" below
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<ProviderContainer> launch({AiService? ai}) async {
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      localCacheProvider.overrideWithValue(cache),
      authControllerProvider.overrideWith(FakeAuth.new),
      transactionRepositoryProvider.overrideWithValue(server),
      merchantRuleRepositoryProvider.overrideWithValue(FakeRuleRepo()),
      merchantRulesProvider.overrideWith(FakeRules.new),
      aiServiceProvider.overrideWithValue(ai ?? ScriptedAi(const {})),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    await container.read(transactionsProvider.future);
    return container;
  }

  Future<void> idle() => Future<void>.delayed(const Duration(milliseconds: 700));

  List<String> ids(ProviderContainer c) => [for (final t in c.read(transactionsProvider).value!) t.id];

  test('opens offline with the last synced numbers', () async {
    server.put(tx('a', 'Naivas', amount: 4250));
    server.put(tx('b', 'John'));
    final first = await launch();
    await idle(); // saved to the phone
    expect(ids(first), unorderedEquals(['a', 'b']));
    first.dispose();

    server.offline = true;
    final second = await launch();
    expect(ids(second), unorderedEquals(['a', 'b']), reason: 'shown from the phone, no network needed');
    await idle();
    expect(second.read(netStatusProvider).offline, isTrue);
    expect(second.read(netStatusProvider).lastSynced, isNotNull, reason: 'the banner can say "from 12:40"');
  });

  test('after the first load only changes are downloaded, including deletions', () async {
    server.put(tx('a', 'Naivas'));
    server.put(tx('b', 'John'));
    final c = await launch();
    await idle();
    expect(server.fullPulls, 1);

    server.put(tx('c', 'Shell'));
    server.put(server.rows['b']!.applyPatch({'deleted': true})); // deleted on another phone
    server.put(server.rows['a']!.applyPatch({'category': 'groceries', 'confirmed': true}));

    expect(await c.read(transactionsProvider.notifier).refresh(), isTrue);
    expect(server.fullPulls, 1, reason: 'no second full download');
    expect(ids(c), unorderedEquals(['a', 'c']));
    expect(c.read(transactionsProvider).value!.firstWhere((t) => t.id == 'a').category, TxCategory.groceries);
  });

  test('changes made offline stay on screen through a pull and upload on reconnect', () async {
    server.put(tx('a', 'John'));
    final c = await launch();
    await idle();

    server.offline = true;
    await c.read(transactionsProvider.notifier).quickCategorize(
          c.read(transactionsProvider).value!.single,
          TxCategory.rent,
        );
    await idle();
    expect(c.read(outboxProvider), 1);
    expect(c.read(netStatusProvider).offline, isTrue);

    server.offline = false;
    expect(await c.read(transactionsProvider.notifier).refresh(), isTrue);
    expect(c.read(outboxProvider), 0);
    expect(server.rows['a']!.category, TxCategory.rent);
    expect(server.rows['a']!.confirmed, isTrue);
    expect(c.read(transactionsProvider).value!.single.category, TxCategory.rent);
  });

  test('queued changes survive an app restart', () async {
    server.put(tx('a', 'John'));
    final first = await launch();
    await idle();
    server.offline = true;
    await first.read(transactionsProvider.notifier).quickCategorize(
          first.read(transactionsProvider).value!.single,
          TxCategory.rent,
        );
    await idle();
    first.dispose();

    server.offline = false;
    final second = await launch();
    expect(second.read(transactionsProvider).value!.single.category, TxCategory.rent);
    await idle();
    await second.read(outboxProvider.notifier).flush();
    expect(server.rows['a']!.category, TxCategory.rent);
  });

  group('auto-sort', () {
    test('files the obvious, asks about the big and the unclear, and asks the AI once', () async {
      // Ten everyday spends so KES 2,000 is the "big" line.
      for (var i = 0; i < 10; i++) {
        server.put(tx('h$i', 'Kiosk $i', amount: 200, confirmed: true, daysAgo: i + 1));
      }
      server.put(tx('naivas', 'Naivas Westlands', amount: 900)); // known merchant
      server.put(tx('lunch', 'Mama Oliech', amount: 450)); // AI is sure
      server.put(tx('john', 'John Kamau', amount: 600)); // AI unsure
      server.put(tx('rent', 'Peter Otieno', amount: 25000)); // big: AI may not decide
      final ai = ScriptedAi({
        'Mama Oliech': const AiCategory(category: TxCategory.food, merchant: '', confidence: 0.95),
        'John Kamau': const AiCategory(category: TxCategory.transfer, merchant: '', confidence: 0.55),
        'Peter Otieno': const AiCategory(category: TxCategory.rent, merchant: '', confidence: 0.97),
      });
      final c = await launch(ai: ai);
      await idle();
      await c.read(transactionsProvider.notifier).autoSort();

      Transaction get(String id) => c.read(transactionsProvider).value!.firstWhere((t) => t.id == id);
      expect(get('naivas').category, TxCategory.groceries);
      expect(get('naivas').confirmed, isTrue, reason: 'well-known merchant, no AI needed');
      expect(get('lunch').category, TxCategory.food);
      expect(get('lunch').confirmed, isTrue, reason: 'confident AI on an everyday amount');
      expect(get('john').confirmed, isFalse, reason: 'unsure: the user decides');
      expect(get('rent').category, TxCategory.rent, reason: "Oobli's guess is shown");
      expect(get('rent').confirmed, isFalse, reason: 'big spends are always the user\'s call');
      expect(ai.asked, 3, reason: 'Naivas was settled on the phone');

      await c.read(transactionsProvider.notifier).autoSort();
      expect(ai.asked, 3, reason: 'each transaction goes to the AI only once');
      expect(c.read(unsortedCountProvider), 2);
      expect(c.read(bigOneTodayProvider)?.id, 'rent');

      await c.read(outboxProvider.notifier).flush();
      expect(server.rows['lunch']!.confirmed, isTrue, reason: 'uploaded');
    });
  });
}
