import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_failure.dart';
import '../core/utils/formatters.dart';
import '../data/models/category.dart';
import '../data/models/plan.dart';
import '../data/repositories/plan_repository.dart';
import '../data/services/ai_service.dart';
import 'auth_controller.dart';
import 'transactions_controller.dart';

final planProvider = AsyncNotifierProvider<PlanController, Plan?>(PlanController.new);

/// Spend so far this month per plan bucket (for active-plan progress).
final planSpendProvider = Provider<Map<PlanBucket, double>>((ref) {
  final stats = ref.watch(statsProvider);
  final start = stats.today.monthStart;
  final end = stats.today.add(const Duration(days: 1));
  final out = <PlanBucket, double>{};
  for (final e in stats.byCategory(start, end).entries) {
    out[e.key.bucket] = (out[e.key.bucket] ?? 0) + e.value;
  }
  out[PlanBucket.savings] = stats.savedBetween(start, end).clamp(0, double.infinity).toDouble();
  return out;
});

class PlanController extends AsyncNotifier<Plan?> {
  static String get currentMonth => Fmt.monthKey(DateTime.now());

  String get _userId {
    final id = ref.read(currentUserIdProvider);
    if (id == null) throw const AppFailure('Please log in again.', code: 401);
    return id;
  }

  @override
  Future<Plan?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    return ref.read(planRepositoryProvider).fetch(userId, currentMonth);
  }

  /// Drafts a plan with Gemini; falls back to a 50/20/20/10 split offline.
  Future<Plan> generate({required double income, required String goal}) async {
    final profile = ref.read(authControllerProvider).value;
    final focus = profile?.focus?.key ?? 'tracking';
    ({String summary, List<PlanAllocation> allocations}) draft;
    try {
      draft = await ref.read(aiServiceProvider).plan(
            income: income,
            goal: goal,
            focus: focus,
            month: Fmt.monthYear(DateTime.now()),
            history: ref.read(statsProvider).planHistory(),
          );
    } catch (e) {
      debugPrint('AI plan unavailable, using default split: $e');
      draft = (summary: 'A balanced 50/20/20/10 starter plan.', allocations: defaultAllocations(income, goal));
    }

    final plan = Plan(
      id: PlanRepository.idFor(_userId, currentMonth),
      month: currentMonth,
      income: income,
      status: PlanStatus.draft,
      allocations: draft.allocations,
      goal: goal.isEmpty ? null : goal,
      focus: focus,
      summary: draft.summary,
    );
    final saved = await ref.read(planRepositoryProvider).save(_userId, plan);
    state = AsyncData(saved);
    await ref.read(authControllerProvider.notifier).updateProfile((p) => p.copyWith(monthlyIncome: income));
    return saved;
  }

  Future<void> activate() => _save((p) => p.copyWith(status: PlanStatus.active));

  Future<void> updateAllocations(List<PlanAllocation> allocations) =>
      _save((p) => p.copyWith(allocations: allocations));

  Future<void> _save(Plan Function(Plan) change) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(change(current));
    try {
      state = AsyncData(await ref.read(planRepositoryProvider).save(_userId, change(current)));
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  static List<PlanAllocation> defaultAllocations(double income, String goal) {
    PlanAllocation a(PlanBucket b, String label, int pct, String reason) => PlanAllocation(
          bucket: b,
          label: label,
          percent: pct,
          amount: (income * pct / 100).roundToDouble(),
          reason: reason,
        );
    return [
      a(PlanBucket.needs, 'Fixed Needs', 50, 'Rent, utilities, food and transport.'),
      a(PlanBucket.savings, 'Savings Goal', 20,
          goal.isEmpty ? 'Pay yourself first every month.' : 'Steady progress towards $goal.'),
      a(PlanBucket.flex, 'Flex Spending', 20, 'Dining, outings and treats.'),
      a(PlanBucket.emergency, 'Emergency', 10, 'Safety net for unexpected M-Pesa requests.'),
    ];
  }
}
