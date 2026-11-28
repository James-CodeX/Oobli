import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/errors/app_failure.dart';
import '../data/local/local_cache.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';
import '../data/repositories/merchant_rule_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/services/sms_inbox_service.dart';
import '../data/services/sms_sync_service.dart';
import '../data/services/ai_service.dart';
import '../domain/bills.dart';
import '../domain/duplicates.dart';
import '../domain/money_moves.dart';
import '../domain/similar_merchants.dart';
import '../domain/sorting.dart';
import '../domain/spending_stats.dart';
import 'auth_controller.dart';
import 'preferences.dart';
import 'sync_engine.dart';

final transactionsProvider =
    AsyncNotifierProvider<TransactionsController, List<Transaction>>(TransactionsController.new);

/// Analytics over the loaded transactions (empty while loading).
final statsProvider = Provider<SpendingStats>(
  (ref) => SpendingStats(ref.watch(transactionsProvider).value ?? const []),
);

/// From what amount a spend counts as "big" for this user.
final bigAmountProvider = Provider<double>(
  (ref) => SortPolicy.bigAmount(ref.watch(transactionsProvider).value ?? const [], DateTime.now()),
);

/// Waiting in Quick sort from the last 7 days: what the home banner counts.
final unsortedCountProvider = Provider<int>(
  (ref) => SortQueue.recent(ref.watch(transactionsProvider).value ?? const [], DateTime.now()).length,
);

/// Waiting from before the last 7 days (optional in Quick sort).
final olderUnsortedCountProvider = Provider<int>(
  (ref) => SortQueue.older(ref.watch(transactionsProvider).value ?? const [], DateTime.now()).length,
);

/// Today's biggest unsorted spend, asked about right on the home screen.
final bigOneTodayProvider = Provider<Transaction?>(
  (ref) => SortQueue.bigOneToday(
    ref.watch(transactionsProvider).value ?? const [],
    DateTime.now(),
    ref.watch(bigAmountProvider),
  ),
);

/// Repeating payments due in the next two weeks, plus the last known balance.
final billForecastProvider = Provider<BillForecast>((ref) {
  final txs = ref.watch(transactionsProvider).value;
  if (txs == null || txs.isEmpty) return BillForecast.empty;
  return BillPredictor.forecast(txs, now: DateTime.now());
});

// ---------- Auto-sort status ----------

@immutable
class AutoSortStatus {
  const AutoSortStatus({this.asking = 0, this.filed = 0});

  /// Transactions currently with the AI (0 when idle).
  final int asking;

  /// How many the last run filed on its own.
  final int filed;

  bool get running => asking > 0;
}

final autoSortStatusProvider = NotifierProvider<AutoSortStatusController, AutoSortStatus>(AutoSortStatusController.new);

class AutoSortStatusController extends Notifier<AutoSortStatus> {
  @override
  AutoSortStatus build() => const AutoSortStatus();

  void asking(int count) => state = AutoSortStatus(asking: count, filed: state.filed);
  void done(int filed) => state = AutoSortStatus(filed: filed);
}

// ---------- Merchant rules ----------

final merchantRulesProvider =
    AsyncNotifierProvider<MerchantRulesController, Map<String, TxCategory>>(MerchantRulesController.new);

/// The user's "always file X as Y" rules, keyed by normalised merchant.
/// Shown from the phone's copy at once, saved through the outbox.
class MerchantRulesController extends AsyncNotifier<Map<String, TxCategory>> {
  static String _cacheName(String uid) => 'rules_$uid';

  @override
  Future<Map<String, TxCategory>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const {};
    return cacheFirst<Map<String, TxCategory>>(
      cache: ref.read(localCacheProvider),
      name: _cacheName(userId),
      fetch: () => ref.read(merchantRuleRepositoryProvider).fetchAll(userId),
      encode: _encode,
      decode: (j) => {
        for (final e in (j as Map).entries) e.key as String: TxCategory.fromKey(e.value as String?),
      },
      onFresh: (fresh) {
        if (!ref.mounted || ref.read(currentUserIdProvider) != userId) return;
        // Rules saved on this phone but not uploaded yet still count.
        state = AsyncData({...fresh, ...ref.read(outboxProvider.notifier).pendingRules});
      },
    );
  }

  static Map<String, String> _encode(Map<String, TxCategory> rules) => {
        for (final e in rules.entries) e.key: e.value.key,
      };

  void _saveCache(Map<String, TxCategory> rules) {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    unawaited(ref.read(localCacheProvider).write(_cacheName(uid), {'v': _encode(rules)}));
  }

  /// Learns a rule at once; it uploads in the background.
  Future<void> save(String merchant, TxCategory category) async {
    final key = Transaction.merchantKey(merchant);
    if (key.isEmpty || ref.read(currentUserIdProvider) == null) return;
    ref.read(outboxProvider.notifier).saveRule(merchant, category);
    final next = {...?state.value, key: category};
    state = AsyncData(next);
    _saveCache(next);
  }

  Future<void> remove(String merchantKey) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref.read(merchantRuleRepositoryProvider).delete(userId, merchantKey);
    final next = {...?state.value}..remove(merchantKey);
    state = AsyncData(next);
    _saveCache(next);
  }
}

// ---------- Transactions ----------

/// The heart of the app's data.
///
/// * **Offline first.** The last synced copy is kept on the phone and shown
///   instantly, with or without internet. Fresh data is pulled in the
///   background.
/// * **Delta sync.** After the first load only rows changed since the last
///   pull are downloaded (by server `$updatedAt`), not the whole history.
/// * **Instant edits.** Changes apply on screen at once and go through the
///   [Outbox], which batches, merges, retries and survives restarts.
/// * **Auto-sort.** What Oobli is sure of is filed for the user (on-device
///   rules first, then the AI in bulk), so Quick sort only asks about the
///   rest (see [SortPolicy]).
class TransactionsController extends AsyncNotifier<List<Transaction>> {
  TransactionRepository get _repo => ref.read(transactionRepositoryProvider);
  LocalCache get _cache => ref.read(localCacheProvider);
  Outbox get _outbox => ref.read(outboxProvider.notifier);

  /// Server time of the newest change pulled so far.
  DateTime? _pulledAt;
  Future<bool>? _refreshing;
  Future<int>? _autoSorting;
  Timer? _saveTimer;

  String get _userId {
    final id = ref.read(currentUserIdProvider);
    if (id == null) throw const AppFailure('Please log in again.', code: 401);
    return id;
  }

  static String _cacheName(String uid) => 'transactions_$uid';
  static String _reviewedName(String uid) => 'ai_reviewed_$uid';
  static DateTime get _windowStart => DateTime.now().subtract(AppConfig.historyWindow);

  @override
  Future<List<Transaction>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    _pulledAt = null;
    _refreshing = null;
    ref.onDispose(() => _saveTimer?.cancel());
    if (userId == null) return const [];
    _outbox.onRejected = _reconcile;

    final saved = await _readCache(userId);
    if (saved != null) {
      _pulledAt = saved.pulledAt;
      ref.read(netStatusProvider.notifier).restore(saved.savedAt);
      // Show the saved copy now; bring it up to date once it is on screen.
      Future(() async {
        await future;
        if (ref.mounted && ref.read(currentUserIdProvider) == userId) await refresh();
      });
      return _sorted(_withPending(saved.items));
    }

    final pull = await _repo.fetchSince(userId, _windowStart);
    _pulledAt = pull.latest;
    ref.read(netStatusProvider.notifier).synced();
    final items = _sorted(pull.items);
    Future(() async {
      await future;
      if (!ref.mounted) return;
      _saveNow();
      await autoSort();
    });
    return items;
  }

  List<Transaction> get _current => state.value ?? const [];

  static List<Transaction> _sorted(List<Transaction> txs) =>
      [...txs]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  void _set(List<Transaction> txs) {
    state = AsyncData(_sorted(txs));
    _scheduleSave();
  }

  /// Lays changes that haven't uploaded yet over rows from the server or cache.
  List<Transaction> _withPending(List<Transaction> txs) {
    final pending = ref.read(outboxProvider.notifier).pendingPatches;
    return [
      for (final t in txs)
        if (pending[t.id] case final patch?) t.applyPatch(patch) else t,
    ].where((t) => !t.deleted).toList();
  }

  // ----- On-device copy -----

  Future<({List<Transaction> items, DateTime? pulledAt, DateTime? savedAt})?> _readCache(String uid) async {
    try {
      final saved = await _cache.read(_cacheName(uid));
      if (saved == null || saved['v'] != 1) return null;
      final start = _windowStart;
      return (
        items: [
          for (final j in saved['items'] as List)
            if (Transaction.fromJson(Map<String, dynamic>.from(j as Map)) case final t
                when !t.occurredAt.isBefore(start))
              t,
        ],
        pulledAt: DateTime.tryParse(saved['pulledAt'] as String? ?? ''),
        savedAt: DateTime.tryParse(saved['syncedAt'] as String? ?? ''),
      );
    } catch (e) {
      debugPrint('Ignoring unreadable transactions cache: $e');
      return null;
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _saveNow);
  }

  void _saveNow() {
    _saveTimer?.cancel();
    final uid = ref.read(currentUserIdProvider);
    final items = state.value;
    if (uid == null || items == null) return;
    final synced = ref.read(netStatusProvider).lastSynced;
    unawaited(_cache.write(_cacheName(uid), {
      'v': 1,
      'pulledAt': _pulledAt?.toUtc().toIso8601String(),
      'syncedAt': synced?.toIso8601String(),
      'items': [for (final t in items) t.toJson()],
    }).catchError((Object e) => debugPrint('Could not save transactions offline: $e')));
  }

  // ----- Sync with the server -----

  /// Uploads waiting changes, then pulls what changed on the server. Safe to
  /// call often (one run at a time). Returns false when offline.
  Future<bool> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return false;
    try {
      await future;
    } catch (_) {
      // The first load failed (offline with nothing saved): retry it below.
    }
    if (!ref.mounted || ref.read(currentUserIdProvider) != uid) return false;
    final status = ref.read(netStatusProvider.notifier);
    try {
      final uploaded = await _outbox.flush();
      if (!uploaded) throw const AppFailure(AppFailure.offline);
      final since = _pulledAt;
      if (since == null || state.value == null) {
        final pull = await _repo.fetchSince(uid, _windowStart);
        if (!ref.mounted || ref.read(currentUserIdProvider) != uid) return false;
        _pulledAt = pull.latest;
        _set(_withPending(pull.items));
      } else {
        final pull = await _repo.fetchChanged(uid, since);
        if (!ref.mounted || ref.read(currentUserIdProvider) != uid) return false;
        if (pull.items.isNotEmpty) {
          final byId = {for (final t in _current) t.id: t};
          for (final t in pull.items) {
            if (t.deleted) {
              byId.remove(t.id);
            } else {
              byId[t.id] = t;
            }
          }
          final start = _windowStart;
          _set(_withPending(byId.values.where((t) => !t.occurredAt.isBefore(start)).toList()));
        }
        if (pull.latest != null && pull.latest!.isAfter(since)) _pulledAt = pull.latest;
      }
      status.synced();
      _saveNow();
      unawaited(autoSort());
      return true;
    } catch (e) {
      debugPrint('Refresh failed: $e');
      if (AppFailure.isRetryable(e)) status.offline();
      if (state.hasError && ref.mounted) state = AsyncError(AppFailure.from(e), StackTrace.current);
      return false;
    }
  }

  /// The server refused a queued change for good: show its real copy.
  void _reconcile(List<String> ids) {
    Future(() async {
      for (final id in ids) {
        try {
          final server = await _repo.get(id);
          if (!ref.mounted) return;
          _set([
            for (final t in _current)
              if (t.id != id) t else if (server != null && !server.deleted) server,
          ]);
        } catch (e) {
          debugPrint('Could not reload $id: $e');
        }
      }
    });
  }

  // ----- Edits (instant; uploaded by the outbox) -----

  Future<Transaction> add(Transaction tx, {bool learnRule = false}) async {
    final created = await _repo.create(_userId, tx);
    _set([created, ..._current]);
    if (learnRule && tx.isOutgoing) {
      await ref.read(merchantRulesProvider.notifier).save(tx.merchant, tx.category);
    }
    return created;
  }

  /// Saves an edited transaction. With [applyToMerchant] the category is
  /// learned and applied to every transaction from the same merchant.
  Future<void> edit(Transaction before, Transaction after, {bool applyToMerchant = false}) async {
    final userId = _userId;
    final categoryChanged = before.category != after.category;
    final updated = after.copyWith(confirmed: true, aiCategorized: before.aiCategorized && !categoryChanged);
    _outbox.patchTx(updated.id, updated.toRow(userId)..remove('userId'));
    if (categoryChanged && before.aiCategorized) {
      await ref.read(localStoreProvider).incrementAiCorrections();
    }
    _set([for (final t in _current) t.id == updated.id ? updated : t]);
    if (applyToMerchant && canLearn(after, after.category)) {
      await recategorizeMerchant(after.merchant, after.category, direction: after.direction);
    }
  }

  /// "Yes" on an AI suggestion: keep the category and remember it.
  Future<void> confirm(Transaction tx) async {
    _outbox.patchTx(tx.id, {'category': tx.category.key, 'confirmed': true});
    _set([for (final t in _current) t.id == tx.id ? t.copyWith(confirmed: true) : t]);
    await ref.read(merchantRulesProvider.notifier).save(tx.merchant, tx.category);
  }

  /// Quick sort: files [tx] under [category] and confirms it, instantly.
  ///
  /// With [remember] the rule is learned and every other unconfirmed
  /// transaction from the same merchant, in the same direction, is filed the
  /// same way. Returns how many transactions were updated.
  Future<int> quickCategorize(Transaction tx, TxCategory category, {bool remember = false}) async {
    final learn = remember && canLearn(tx, category);
    final key = Transaction.merchantKey(tx.merchant);
    final targets = {
      tx.id,
      if (learn)
        for (final t in _current)
          if (!t.confirmed && t.direction == tx.direction && Transaction.merchantKey(t.merchant) == key) t.id,
    };
    final patches = <String, Map<String, dynamic>>{};
    _set([
      for (final t in _current)
        if (targets.contains(t.id))
          () {
            final next = t.copyWith(
              category: category,
              confirmed: true,
              aiCategorized: t.aiCategorized && t.category == category,
            );
            patches[t.id] = {'category': category.key, 'confirmed': true, 'aiCategorized': next.aiCategorized};
            return next;
          }()
        else
          t,
    ]);
    _outbox.patchMany(patches);
    if (tx.aiCategorized && tx.category != category) {
      await ref.read(localStoreProvider).incrementAiCorrections();
    }
    if (learn) await ref.read(merchantRulesProvider.notifier).save(tx.merchant, category);
    return patches.length;
  }

  /// "Keep Oobli's guesses": confirms [txs] as they are. Returns the count.
  int acceptGuesses(Iterable<Transaction> txs) {
    final ids = {for (final t in txs) if (!t.confirmed) t.id};
    if (ids.isEmpty) return 0;
    _set([for (final t in _current) ids.contains(t.id) ? t.copyWith(confirmed: true) : t]);
    _outbox.patchMany({for (final id in ids) id: {'confirmed': true}});
    return ids.length;
  }

  /// Files everything Oobli is sure about, so Quick sort only asks about the
  /// rest: first with on-device knowledge (rules, message types, known
  /// merchants), then by asking the AI about the remainder in bulk. Each
  /// transaction goes to the AI once. Returns how many were filed.
  Future<int> autoSort() => _autoSorting ??= _autoSort().whenComplete(() => _autoSorting = null);

  Future<int> _autoSort() async {
    final uid = ref.read(currentUserIdProvider);
    final txs = state.value;
    if (uid == null || txs == null) return 0;
    final unsorted = [for (final t in txs) if (!t.confirmed) t];
    if (unsorted.isEmpty) return 0;

    Map<String, TxCategory> rules;
    try {
      rules = await ref.read(merchantRulesProvider.future);
    } catch (_) {
      rules = const {};
    }
    if (!ref.mounted) return 0;
    final owner = ref.read(authControllerProvider).value?.name;
    final patches = <String, Map<String, dynamic>>{};
    final rest = <Transaction>[];
    for (final t in unsorted) {
      final sure = SortPolicy.certain(t, rules: rules, ownerName: owner);
      if (sure != null && sure.fits(inbound: !t.isOutgoing)) {
        patches[t.id] = {'category': sure.key, 'confirmed': true};
      } else {
        rest.add(t);
      }
    }

    final reviewed = await _reviewed(uid);
    if (!ref.mounted) return 0;
    final ask = rest.where((t) => !reviewed.contains(t.id)).take(600).toList();
    final status = ref.read(autoSortStatusProvider.notifier);
    if (ask.isNotEmpty) {
      status.asking(ask.length);
      try {
        final big = SortPolicy.bigAmount(txs, DateTime.now());
        final answers = await ref.read(aiServiceProvider).categorize([
          for (final t in ask)
            {
              'id': t.id,
              'merchant': t.merchant,
              'channel': t.channel.key,
              'direction': t.isOutgoing ? 'out' : 'in',
              'amount': t.amount,
            },
        ], rules: rules);
        if (!ref.mounted) return 0;
        for (final t in ask) {
          final a = answers[t.id];
          if (a == null) continue;
          reviewed.add(t.id);
          if (!a.category.fits(inbound: !t.isOutgoing)) continue;
          if (SortPolicy.aiIsSure(a.category, a.confidence, big: SortPolicy.isBig(t, big))) {
            patches[t.id] = {'category': a.category.key, 'confirmed': true, 'aiCategorized': true};
          } else if (a.category != t.category) {
            patches[t.id] = {'category': a.category.key, 'aiCategorized': true};
          }
        }
        await _cache.write(_reviewedName(uid), {'ids': reviewed.toList()});
      } catch (e) {
        debugPrint('AI auto-sort unavailable: $e');
      }
    }

    if (!ref.mounted || ref.read(currentUserIdProvider) != uid) return 0;
    // The user may have sorted some of these meanwhile: their choice wins.
    final applied = <String, Map<String, dynamic>>{};
    _set([
      for (final t in _current)
        if (patches[t.id] case final p? when !t.confirmed) () {
          applied[t.id] = p;
          return t.applyPatch(p);
        }() else t,
    ]);
    if (applied.isNotEmpty) _outbox.patchMany(applied);
    final filed = applied.values.where((p) => p['confirmed'] == true).length;
    status.done(filed);
    return filed;
  }

  Future<Set<String>> _reviewed(String uid) async {
    try {
      final saved = await _cache.read(_reviewedName(uid));
      return {...?(saved?['ids'] as List?)?.cast<String>()};
    } catch (_) {
      return <String>{};
    }
  }

  /// Transactions the AI already judged (at import) don't need asking again.
  Future<void> markReviewed(Iterable<String> ids) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null || ids.isEmpty) return;
    final reviewed = await _reviewed(uid)
      ..addAll(ids);
    await _cache.write(_reviewedName(uid), {'ids': reviewed.toList()});
  }

  /// Marks out-and-back round trips (refunds, money returned) as Own transfer
  /// so they stop counting as spending and income. They stay unconfirmed and
  /// show up in Quick sort, so the user has the final say. M-Pesa payments a
  /// bank message explains are fixed too (see [MoneyMoves.explained]).
  /// Returns the count.
  Future<int> detectMoneyMoves() async {
    final explained = {for (final t in MoneyMoves.explained(_current)) t.id: t};
    final current = [for (final t in _current) explained[t.id] ?? t];
    final changed = {
      ...explained,
      for (final m in MoneyMoves.roundTrips(current))
        for (final t in m.both) t.id: t.copyWith(category: TxCategory.ownTransfer, aiCategorized: true, confirmed: false),
    };
    if (changed.isEmpty) return 0;
    _set([for (final t in _current) changed[t.id] ?? t]);
    _outbox.patchMany({
      for (final t in changed.values)
        t.id: {'category': t.category.key, 'aiCategorized': t.aiCategorized, 'confirmed': t.confirmed},
    });
    return changed.length;
  }

  /// Other merchants that probably belong in [category] too, after the user
  /// filed [tx] there: name matches instantly, plus the AI's picks when online.
  Future<List<MerchantGroup>> similarTo(Transaction tx, TxCategory category) async {
    if (!canLearn(tx, category)) return const [];
    final candidates = SimilarMerchants.candidates(_current, tx, category);
    if (candidates.isEmpty) return const [];
    final picked = {for (final g in SimilarMerchants.byName(candidates, tx)) g.key: g};
    final rest = candidates.where((g) => !picked.containsKey(g.key)).toList();
    if (rest.isNotEmpty) {
      try {
        final names = await ref
            .read(aiServiceProvider)
            .similar(merchant: tx.merchant, category: category, candidates: [for (final g in rest) g.merchant])
            .timeout(const Duration(seconds: 10));
        final wanted = names.toSet();
        for (final g in rest) {
          if (wanted.contains(g.merchant)) picked[g.key] = g;
        }
      } catch (e) {
        debugPrint('AI similar-merchant lookup unavailable: $e');
      }
    }
    return picked.values.toList()..sort((a, b) => b.count.compareTo(a.count));
  }

  /// Files every transaction of [groups] under [category] and learns a rule
  /// per merchant. Returns how many transactions changed.
  Future<int> fileMerchants(List<MerchantGroup> groups, TxCategory category, {required TxDirection direction}) async {
    var changed = 0;
    for (final g in groups) {
      changed += await recategorizeMerchant(g.merchant, category, direction: direction);
    }
    return changed;
  }

  /// Merchant rules are shared by both directions, so money received only
  /// teaches categories that can never apply to spending (Income, Bank
  /// withdrawal). Otherwise receiving from John would relabel paying John.
  static bool canLearn(Transaction tx, TxCategory category) => tx.isOutgoing || category.receivingOnly;

  /// Removes extra copies of one payment (see [Duplicates]): banks often send
  /// two messages for a loan repayment, and a later sync can read a message
  /// again. A note on a removed copy moves to the one kept. Returns how many
  /// were removed.
  Future<int> removeDuplicates() async {
    final groups = Duplicates.find(_current);
    if (groups.isEmpty) return 0;
    final extra = {for (final g in groups) for (final t in g.extra) t.id};
    final noted = <String, Transaction>{
      for (final g in groups)
        if (g.keep.note == null)
          if (g.extra.map((t) => t.note).nonNulls.firstOrNull case final note?) g.keep.id: g.keep.copyWith(note: note),
    };
    _set([for (final t in _current) if (!extra.contains(t.id)) noted[t.id] ?? t]);
    _outbox.patchMany({
      for (final id in extra) id: {'deleted': true},
      for (final t in noted.values) t.id: {'note': t.note},
    });
    return extra.length;
  }

  Future<void> delete(Transaction tx) async {
    _outbox.patchTx(tx.id, {'deleted': true});
    _set(_current.where((t) => t.id != tx.id).toList());
  }

  /// Moves every transaction from [merchant] into [category] and learns the rule.
  /// Only transactions the category fits are touched (money in stays money in).
  Future<int> recategorizeMerchant(String merchant, TxCategory category, {TxDirection? direction}) async {
    final key = Transaction.merchantKey(merchant);
    final ids = {
      for (final t in _current)
        if (Transaction.merchantKey(t.merchant) == key &&
            t.category != category &&
            (direction == null || t.direction == direction) &&
            category.fits(inbound: !t.isOutgoing))
          t.id,
    };
    _set([
      for (final t in _current)
        ids.contains(t.id) ? t.copyWith(category: category, confirmed: true) : t,
    ]);
    _outbox.patchMany({for (final id in ids) id: {'category': category.key, 'confirmed': true}});
    await ref.read(merchantRulesProvider.notifier).save(merchant, category);
    return ids.length;
  }

  void _merge(List<Transaction> added) {
    if (added.isEmpty) return;
    final existing = {for (final t in _current) t.fingerprint};
    _set([..._current, ...added.where((t) => !existing.contains(t.fingerprint))]);
  }
}

// ---------- SMS sync ----------

enum SyncPhase { idle, syncing, done, failed }

@immutable
class SyncState {
  const SyncState({this.phase = SyncPhase.idle, this.added = 0, this.merged = 0, this.message});

  final SyncPhase phase;
  final int added;

  /// Extra copies of a payment this sync removed (several messages, one payment).
  final int merged;
  final String? message;

  bool get isSyncing => phase == SyncPhase.syncing;
}

final smsSyncControllerProvider = NotifierProvider<SmsSyncController, SyncState>(SmsSyncController.new);

class SmsSyncController extends Notifier<SyncState> {
  @override
  SyncState build() {
    ref.watch(currentUserIdProvider);
    return const SyncState();
  }

  /// Imports new M-Pesa/bank SMS. Safe to call repeatedly; returns new count.
  Future<int> sync({bool silent = false}) async {
    if (state.isSyncing) return 0;
    final profile = ref.read(authControllerProvider).value;
    if (profile == null) return 0;
    final inbox = ref.read(smsInboxServiceProvider);
    if (!await inbox.hasPermission()) {
      if (!silent) {
        state = const SyncState(phase: SyncPhase.failed, message: 'SMS access is turned off.');
      }
      return 0;
    }

    state = const SyncState(phase: SyncPhase.syncing);
    try {
      // Re-read a day of overlap; duplicates are dropped by fingerprint.
      final since = profile.lastSmsSyncAt?.subtract(const Duration(days: 1)) ??
          DateTime.now().subtract(AppConfig.initialSmsLookback);
      final rules = await ref.read(merchantRulesProvider.future);
      final result = await ref.read(smsSyncServiceProvider).sync(
            userId: profile.id,
            since: since,
            rules: rules,
            ownerName: profile.name,
            bigAmount: ref.read(bigAmountProvider),
          );
      final transactions = ref.read(transactionsProvider.notifier);
      transactions._merge(result.added);
      if (result.added.isNotEmpty) {
        await transactions.markReviewed([for (final t in result.added) if (t.aiCategorized) t.id]);
        await transactions.detectMoneyMoves();
      }
      // Run even when nothing is new: older copies get cleaned up too.
      final merged = await transactions.removeDuplicates();
      final kept = {for (final t in transactions._current) t.id};
      final added = result.added.where((t) => kept.contains(t.id)).length;
      if (added > 0) unawaited(transactions.autoSort());
      await ref.read(authControllerProvider.notifier).updateProfile(
            (p) => p.copyWith(smsSyncEnabled: true, lastSmsSyncAt: DateTime.now()),
          );
      state = SyncState(phase: SyncPhase.done, added: added, merged: merged);
      return added;
    } catch (e) {
      final failure = AppFailure.from(e);
      state = SyncState(phase: SyncPhase.failed, message: failure.message);
      if (!silent) rethrow;
      return 0;
    }
  }
}
