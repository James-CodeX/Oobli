import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/formatters.dart';
import '../data/models/ai_models.dart';
import '../data/services/ai_service.dart';
import '../domain/local_insights.dart';
import '../domain/spending_stats.dart';
import 'preferences.dart';
import 'transactions_controller.dart';

@immutable
class WrappedData {
  const WrappedData({required this.recap, required this.story});

  final MonthRecap recap;
  final WrappedStory story;
}

/// The month Oobli Wrapped shows (latest month with data).
final wrappedMonthProvider = Provider<DateTime>((ref) => ref.watch(statsProvider).latestRecapMonth());

final wrappedProvider = FutureProvider<WrappedData>((ref) async {
  final txs = await ref.watch(transactionsProvider.future);
  final stats = SpendingStats(txs);
  final recap = stats.recap(ref.watch(wrappedMonthProvider));
  final local = LocalInsights.wrapped(recap);
  if (recap.isEmpty) return WrappedData(recap: recap, story: local);

  final store = ref.read(localStoreProvider);
  final key = '${Fmt.monthKey(recap.month)}|${recap.transactionCount}|${recap.total.round()}';
  final cached = store.readCache('wrapped', key);
  if (cached != null) return WrappedData(recap: recap, story: WrappedStory.fromJson(cached));

  try {
    final story = await ref.read(aiServiceProvider).wrapped(recap.toAiJson());
    await store.writeCache('wrapped', key, {
      'insight': story.insight,
      'badges': [for (final b in story.badges) {'label': b.label, 'icon': b.icon}],
      'win': {'title': story.winTitle, 'body': story.winBody},
    });
    return WrappedData(
      recap: recap,
      story: story.badges.isEmpty ? local : story,
    );
  } catch (e) {
    debugPrint('AI wrapped unavailable: $e');
    return WrappedData(recap: recap, story: local);
  }
});
