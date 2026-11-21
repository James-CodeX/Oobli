import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../../core/network/retry.dart';
import '../appwrite/appwrite_providers.dart';
import '../models/plan.dart';
import 'ids.dart';

final planRepositoryProvider =
    Provider<PlanRepository>((ref) => PlanRepository(ref.watch(tablesDbProvider)));

/// One plan per user per month (row id derived from user + month).
class PlanRepository {
  PlanRepository(this._db);

  final TablesDB _db;

  static String idFor(String userId, String month) => deterministicId('p', [userId, month]);

  Future<Plan?> fetch(String userId, String month) async {
    try {
      final row = await withNetworkRetry(() => _db.getRow(
        databaseId: AppConfig.databaseId,
        tableId: AppConfig.plansTable,
        rowId: idFor(userId, month),
      ));
      return Plan.fromRow(row.$id, row.data);
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      throw AppFailure.from(e);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<Plan> save(String userId, Plan plan) async {
    try {
      final row = await _db.upsertRow(
        databaseId: AppConfig.databaseId,
        tableId: AppConfig.plansTable,
        rowId: idFor(userId, plan.month),
        data: plan.toRow(userId),
        permissions: ownerPermissions(userId),
      );
      return Plan.fromRow(row.$id, row.data);
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}
