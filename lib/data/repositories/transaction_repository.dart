import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../appwrite/appwrite_providers.dart';
import '../models/category.dart';
import '../models/transaction.dart';

final transactionRepositoryProvider =
    Provider<TransactionRepository>((ref) => TransactionRepository(ref.watch(tablesDbProvider)));

class TransactionRepository {
  TransactionRepository(this._db);

  final TablesDB _db;

  static const _pageSize = 100;
  static const _maxRows = 5000;
  static const _writeConcurrency = 6;

  Future<List<Transaction>> fetchSince(String userId, DateTime since) async {
    final out = <Transaction>[];
    String? cursor;
    try {
      while (out.length < _maxRows) {
        final page = await _db.listRows(
          databaseId: AppConfig.databaseId,
          tableId: AppConfig.transactionsTable,
          total: false,
          queries: [
            Query.equal('userId', userId),
            Query.greaterThanEqual('occurredAt', since.toUtc().toIso8601String()),
            Query.orderDesc('occurredAt'),
            Query.limit(_pageSize),
            if (cursor != null) Query.cursorAfter(cursor),
          ],
        );
        out.addAll(page.rows.map((r) => Transaction.fromRow(r.$id, r.data)));
        if (page.rows.length < _pageSize) break;
        cursor = page.rows.last.$id;
      }
      return out;
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<Transaction> create(String userId, Transaction tx) async {
    try {
      final row = await _db.createRow(
        databaseId: AppConfig.databaseId,
        tableId: AppConfig.transactionsTable,
        rowId: ID.unique(),
        data: tx.toRow(userId),
        permissions: ownerPermissions(userId),
      );
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
      final row = await _db.updateRow(
        databaseId: AppConfig.databaseId,
        tableId: AppConfig.transactionsTable,
        rowId: tx.id,
        data: tx.toRow(userId),
      );
      return Transaction.fromRow(row.$id, row.data);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> updateCategory(String txId, TxCategory category, {required bool confirmed}) async {
    try {
      await _db.updateRow(
        databaseId: AppConfig.databaseId,
        tableId: AppConfig.transactionsTable,
        rowId: txId,
        data: {'category': category.key, 'confirmed': confirmed},
      );
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> delete(String txId) async {
    try {
      await _db.deleteRow(
        databaseId: AppConfig.databaseId,
        tableId: AppConfig.transactionsTable,
        rowId: txId,
      );
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}
