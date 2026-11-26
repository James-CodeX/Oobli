import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_failure.dart';
import '../data/local/local_cache.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';
import '../data/repositories/merchant_rule_repository.dart';
import '../data/repositories/transaction_repository.dart';
import 'auth_controller.dart';

// ---------- Connection status ----------

/// Whether Oobli can reach its servers, and when the data on screen was last
/// brought up to date with them.
@immutable
class NetStatus {
  const NetStatus({this.offline = false, this.lastSynced});

  final bool offline;
  final DateTime? lastSynced;
}

final netStatusProvider = NotifierProvider<NetStatusController, NetStatus>(NetStatusController.new);

class NetStatusController extends Notifier<NetStatus> {
  @override
  NetStatus build() {
    ref.watch(currentUserIdProvider);
    return const NetStatus();
  }

  /// Data was just pulled from the server.
  void synced([DateTime? at]) => state = NetStatus(lastSynced: at ?? DateTime.now());

  /// A request went through (but nothing was pulled).
  void reachable() {
    if (state.offline) state = NetStatus(lastSynced: state.lastSynced);
  }

  void offline() {
    if (!state.offline) state = NetStatus(offline: true, lastSynced: state.lastSynced);
  }

  /// The saved copy on screen was synced at [at] (from the offline cache).
  void restore(DateTime? at) {
    if (state.lastSynced == null && at != null) state = NetStatus(offline: state.offline, lastSynced: at);
  }
}

// ---------- Outbox ----------

/// Changes made on this phone that the server hasn't confirmed yet. Edits
/// apply on screen at once; the outbox uploads them in the background, keeps
/// them across restarts and retries when the connection comes back.
///
/// Changes to the same transaction are merged, so sorting something twice
/// offline uploads once. The state is the number of waiting changes.
final outboxProvider = NotifierProvider<Outbox, int>(Outbox.new);

class Outbox extends Notifier<int> {
  static const _concurrency = 6;
  static const debounce = Duration(milliseconds: 400);

  /// Keyed `tx:<id>` or `rule:<merchant key>`.
  final _ops = <String, Map<String, dynamic>>{};
  String? _userId;
  Future<void>? _loading;
  Future<void>? _flushing;
  Timer? _timer;

  /// Told about transactions whose change the server refused for good (for
  /// example, deleted on another phone), so the screen can be corrected.
  void Function(List<String> txIds)? onRejected;

  LocalCache get _cache => ref.read(localCacheProvider);

  @override
  int build() {
    _userId = ref.watch(currentUserIdProvider);
    _ops.clear();
    _timer?.cancel();
    ref.onDispose(() => _timer?.cancel());
    final uid = _userId;
    _loading = uid == null ? null : _load(uid);
    return 0;
  }

  Future<void> _load(String uid) async {
    final saved = await _cache.read(_name(uid));
    if (!ref.mounted || _userId != uid || saved == null) return;
    for (final raw in (saved['ops'] as List? ?? const [])) {
      final op = Map<String, dynamic>.from(raw as Map);
      final key = _keyOf(op);
      final newer = _ops[key];
      // Anything queued since launch is newer than what was saved.
      _ops[key] = newer == null ? op : _merge(op, newer);
    }
    state = _ops.length;
    if (_ops.isNotEmpty) _schedule();
  }

  static String _name(String uid) => 'outbox_$uid';

  static String _keyOf(Map<String, dynamic> op) =>
      op['k'] == 'rule' ? 'rule:${Transaction.merchantKey(op['m'] as String)}' : 'tx:${op['id']}';

  static Map<String, dynamic> _merge(Map<String, dynamic> older, Map<String, dynamic> newer) => older['k'] == 'tx'
      ? {
          ...newer,
          'd': {...(older['d'] as Map), ...(newer['d'] as Map)},
        }
      : newer;

  /// Changes waiting for each transaction, to lay over data pulled from the
  /// server until they are uploaded.
  Map<String, Map<String, dynamic>> get pendingPatches => {
        for (final op in _ops.values)
          if (op['k'] == 'tx') op['id'] as String: Map<String, dynamic>.from(op['d'] as Map),
      };

  /// Rules saved on this phone that haven't uploaded yet, by merchant key.
  Map<String, TxCategory> get pendingRules => {
        for (final op in _ops.values)
          if (op['k'] == 'rule') Transaction.merchantKey(op['m'] as String): TxCategory.fromKey(op['c'] as String?),
      };

  /// Queues row fields for transaction [txId].
  void patchTx(String txId, Map<String, dynamic> data) {
    _put({'k': 'tx', 'id': txId, 'd': data});
  }

  void patchMany(Map<String, Map<String, dynamic>> patches) {
    for (final e in patches.entries) {
      _put({'k': 'tx', 'id': e.key, 'd': e.value}, notify: false);
    }
    _changed();
  }

  /// Queues "always file [merchant] under [category]".
  void saveRule(String merchant, TxCategory category) {
    if (Transaction.merchantKey(merchant).isEmpty) return;
    _put({'k': 'rule', 'm': merchant, 'c': category.key});
  }

  void _put(Map<String, dynamic> op, {bool notify = true}) {
    if (_userId == null) return;
    final key = _keyOf(op);
    final existing = _ops[key];
    _ops[key] = existing == null ? op : _merge(existing, op);
    if (notify) _changed();
  }

  void _changed() {
    state = _ops.length;
    _persist();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(flush()));
  }

  void _persist() {
    final uid = _userId;
    if (uid == null) return;
    unawaited(_cache.write(_name(uid), {'ops': _ops.values.toList()}).catchError((Object e) {
      debugPrint('Could not save pending changes: $e');
    }));
  }

  /// Uploads everything waiting. Returns true when the outbox is empty
  /// afterwards; false when the connection failed (changes are kept).
  Future<bool> flush() async {
    while (_flushing != null) {
      await _flushing;
    }
    final run = _flush();
    _flushing = run;
    try {
      await run;
    } finally {
      _flushing = null;
    }
    return _ops.isEmpty;
  }

  Future<void> _flush() async {
    await _loading;
    final uid = _userId;
    if (uid == null || _ops.isEmpty || !ref.mounted) return;
    final txRepo = ref.read(transactionRepositoryProvider);
    final ruleRepo = ref.read(merchantRuleRepositoryProvider);
    final batch = Map.of(_ops);
    final rejected = <String>[];
    var failedRetryably = false;
    var sent = 0;

    final entries = batch.entries.toList();
    for (var i = 0; i < entries.length && !failedRetryably; i += _concurrency) {
      await Future.wait(entries.skip(i).take(_concurrency).map((entry) async {
        final op = entry.value;
        try {
          if (op['k'] == 'rule') {
            await ruleRepo.save(uid, op['m'] as String, TxCategory.fromKey(op['c'] as String?));
          } else {
            await txRepo.patch(op['id'] as String, Map<String, dynamic>.from(op['d'] as Map));
          }
          sent++;
          // Only drop it if nothing newer was queued while it was uploading.
          if (identical(_ops[entry.key], op)) _ops.remove(entry.key);
        } catch (e) {
          if (AppFailure.isRetryable(e)) {
            failedRetryably = true;
          } else {
            debugPrint('Server refused a queued change (${entry.key}): $e');
            if (identical(_ops[entry.key], op)) _ops.remove(entry.key);
            if (op['k'] == 'tx') rejected.add(op['id'] as String);
          }
        }
      }));
    }

    if (!ref.mounted) return;
    state = _ops.length;
    _persist();
    final status = ref.read(netStatusProvider.notifier);
    if (failedRetryably) {
      status.offline();
    } else if (sent > 0) {
      status.reachable();
    }
    if (rejected.isNotEmpty) onRejected?.call(rejected);
  }

  /// Forgets everything (sign-out).
  Future<void> clear() async {
    _ops.clear();
    _timer?.cancel();
    final uid = _userId;
    if (uid != null) await _cache.remove(_name(uid));
    if (ref.mounted) state = 0;
  }
}
