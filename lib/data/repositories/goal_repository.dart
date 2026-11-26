import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../../core/network/retry.dart';
import '../appwrite/appwrite_providers.dart';
import '../models/goal.dart';

final goalRepositoryProvider =
    Provider<GoalRepository>((ref) => GoalRepository(ref.watch(tablesDbProvider)));

class GoalRepository {
  GoalRepository(this._db);

  final TablesDB _db;

  Future<List<Goal>> fetchAll(String userId) async {
    try {
      final page = await withNetworkRetry(() => _db.listRows(
        databaseId: AppConfig.databaseId,
        tableId: AppConfig.goalsTable,
        total: false,
        queries: [Query.equal('userId', userId), Query.orderAsc('\$createdAt'), Query.limit(100)],
      ));
      return page.rows.map((r) => Goal.fromRow(r.$id, r.$createdAt, r.data)).toList();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<Goal> create(String userId, Goal goal) async {
    try {
      final row = await withDeadline(() => _db.createRow(
        databaseId: AppConfig.databaseId,
        tableId: AppConfig.goalsTable,
        rowId: ID.unique(),
        data: goal.toRow(userId),
        permissions: ownerPermissions(userId),
      ));
      return Goal.fromRow(row.$id, row.$createdAt, row.data);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<Goal> update(String userId, Goal goal) async {
    try {
      final row = await withDeadline(() => _db.updateRow(
        databaseId: AppConfig.databaseId,
        tableId: AppConfig.goalsTable,
        rowId: goal.id,
        data: goal.toRow(userId),
      ));
      return Goal.fromRow(row.$id, row.$createdAt, row.data);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> delete(String goalId) async {
    try {
      await withDeadline(() => _db.deleteRow(
        databaseId: AppConfig.databaseId,
        tableId: AppConfig.goalsTable,
        rowId: goalId,
      ));
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}
