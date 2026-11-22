import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/errors/app_failure.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';
import '../data/repositories/merchant_rule_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/services/sms_inbox_service.dart';
import '../data/services/sms_sync_service.dart';
import '../domain/spending_stats.dart';
import 'auth_controller.dart';
import 'preferences.dart';

final transactionsProvider =
    AsyncNotifierProvider<TransactionsController, List<Transaction>>(TransactionsController.new);

/// Analytics over the loaded transactions (empty while loading).
final statsProvider = Provider<SpendingStats>(
  (ref) => SpendingStats(ref.watch(transactionsProvider).value ?? const []),
);

/// Transactions nobody has confirmed yet: the Quick sort queue.
final unsortedCountProvider = Provider<int>(
  (ref) => (ref.watch(transactionsProvider).value ?? const []).where((t) => !t.confirmed).length,
);

final merchantRulesProvider =
    AsyncNotifierProvider<MerchantRulesController, Map<String, TxCategory>>(MerchantRulesController.new);

class MerchantRulesController extends AsyncNotifier<Map<String, TxCategory>> {
  @override
  Future<Map<String, TxCategory>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const {};
    return ref.read(merchantRuleRepositoryProvider).fetchAll(userId);
  }

  Future<void> save(String merchant, TxCategory category) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref.read(merchantRuleRepositoryProvider).save(userId, merchant, category);
    state = AsyncData({...?state.value, Transaction.merchantKey(merchant): category});
  }

  Future<void> remove(String merchantKey) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref.read(merchantRuleRepositoryProvider).delete(userId, merchantKey);
    state = AsyncData({...?state.value}..remove(merchantKey));
  }
}

class TransactionsController extends AsyncNotifier<List<Transaction>> {
  TransactionRepository get _repo => ref.read(transactionRepositoryProvider);

  String get _userId {
    final id = ref.read(currentUserIdProvider);
    if (id == null) throw const AppFailure('Please log in again.', code: 401);
    return id;
  }

  @override
  Future<List<Transaction>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];
    return _repo.fetchSince(userId, DateTime.now().subtract(AppConfig.historyWindow));
  }

  List<Transaction> get _current => state.value ?? const [];

  void _set(List<Transaction> txs) {
    state = AsyncData([...txs]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)));
  }

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
    final categoryChanged = before.category != after.category;
    final updated = await _repo.update(
      _userId,
      after.copyWith(confirmed: true, aiCategorized: before.aiCategorized && !categoryChanged),
    );
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
    await _repo.updateCategory(tx.id, tx.category, confirmed: true);
    _set([for (final t in _current) t.id == tx.id ? t.copyWith(confirmed: true) : t]);
    await ref.read(merchantRulesProvider.notifier).save(tx.merchant, tx.category);
  }

  /// Quick sort: files [tx] under [category] and confirms it. The change is
  /// shown at once and written in the background; if the write fails the
  /// change is rolled back and the error rethrown.
  ///
  /// With [remember] the rule is learned and every other unconfirmed
  /// transaction from the same merchant, in the same direction, is filed the
  /// same way. Returns how many transactions were updated.
  Future<int> quickCategorize(Transaction tx, TxCategory category, {bool remember = false}) async {
    final learn = remember && canLearn(tx, category);
    final key = Transaction.merchantKey(tx.merchant);
    final targets = [
      tx,
      if (learn)
        ..._current.where((t) =>
            t.id != tx.id &&
            !t.confirmed &&
            t.direction == tx.direction &&
            Transaction.merchantKey(t.merchant) == key),
    ];
    final before = {for (final t in targets) t.id: t};
    _set([
      for (final t in _current)
        before.containsKey(t.id)
            ? t.copyWith(
                category: category,
                confirmed: true,
                aiCategorized: t.aiCategorized && t.category == category,
              )
            : t,
    ]);
    try {
      for (var i = 0; i < targets.length; i += 6) {
        await Future.wait(targets
            .skip(i)
            .take(6)
            .map((t) => _repo.updateCategory(t.id, category, confirmed: true)));
      }
      if (tx.aiCategorized && tx.category != category) {
        await ref.read(localStoreProvider).incrementAiCorrections();
      }
      if (learn) await ref.read(merchantRulesProvider.notifier).save(tx.merchant, category);
      return targets.length;
    } catch (e) {
      // Restore only what this call changed; later picks stay as they are.
      _set([for (final t in _current) before[t.id] ?? t]);
      throw AppFailure.from(e);
    }
  }

  /// Merchant rules are shared by both directions, so money received only
  /// teaches categories that can never apply to spending (Income, Bank
  /// withdrawal). Otherwise receiving from John would relabel paying John.
  static bool canLearn(Transaction tx, TxCategory category) => tx.isOutgoing || category.receivingOnly;

  Future<void> delete(Transaction tx) async {
    await _repo.delete(tx.id);
    _set(_current.where((t) => t.id != tx.id).toList());
  }

  /// Moves every transaction from [merchant] into [category] and learns the rule.
  /// Only transactions the category fits are touched (money in stays money in).
  Future<int> recategorizeMerchant(String merchant, TxCategory category, {TxDirection? direction}) async {
    final key = Transaction.merchantKey(merchant);
    final targets = _current
        .where((t) =>
            Transaction.merchantKey(t.merchant) == key &&
            t.category != category &&
            (direction == null || t.direction == direction) &&
            category.fits(inbound: !t.isOutgoing))
        .toList();
    for (var i = 0; i < targets.length; i += 6) {
      await Future.wait(targets
          .skip(i)
          .take(6)
          .map((t) => _repo.updateCategory(t.id, category, confirmed: true)));
    }
    final ids = targets.map((t) => t.id).toSet();
    _set([
      for (final t in _current)
        ids.contains(t.id) ? t.copyWith(category: category, confirmed: true) : t,
    ]);
    await ref.read(merchantRulesProvider.notifier).save(merchant, category);
    return targets.length;
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
  const SyncState({this.phase = SyncPhase.idle, this.added = 0, this.message});

  final SyncPhase phase;
  final int added;
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
          );
      ref.read(transactionsProvider.notifier)._merge(result.added);
      await ref.read(authControllerProvider.notifier).updateProfile(
            (p) => p.copyWith(smsSyncEnabled: true, lastSmsSyncAt: DateTime.now()),
          );
      state = SyncState(phase: SyncPhase.done, added: result.added.length);
      return result.added.length;
    } catch (e) {
      final failure = AppFailure.from(e);
      state = SyncState(phase: SyncPhase.failed, message: failure.message);
      if (!silent) rethrow;
      return 0;
    }
  }
}
