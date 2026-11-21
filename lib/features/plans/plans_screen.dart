import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oobli_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/plan.dart';
import '../../state/auth_controller.dart';
import '../../state/goals_controller.dart';
import '../../state/plan_controller.dart';
import '../../ui/widgets/charts.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/oobli_text_field.dart';
import '../../ui/widgets/progress.dart';
import '../../ui/widgets/tiles.dart';
import '../assistant/ask_oobli_sheet.dart';

IconData _bucketIcon(PlanBucket b) => switch (b) {
      PlanBucket.needs => Icons.home_rounded,
      PlanBucket.savings => Icons.savings_rounded,
      PlanBucket.flex => Icons.shopping_cart_rounded,
      _ => Icons.verified_user_rounded,
    };

/// "Oobli Plans": anticipated income + goal -> AI-drafted monthly plan.
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  final _income = TextEditingController();
  final _goal = TextEditingController();
  bool _generating = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _income.dispose();
    _goal.dispose();
    super.dispose();
  }

  void _prefill(Plan? plan) {
    if (_prefilled) return;
    _prefilled = true;
    final income = plan?.income ?? ref.read(authControllerProvider).value?.monthlyIncome;
    if (income != null && income > 0) _income.text = Fmt.number(income.round());
    final goal = plan?.goal ?? ref.read(primaryGoalProvider)?.title;
    if (goal != null) _goal.text = plan?.goal ?? 'Save for $goal';
  }

  Future<void> _generate() async {
    final income = ThousandsFormatter.parse(_income.text) ?? 0;
    if (income <= 0) {
      HapticFeedback.heavyImpact();
      showOobliSnack(context, 'Tell Oobli how much you expect to receive this month.', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _generating = true);
    try {
      await ref.read(planProvider.notifier).generate(income: income, goal: _goal.text.trim());
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _activate() async {
    try {
      await ref.read(planProvider.notifier).activate();
      HapticFeedback.heavyImpact();
      if (mounted) showOobliSnack(context, 'Plan activated! Oobli will track it all month.');
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final planAsync = ref.watch(planProvider);
    final plan = planAsync.value;
    if (planAsync.hasValue) _prefill(plan);

    return Scaffold(
      bottomNavigationBar: plan == null ? null : _ActionBar(plan: plan, onActivate: _activate),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(Sp.lg, MediaQuery.paddingOf(context).top + Sp.md, Sp.lg, Sp.lg),
            decoration: BoxDecoration(
              color: c.secondaryBackground,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    OobliIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => context.go(Routes.feed)),
                    Expanded(child: Text('Oobli Plans', textAlign: TextAlign.center, style: t.titleLarge)),
                    OobliIconButton(
                      icon: Icons.auto_awesome_rounded,
                      color: c.primary,
                      tooltip: 'Ask Oobli',
                      onPressed: () => showAskOobli(context),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.lg),
                OobliCard(
                  shadow: true,
                  borderColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Oobli says...', style: t.labelLarge.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
                      const SizedBox(height: Sp.md),
                      Text(
                        "Tell me what you're expecting this month, and I'll draft a plan for you.",
                        style: t.bodyMedium.copyWith(color: c.secondaryText),
                      ),
                      const SizedBox(height: Sp.md),
                      OobliTextField(
                        label: 'Anticipated Income',
                        hint: 'KES 85,000',
                        icon: Icons.payments_rounded,
                        controller: _income,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsFormatter()],
                      ),
                      const SizedBox(height: Sp.md),
                      OobliTextField(
                        label: 'Main Goal',
                        hint: 'Save for a new laptop',
                        icon: Icons.star_rounded,
                        controller: _goal,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 200,
                      ),
                      const SizedBox(height: Sp.lg),
                      OobliButton(
                        label: plan == null ? 'Generate AI Plan' : 'Re-draft AI Plan',
                        icon: Icons.auto_fix_high_rounded,
                        size: OobliButtonSize.medium,
                        fullWidth: true,
                        loading: _generating,
                        onPressed: _generate,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Sp.lg),
            child: planAsync.when(
              loading: () => const Column(
                children: [SkeletonBox(height: 200, radius: Rad.lg), SizedBox(height: Sp.md), SkeletonBox(height: 110)],
              ),
              error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(planProvider)),
              data: (plan) => AnimatedSwitcher(
                duration: Motion.medium,
                child: _generating
                    ? const _Drafting()
                    : plan == null
                        ? const EmptyState(
                            title: 'Your plan appears here',
                            message: 'Oobli looks at your M-Pesa history to split your income into needs, savings, '
                                'flex spending and an emergency buffer.',
                            mood: MascotMood.happy,
                          )
                        : _PlanBody(plan: plan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Drafting extends StatelessWidget {
  const _Drafting();

  @override
  Widget build(BuildContext context) => const EmptyState(
        title: 'Drafting your plan…',
        message: 'Oobli is reading your spending history and balancing your budget.',
        mood: MascotMood.thinking,
      );
}

class _PlanBody extends ConsumerWidget {
  const _PlanBody({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final spend = ref.watch(planSpendProvider);
    final month = DateTime.parse('${plan.month}-01');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Fmt.monthName(month)} ${plan.isActive ? 'Active' : 'Draft'} Plan',
                    style: t.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: Sp.xs),
                  Text(
                    plan.summary?.isNotEmpty == true ? plan.summary! : 'Based on your M-Pesa history',
                    style: t.bodySmall.copyWith(color: c.secondaryText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Sp.sm),
            OobliBadge(plan.isActive ? 'Active' : 'AI Draft', tone: plan.isActive ? Tone.primary : Tone.accent),
          ],
        ),
        const SizedBox(height: Sp.lg),
        OobliCard(
          radius: Rad.lg,
          padding: const EdgeInsets.all(Sp.lg),
          child: DonutChart(
            size: 132,
            centerValue: Fmt.compactKes(plan.income),
            centerLabel: 'income',
            slices: [
              for (final a in plan.allocations)
                DonutSlice(label: a.legend, value: a.percent.toDouble(), color: c.tone(a.tone)),
            ],
          ),
        ),
        const SizedBox(height: Sp.lg),
        for (final a in plan.allocations) ...[
          _PlanItem(allocation: a, spent: plan.isActive ? spend[a.bucket] ?? 0 : null),
          const SizedBox(height: Sp.md),
        ],
      ],
    );
  }
}

class _PlanItem extends StatelessWidget {
  const _PlanItem({required this.allocation, this.spent});

  final PlanAllocation allocation;

  /// Spent so far this month (only for active plans).
  final double? spent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final a = allocation;
    final over = spent != null && spent! > a.amount;
    return OobliCard(
      radius: Rad.lg,
      child: Column(
        children: [
          Row(
            children: [
              ToneTile(icon: _bucketIcon(a.bucket), tone: a.tone, size: 44, radius: Rad.lg),
              const SizedBox(width: Sp.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(a.label, style: t.titleLarge)),
                        Text(Fmt.kes(a.amount), style: t.titleLarge.copyWith(color: c.primary)),
                      ],
                    ),
                    const SizedBox(height: Sp.xs),
                    Text(a.reason, style: t.bodyMedium.copyWith(color: c.secondaryText)),
                  ],
                ),
              ),
            ],
          ),
          if (spent != null) ...[
            const SizedBox(height: Sp.md),
            OobliProgressBar(
              value: a.amount <= 0 ? 0 : spent! / a.amount,
              color: over ? c.error : c.tone(a.tone),
              height: 8,
            ),
            const SizedBox(height: Sp.sm),
            Row(
              children: [
                Text(
                  '${Fmt.kes(spent!)} ${a.bucket == PlanBucket.savings ? 'saved' : 'spent'}',
                  style: t.labelMedium.copyWith(color: over ? c.error : c.secondaryText),
                ),
                const Spacer(),
                Text(
                  over ? '${Fmt.kes(spent! - a.amount)} over' : '${Fmt.kes(a.amount - spent!)} left',
                  style: t.labelMedium.copyWith(color: over ? c.error : c.secondaryText),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.plan, required this.onActivate});

  final Plan plan;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Sp.lg),
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.divider))),
      child: Row(
        children: [
          Expanded(
            child: OobliButton(
              label: 'Edit Details',
              variant: OobliButtonVariant.outline,
              size: OobliButtonSize.medium,
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _EditAllocationsSheet(plan: plan),
              ),
            ),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: OobliButton(
              label: plan.isActive ? 'Plan Active' : 'Activate Plan',
              icon: plan.isActive ? Icons.check_rounded : null,
              size: OobliButtonSize.medium,
              onPressed: plan.isActive ? null : onActivate,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sliders for each bucket; moving one rebalances the others to keep 100%.
class _EditAllocationsSheet extends ConsumerStatefulWidget {
  const _EditAllocationsSheet({required this.plan});

  final Plan plan;

  @override
  ConsumerState<_EditAllocationsSheet> createState() => _EditAllocationsSheetState();
}

class _EditAllocationsSheetState extends ConsumerState<_EditAllocationsSheet> {
  late List<PlanAllocation> _rows = widget.plan.allocations;
  bool _saving = false;

  void _change(int index, int value) {
    final others = [for (var i = 0; i < _rows.length; i++) if (i != index) i];
    final remaining = 100 - value;
    final otherTotal = others.fold<int>(0, (s, i) => s + _rows[i].percent);
    final next = [..._rows];
    next[index] = _rows[index].withPercent(value, widget.plan.income);
    var assigned = 0;
    for (final (n, i) in others.indexed) {
      final pct = n == others.length - 1
          ? remaining - assigned
          : otherTotal == 0
              ? remaining ~/ others.length
              : (_rows[i].percent / otherTotal * remaining).round();
      assigned += pct;
      next[i] = _rows[i].withPercent(pct.clamp(0, 100), widget.plan.income);
    }
    setState(() => _rows = next);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(planProvider.notifier).updateAllocations(_rows);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showFailure(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Fine-tune your plan', style: t.headlineSmall),
            const SizedBox(height: Sp.xs),
            Text('Income: ${Fmt.kes(widget.plan.income)}', style: t.bodyMedium.copyWith(color: c.secondaryText)),
            const SizedBox(height: Sp.lg),
            for (final (i, a) in _rows.indexed) ...[
              Row(
                children: [
                  Icon(_bucketIcon(a.bucket), color: c.tone(a.tone), size: 20),
                  const SizedBox(width: Sp.sm),
                  Expanded(child: Text(a.label, style: t.titleSmall)),
                  Text('${a.percent}% · ${Fmt.kes(a.amount)}', style: t.labelLarge.copyWith(color: c.secondaryText)),
                ],
              ),
              Slider(
                value: a.percent.toDouble(),
                max: 100,
                divisions: 20,
                activeColor: c.tone(a.tone),
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  _change(i, v.round());
                },
              ),
            ],
            const SizedBox(height: Sp.md),
            OobliButton(label: 'Save plan', fullWidth: true, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
