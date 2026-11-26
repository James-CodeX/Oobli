import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../../core/network/retry.dart';
import '../appwrite/appwrite_providers.dart';
import '../models/category.dart';
import '../models/transaction.dart';

final transactionRepositoryProvider =
    Provider<TransactionRepository>((ref) => TransactionRepository(ref.watch(tablesDbProvider)));

/// Rows from one pull, plus the newest server `$updatedAt` among them: the
/// cursor for the next delta pull (server time, so phone clocks don't matter).
@immutable
class TxPull {
  const TxPull(this.items, this.latest);

  final List<Transaction> items;
  final DateTime? latest;
}

class TransactionRepository {
  TransactionRepository(this._db);

  final TablesDB _db;

  static const _pageSize = 100;
  static const _maxRows = 20000;
  static const _writeConcurrency = 6;

  /// Every live transaction since [since] (first load on a device).
  Future<TxPull> fetchSince(String userId, DateTime since) async {
    final pull = await _pages(userId, [
      Query.greaterThanEqual('occurredAt', since.toUtc().toIso8601String()),
      Query.orderDesc('occurredAt'),
    ]);
    return TxPull(pull.items.where((t) => !t.deleted).toList(), pull.latest);
  }

  /// Rows created, edited or deleted after [after] (server time). Deleted
  /// rows are included so the caller can drop them.
  Future<TxPull> fetchChanged(String userId, DateTime after) => _pages(userId, [
        Query.greaterThan('\$updatedAt', after.toUtc().toIso8601String()),
        Query.orderAsc('\$updatedAt'),
      ]);

  Future<TxPull> _pages(String userId, List<String> queries) async {
    final out = <Transaction>[];
    DateTime? latest;
    String? cursor;
    try {
      while (out.length < _maxRows) {
        final page = await withNetworkRetry(() => _db.listRows(
              databaseId: AppConfig.databaseId,
              tableId: AppConfig.transactionsTable,
              total: false,
              queries: [
                Query.equal('userId', userId),
                ...queries,
                Query.limit(_pageSize),
                if (cursor != null) Query.cursorAfter(cursor),
              ],
            ));
        for (final r in page.rows) {
          out.add(Transaction.fromRow(r.$id, r.data));
          final updated = _updatedAt(r);
          if (updated != null && (latest == null || updated.isAfter(latest))) latest = updated;
        }
        if (page.rows.length < _pageSize) break;
        cursor = page.rows.last.$id;
      }
      return TxPull(out, latest);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  static DateTime? _updatedAt(models.Row r) => DateTime.tryParse(r.$updatedAt);

  Future<Transaction> create(String userId, Transaction tx) async {
    try {
      final row = await withDeadline(() => _db.createRow(
            databaseId: AppConfig.databaseId,
            tableId: AppConfig.transactionsTable,
            rowId: ID.unique(),
            data: tx.toRow(userId),
            permissions: ownerPermissions(userId),
          ));
      return Transaction.fromRow(row.$id, row.data);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Inserts many rows with bounded concurrency. Rows that already exist
  /// (same fingerprint, enforced by a unique index) are skipped silently.
  Future<List<Transaction>> createMany(String userId, List<Transaction> txs) async {
    final created = <Transaction>[];
    for (var i = 0; i < txs.length; i += _writeConcurrency) {
      final chunk = txs.skip(i).take(_writeConcurrency);
      final results = await Future.wait(chunk.map((tx) async {
        try {
          return await create(userId, tx);
        } on AppFailure catch (f) {
          if (f.isConflict) return null;
          rethrow;
        }
      }));
      created.addAll(results.whereType<Transaction>());
    }
    return created;
  }

  Future<Transaction> update(String userId, Transaction tx) async {
    try {
      final row = await withDeadline(() => _db.updateRow(
            databaseId: AppConfig.databaseId,
            tableId: AppConfig.transactionsTable,
            rowId: tx.id,
            data: tx.toRow(userId),
          ));
      return Transaction.fromRow(row.$id, row.data);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Writes only the given row fields (what the offline queue sends).
  Future<void> patch(String txId, Map<String, dynamic> data) async {
    try {
      await withDeadline(() => _db.updateRow(
            databaseId: AppConfig.databaseId,
            tableId: AppConfig.transactionsTable,
            rowId: txId,
            data: data,
          ));
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> updateCategory(String txId, TxCategory category, {required bool confirmed}) =>
      patch(txId, {'category': category.key, 'confirmed': confirmed});

  /// The server's copy of one row, or null when it no longer exists.
  Future<Transaction?> get(String txId) async {
    try {
      final row = await withNetworkRetry(() => _db.getRow(
            databaseId: AppConfig.databaseId,
            tableId: AppConfig.transactionsTable,
            rowId: txId,
          ));
      return Transaction.fromRow(row.$id, row.data);
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      throw AppFailure.from(e);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Soft delete: the row stays as a tombstone so every device's next delta
  /// sync removes it too.
  Future<void> delete(String txId) => patch(txId, {'deleted': true});
}
