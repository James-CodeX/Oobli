import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oobli_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/goal.dart';
import '../../domain/local_insights.dart';
import '../../state/auth_controller.dart';
import '../../state/goals_controller.dart';
import '../../state/insights_controller.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/progress.dart';
import '../../ui/widgets/tiles.dart';
import 'goal_sheets.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final goalsAsync = ref.watch(goalsProvider);
    final primary = ref.watch(primaryGoalProvider);
    final name = ref.watch(authControllerProvider).value?.name ?? '';

    final hasGoals = goalsAsync.value?.isNotEmpty ?? false;
    return Scaffold(
      floatingActionButton: goalsAsync.hasValue
          ? FloatingActionButton.extended(
              heroTag: 'new-goal',
              onPressed: () => showGoalEditor(context),
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              elevation: 2,
              icon: const Icon(Icons.add_rounded),
              label: Text(hasGoals ? 'New goal' : 'Create a goal',
                  style: t.labelLarge.copyWith(color: c.onPrimary, fontWeight: FontWeight.w700)),
            )
          : null,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(Sp.lg, MediaQuery.paddingOf(context).top + Sp.lg, Sp.lg, Sp.lg),
            decoration: BoxDecoration(color: c.surface, border: Border(bottom: BorderSide(color: c.divider))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Oobli Goals', style: t.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    Pressable(
                      onTap: () => context.push(Routes.settings),
                      semanticLabel: 'Profile and settings',
                      child: InitialsAvatar(name: name, size: 40, background: c.secondaryBackground, foreground: c.primary),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.sm),
                Text(_savingLine(ref), style: t.bodyMedium.copyWith(color: c.secondaryText)),
              ],
            ),
          ),
          goalsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Sp.lg),
              child: Column(children: [SkeletonBox(height: 160, radius: Rad.lg), SizedBox(height: Sp.lg), SkeletonBox(height: 240)]),
            ),
            error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(goalsProvider)),
            data: (goals) => goals.isEmpty || primary == null
                ? const Padding(
                    padding: EdgeInsets.only(top: Sp.xxl),
                    child: EmptyState(
                      title: 'Dream it, then save it',
                      message: 'Create a goal and Oobli will break it into milestones and cheer you on.',
                      mood: MascotMood.happy,
                    ),
                  )
                : _GoalsBody(goals: goals, primary: primary),
          ),
          const SizedBox(height: 96), // clear of the "New goal" button
        ],
      ),
    );
  }

  static String _savingLine(WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final monthStart = stats.today.monthStart;
    final prevStart = DateTime(monthStart.year, monthStart.month - 1);
    final now = stats.savedBetween(monthStart, stats.today.add(const Duration(days: 1)));
    final before = stats.savedBetween(prevStart, monthStart);
    if (now > before && before > 0) {
      return "You're saving ${Fmt.ksh(now - before)} more than last month. Keep it up!";
    }
    if (now > 0) return "You've saved ${Fmt.ksh(now)} this month. Every shilling counts!";
    return 'Small, steady deposits beat big one-offs. Start today!';
  }
}

class _GoalsBody extends ConsumerWidget {
  const _GoalsBody({required this.goals, required this.primary});

  final List<Goal> goals;
  final Goal primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    // The goal in the spotlight is the primary one, unless it's already
    // reached: then the next goal still in progress.
    final active = goals.where((g) => !g.isComplete).toList();
    final featured = !primary.isComplete ? primary : active.firstOrNull;
    final others = active.where((g) => g.id != featured?.id).toList();
    final done = goals.where((g) => g.isComplete).toList()
      ..sort((a, b) => (b.isPrimary ? 1 : 0).compareTo(a.isPrimary ? 1 : 0));
    final note = ref.watch(currentInsightsProvider).goalNote;
    final stats = ref.watch(statsProvider);

    return Padding(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (featured != null) ...[
            Text(featured.isPrimary ? 'Primary Goal' : 'In progress',
                style: t.labelLarge.copyWith(fontWeight: FontWeight.w700, color: c.onBackground)),
            const SizedBox(height: Sp.lg),
            _PrimaryGoalCard(goal: featured),
            const SizedBox(height: Sp.lg),
            Container(
              padding: const EdgeInsets.all(Sp.md),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.06),
                borderRadius: Rad.all(Rad.lg),
                border: Border.all(color: c.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Oobli says...', style: t.titleSmall.copyWith(fontWeight: FontWeight.w800, color: c.onSurface)),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Text(
                      featured.id == primary.id && note.isNotEmpty ? note : LocalInsights.goalProjection(featured, stats),
                      style: t.bodySmall.copyWith(color: c.primaryText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Sp.lg),
            Text('Milestones', style: t.titleLarge),
            const SizedBox(height: Sp.md),
            OobliCard(
              radius: Rad.lg,
              child: Column(
                children: [
                  for (final (i, m) in LocalInsights.milestones(featured).indexed) ...[
                    if (i > 0) const SizedBox(height: Sp.lg),
                    _MilestoneStep(milestone: m),
                  ],
                ],
              ),
            ),
          ] else
            OobliCard(
              radius: Rad.lg,
              color: c.primary.withValues(alpha: 0.06),
              borderColor: c.primary.withValues(alpha: 0.2),
              child: Row(
                children: [
                  const OobliMascot(size: 40, glow: false, mood: MascotMood.joy),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Text(
                      done.length == 1
                          ? 'You reached your goal! What are you saving for next?'
                          : 'All ${done.length} goals reached! What are you saving for next?',
                      style: t.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: Sp.lg),
            Text('Other Goals', style: t.titleLarge),
            const SizedBox(height: Sp.md),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: Sp.md,
              mainAxisSpacing: Sp.md,
              childAspectRatio: 2.05,
              children: [for (final g in others) _SmallGoalCard(goal: g)],
            ),
          ],
          if (done.isNotEmpty) ...[
            const SizedBox(height: Sp.lg),
            Text('Achieved', style: t.titleLarge),
            const SizedBox(height: Sp.md),
            OobliCard(
              radius: Rad.lg,
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              child: Column(
                children: [
                  for (final (i, g) in done.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    _AchievedRow(goal: g),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A reached goal: one slim row; tapping shows its history.
class _AchievedRow extends StatelessWidget {
  const _AchievedRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable(
      onTap: () => showGoalDetails(context, goal),
      scale: 0.98,
      semanticLabel: '${goal.title}, reached',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.md),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, size: 18, color: c.onPrimary),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyLarge),
                  Text('${Fmt.ksh(goal.target)} reached', style: t.labelSmall.copyWith(color: c.secondaryText)),
                ],
              ),
            ),
            Icon(goal.icon.icon, size: 20, color: c.secondaryText),
            const SizedBox(width: Sp.xs),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.hint),
          ],
        ),
      ),
    );
  }
}

class _PrimaryGoalCard extends StatelessWidget {
  const _PrimaryGoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable(
      onTap: () => showGoalDetails(context, goal),
      scale: 0.98,
      child: OobliCard(
        radius: Rad.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ToneTile(icon: goal.icon.icon, tone: goal.tone, size: 44, radius: Rad.lg),
                const SizedBox(width: Sp.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title, style: t.titleLarge),
                      const SizedBox(height: Sp.xs),
                      Text(
                        '${Fmt.ksh(goal.saved)} of ${Fmt.number(goal.target)}',
                        style: t.bodyMedium.copyWith(color: c.secondaryText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sp.lg),
            OobliProgressBar(value: goal.progress, color: c.tone(goal.tone), height: 10, radius: 2),
            const SizedBox(height: Sp.sm),
            Row(
              children: [
                Text(
                  '${Fmt.percent(goal.progress)} complete',
                  style: t.labelMedium.copyWith(color: c.tone(goal.tone), fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text('${Fmt.ksh(goal.remaining)} left', style: t.labelMedium.copyWith(color: c.secondaryText)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneStep extends StatelessWidget {
  const _MilestoneStep({required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final done = milestone.completed;
    return Row(
      children: [
        AnimatedContainer(
          duration: Motion.medium,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? c.primary : Colors.transparent,
            border: done ? null : Border.all(color: c.outline, width: 2.5),
          ),
          child: done ? Icon(Icons.check_rounded, size: 18, color: c.onPrimary) : null,
        ),
        const SizedBox(width: Sp.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(milestone.label, style: t.bodyLarge.copyWith(color: done ? c.primaryText : c.secondaryText)),
              Text(milestone.date, style: t.labelMedium.copyWith(color: c.secondaryText)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallGoalCard extends StatelessWidget {
  const _SmallGoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = goal.tone == Tone.primary ? Tone.success : goal.tone;
    return Pressable(
      onTap: () => showGoalDetails(context, goal),
      child: OobliCard(
        radius: Rad.lg,
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(goal.icon.icon, color: c.onSurface, size: 22),
            Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge.copyWith(fontWeight: FontWeight.w600)),
            OobliProgressBar(value: goal.progress, color: c.tone(tone), height: 5, radius: 0, trackColor: c.surfaceVariant),
          ],
        ),
      ),
    );
  }
}
