import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_failure.dart';
import '../data/models/category.dart';
import '../data/models/goal.dart';
import '../data/models/transaction.dart';
import '../data/repositories/goal_repository.dart';
import 'auth_controller.dart';
import 'transactions_controller.dart';

final goalsProvider = AsyncNotifierProvider<GoalsController, List<Goal>>(GoalsController.new);

final primaryGoalProvider = Provider<Goal?>((ref) {
  final goals = ref.watch(goalsProvider).value ?? const [];
  if (goals.isEmpty) return null;
  return goals.firstWhere((g) => g.isPrimary, orElse: () => goals.first);
});

class GoalsController extends AsyncNotifier<List<Goal>> {
  GoalRepository get _repo => ref.read(goalRepositoryProvider);

  String get _userId {
    final id = ref.read(currentUserIdProvider);
    if (id == null) throw const AppFailure('Please log in again.', code: 401);
    return id;
  }

  List<Goal> get _current => state.value ?? const [];

  @override
  Future<List<Goal>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];
    return ref.read(goalRepositoryProvider).fetchAll(userId);
  }

  Future<Goal> create(Goal goal) async {
    final makePrimary = goal.isPrimary || _current.isEmpty;
    if (makePrimary) await _clearPrimary();
    final created = await _repo.create(_userId, goal.copyWith(isPrimary: makePrimary));
    state = AsyncData([..._current, created]);
    return created;
  }

  Future<void> save(Goal goal) async {
    if (goal.isPrimary) await _clearPrimary(except: goal.id);
    final updated = await _repo.update(_userId, goal);
    state = AsyncData([for (final g in _current) g.id == updated.id ? updated : g]);
  }

  Future<void> delete(Goal goal) async {
    await _repo.delete(goal.id);
    final rest = _current.where((g) => g.id != goal.id).toList();
    state = AsyncData(rest);
    if (goal.isPrimary && rest.isNotEmpty) await save(rest.first.copyWith(isPrimary: true));
  }

  /// Adds money to a goal and records it as a savings transaction so it
  /// shows up in analytics and "saved this month".
  Future<void> deposit(Goal goal, double amount) async {
    await save(goal.copyWith(saved: goal.saved + amount));
    await ref.read(transactionsProvider.notifier).add(Transaction(
          id: '',
          fingerprint: 'goal-${goal.id}-${DateTime.now().microsecondsSinceEpoch}',
          amount: amount,
          direction: TxDirection.out,
          merchant: 'Goal · ${goal.title}',
          category: TxCategory.savings,
          channel: TxChannel.other,
          source: TxSource.manual,
          occurredAt: DateTime.now(),
          confirmed: true,
        ));
  }

  Future<void> _clearPrimary({String? except}) async {
    for (final g in _current.where((g) => g.isPrimary && g.id != except)) {
      final updated = await _repo.update(_userId, g.copyWith(isPrimary: false));
      state = AsyncData([for (final x in _current) x.id == updated.id ? updated : x]);
    }
  }
}
