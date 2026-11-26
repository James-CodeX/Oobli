import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../../core/network/retry.dart';
import '../appwrite/appwrite_providers.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import 'ids.dart';

final merchantRuleRepositoryProvider =
    Provider<MerchantRuleRepository>((ref) => MerchantRuleRepository(ref.watch(tablesDbProvider)));

/// Category corrections the user has made, keyed by normalised merchant.
/// These always win over keyword and AI categorisation.
class MerchantRuleRepository {
  MerchantRuleRepository(this._db);

  final TablesDB _db;

  Future<Map<String, TxCategory>> fetchAll(String userId) async {
    try {
      final page = await withNetworkRetry(() => _db.listRows(
        databaseId: AppConfig.databaseId,
        tableId: AppConfig.merchantRulesTable,
        total: false,
        queries: [Query.equal('userId', userId), Query.limit(1000)],
      ));
      return {
        for (final r in page.rows)
          r.data['merchantKey'] as String: TxCategory.fromKey(r.data['category'] as String?),
      };
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> save(String userId, String merchant, TxCategory category) async {
    final key = Transaction.merchantKey(merchant);
    if (key.isEmpty) return;
    try {
      await withDeadline(() => _db.upsertRow(
        databaseId: AppConfig.databaseId,
        tableId: AppConfig.merchantRulesTable,
        rowId: deterministicId('r', [userId, key]),
        data: {'userId': userId, 'merchantKey': key, 'category': category.key},
        permissions: ownerPermissions(userId),
      ));
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> delete(String userId, String merchantKey) async {
    try {
      await withDeadline(() => _db.deleteRow(
        databaseId: AppConfig.databaseId,
        tableId: AppConfig.merchantRulesTable,
        rowId: deterministicId('r', [userId, merchantKey]),
      ));
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}
