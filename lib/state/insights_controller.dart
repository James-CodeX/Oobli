import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/formatters.dart';
import '../data/models/ai_models.dart';
import '../data/models/transaction.dart';
import '../data/services/ai_service.dart';
import '../domain/local_insights.dart';
import '../domain/spending_stats.dart';
import 'auth_controller.dart';
import 'goals_controller.dart';
import 'plan_controller.dart';
import 'preferences.dart';
import 'transactions_controller.dart';

final insightsProvider = AsyncNotifierProvider<InsightsController, AiInsights>(InsightsController.new);

/// Always-available insights: AI when ready, local rules while loading or offline.
final currentInsightsProvider = Provider<AiInsights>((ref) {
  final ai = ref.watch(insightsProvider).value;
  if (ai != null) return ai;
  return LocalInsights.build(ref.watch(statsProvider), primaryGoal: ref.watch(primaryGoalProvider));
});

class InsightsController extends AsyncNotifier<AiInsights> {
  static const _cacheName = 'insights';

  @override
  Future<AiInsights> build() async {
    final txs = await ref.watch(transactionsProvider.future);
    final profile = ref.watch(authControllerProvider).value;
    final goal = ref.watch(primaryGoalProvider);
    final plan = ref.watch(planProvider).value;
    final stats = SpendingStats(txs);
    final local = LocalInsights.build(stats, primaryGoal: goal);
    if (txs.isEmpty || profile == null || !profile.insightsEnabled) return local;

    final store = ref.read(localStoreProvider);
    final key = _cacheKey(txs, goal?.saved, plan?.status.name);
    final cached = store.readCache(_cacheName, key);
    if (cached != null) return _filtered(AiInsights.fromJson(cached));

    try {
      final ai = await ref.read(aiServiceProvider).insights(
            stats.aiSummary(primaryGoal: goal, plan: plan, firstName: profile.firstName),
          );
      final merged = AiInsights(
        headline: ai.headline.isEmpty ? local.headline : ai.headline,
        cards: ai.cards.isEmpty ? local.cards : ai.cards,
        activityNote: ai.activityNote.isEmpty ? local.activityNote : ai.activityNote,
        analyticsNote: ai.analyticsNote.isEmpty ? local.analyticsNote : ai.analyticsNote,
        goalNote: ai.goalNote.isEmpty ? local.goalNote : ai.goalNote,
        suggestion: ai.suggestion,
      );
      await store.writeCache(_cacheName, key, merged.toJson());
      return _filtered(merged);
    } catch (e) {
      debugPrint('AI insights unavailable, using local insights: $e');
      return local;
    }
  }

  /// Insights are regenerated once per day, or when transactions/goals change.
  String _cacheKey(List<Transaction> txs, double? goalSaved, String? planStatus) =>
      [Fmt.monthKey(DateTime.now()), DateTime.now().day, txs.length,
          txs.isEmpty ? '' : txs.first.id, goalSaved, planStatus].join('|');

  AiInsights _filtered(AiInsights insights) {
    final s = insights.suggestion;
    if (s == null) return insights;
    final dismissed = ref.read(localStoreProvider).dismissedSuggestions;
    return dismissed.contains(Transaction.merchantKey(s.merchant)) ? insights.withoutSuggestion() : insights;
  }

  Future<void> dismissSuggestion() async {
    final current = state.value;
    final s = current?.suggestion;
    if (current == null || s == null) return;
    await ref.read(localStoreProvider).dismissSuggestion(Transaction.merchantKey(s.merchant));
    state = AsyncData(current.withoutSuggestion());
  }

  Future<void> refresh() async {
    await ref.read(localStoreProvider).clearCache(_cacheName);
    ref.invalidateSelf();
  }
}
