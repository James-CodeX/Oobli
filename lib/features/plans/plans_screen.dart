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
import '../../data/models/transaction.dart';
import '../../state/auth_controller.dart';
import '../../state/goals_controller.dart';
import '../../state/plan_controller.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/oobli_text_field.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/progress.dart';
import '../../ui/widgets/tiles.dart';
import '../assistant/ask_oobli_sheet.dart';
import '../transactions/spend_history_screen.dart';

IconData _bucketIcon(PlanBucket b) => switch (b) {
      PlanBucket.needs => Icons.home_rounded,
      PlanBucket.savings => Icons.savings_rounded,
      PlanBucket.flex => Icons.shopping_bag_rounded,
      _ => Icons.verified_user_rounded,
    };

/// "Oobli Plans": this month's plan and how it's going. Before there is a
/// plan, the page asks for the expected income and drafts one.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final planAsync = ref.watch(planProvider);
    final plan = planAsync.value;
    final month = Fmt.monthName(DateTime.now());

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top + Sp.sm, 0, Sp.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.sm),
            child: Row(
              children: [
                OobliIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => context.go(Routes.feed)),
                const SizedBox(width: Sp.xs),
                Expanded(
                  child: Text(
                    plan == null ? 'Oobli Plans' : '$month plan',
                    style: t.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (plan != null) ...[
                  OobliBadge(plan.isActive ? 'Active' : 'Draft', tone: plan.isActive ? Tone.primary : Tone.accent),
                  const SizedBox(width: Sp.xs),
                ],
                OobliIconButton(
                  icon: Icons.auto_awesome_rounded,
                  color: c.primary,
                  tooltip: 'Ask Oobli',
                  onPressed: () => showAskOobli(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Sp.lg),
            child: planAsync.when(
              loading: () => const Column(
                children: [SkeletonBox(height: 160, radius: Rad.lg), SizedBox(height: Sp.md), SkeletonBox(height: 260)],
              ),
              error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(planProvider)),
              data: (plan) => plan == null ? const _NoPlan() : _PlanBody(plan: plan),
            ),
          ),
        ],
      ),
    );
  }
}

/// First visit this month: expected income and goal, then Oobli drafts.
class _NoPlan extends StatelessWidget {
  const _NoPlan();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: OobliMascot(size: 96, glow: false, mood: MascotMood.working, interactive: true)),
        const SizedBox(height: Sp.md),
        Text('Plan your month', textAlign: TextAlign.center, style: t.titleLarge),
        const SizedBox(height: Sp.xs),
        Text(
          "Tell Oobli what you expect to receive. It reads your M-Pesa history and splits it into needs, "
          'savings, wants and an emergency buffer.',
          textAlign: TextAlign.center,
          style: t.bodyMedium.copyWith(color: c.secondaryText),
        ),
        const SizedBox(height: Sp.xl),
        const OobliCard(child: _PlanForm()),
      ],
    );
  }
}

/// Expected income + main goal → an AI-drafted plan. Used on the empty page
/// and in the "Re-draft" sheet.
class _PlanForm extends ConsumerStatefulWidget {
  const _PlanForm({this.onDone});

  /// Called after a plan was drafted (the sheet closes itself).
  final VoidCallback? onDone;

  @override
  ConsumerState<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends ConsumerState<_PlanForm> {
  final _income = TextEditingController();
  final _goal = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final plan = ref.read(planProvider).value;
    final income = plan?.income ?? ref.read(authControllerProvider).value?.monthlyIncome;
    if (income != null && income > 0) _income.text = Fmt.number(income.round());
    final goal = ref.read(primaryGoalProvider);
    _goal.text = plan?.goal ?? (goal == null || goal.isComplete ? '' : 'Save for ${goal.title}');
  }

  @override
  void dispose() {
    _income.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final income = ThousandsFormatter.parse(_income.text) ?? 0;
    if (income <= 0) {
      HapticFeedback.heavyImpact();
      showOobliSnack(context, 'Tell Oobli how much you expect to receive this month.', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ref.read(planProvider.notifier).generate(income: income, goal: _goal.text.trim());
      HapticFeedback.mediumImpact();
      widget.onDone?.call();
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planProvider).value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OobliTextField(
          label: 'Expected income this month',
          hint: 'KES 85,000',
          icon: Icons.payments_rounded,
          controller: _income,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsFormatter()],
        ),
        const SizedBox(height: Sp.md),
        OobliTextField(
          label: 'Main goal (optional)',
          hint: 'Save for a new laptop',
          icon: Icons.star_rounded,
          controller: _goal,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 200,
        ),
        const SizedBox(height: Sp.lg),
        OobliButton(
          label: _busy ? 'Drafting your plan…' : (plan == null ? 'Draft my plan' : 'Re-draft plan'),
          icon: Icons.auto_fix_high_rounded,
          size: OobliButtonSize.medium,
          fullWidth: true,
          loading: _busy,
          onPressed: _generate,
        ),
      ],
    );
  }
}

/// What each plan bucket covers in the transaction list.
bool _inBucket(Transaction t, PlanBucket bucket) =>
    bucket == PlanBucket.savings ? t.isOutgoing && t.category == TxCategory.savings : t.isSpend && t.category.bucket == bucket;

class _PlanBody extends ConsumerWidget {
  const _PlanBody({required this.plan});

  final Plan plan;

  Future<void> _activate(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(planProvider.notifier).activate();
      HapticFeedback.heavyImpact();
      if (context.mounted) showOobliSnack(context, 'Plan activated! Oobli will track it all month.');
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final spend = ref.watch(planSpendProvider);
    final now = ref.watch(statsProvider).now;
    final month = DateTime.parse('${plan.month}-01');
    final monthEnd = DateTime(month.year, month.month + 1);
    final daysInMonth = monthEnd.subtract(const Duration(days: 1)).day;
    final spendBuckets = plan.allocations.where((a) => a.bucket != PlanBucket.savings && a.bucket != PlanBucket.emergency);
    final spent = spendBuckets.fold<double>(0, (s, a) => s + (spend[a.bucket] ?? 0));
    final budget = spendBuckets.fold<double>(0, (s, a) => s + a.amount);
    final over = spent > budget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The month at a glance.
        OobliCard(
          radius: Rad.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spent so far', style: t.labelMedium.copyWith(color: c.secondaryText)),
                        const SizedBox(height: Sp.xs),
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(text: Fmt.kes(spent), style: t.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
                            TextSpan(
                              text: '  of ${Fmt.kes(budget)}',
                              style: t.bodyMedium.copyWith(color: c.secondaryText),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  // Over budget: tears. Spending slower than the month: cool.
                  OobliMascot(
                    size: 56,
                    glow: false,
                    interactive: true,
                    mood: over
                        ? MascotMood.crying
                        : budget > 0 && spent / budget <= now.day.clamp(1, daysInMonth) / daysInMonth
                            ? MascotMood.cool
                            : MascotMood.thinking,
                  ),
                ],
              ),
              const SizedBox(height: Sp.md),
              OobliProgressBar(value: budget <= 0 ? 0 : spent / budget, color: over ? c.error : c.primary, height: 8),
              const SizedBox(height: Sp.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      over ? '${Fmt.kes(spent - budget)} over' : '${Fmt.kes(budget - spent)} left to spend',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelMedium.copyWith(color: over ? c.error : c.secondaryText),
                    ),
                  ),
                  Text(
                    'Day ${now.day.clamp(1, daysInMonth)} of $daysInMonth',
                    style: t.labelMedium.copyWith(color: c.secondaryText),
                  ),
                ],
              ),
              const SizedBox(height: Sp.md),
              const Divider(height: 1),
              const SizedBox(height: Sp.md),
              Row(
                children: [
                  Icon(Icons.payments_rounded, size: 18, color: c.secondaryText),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: Text('Income ${Fmt.kes(plan.income)}', style: t.bodyMedium.copyWith(color: c.secondaryText)),
                  ),
                  if (plan.goal?.isNotEmpty == true)
                    Flexible(
                      child: Text(
                        plan.goal!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: t.bodyMedium.copyWith(color: c.secondaryText),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (!plan.isActive) ...[
          const SizedBox(height: Sp.md),
          Container(
            padding: const EdgeInsets.all(Sp.md),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.08),
              borderRadius: Rad.all(Rad.lg),
              border: Border.all(color: c.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    plan.summary?.isNotEmpty == true ? plan.summary! : "Oobli's draft from your M-Pesa history.",
                    style: t.bodySmall,
                  ),
                ),
                const SizedBox(width: Sp.md),
                OobliButton(
                  label: 'Activate Plan',
                  size: OobliButtonSize.small,
                  onPressed: () => _activate(context, ref),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Sp.xl),
        Row(
          children: [
            Expanded(child: Text('Where the money goes', style: t.titleMedium)),
            Flexible(child: Text('Tap to see payments', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: t.labelSmall.copyWith(color: c.hint))),
          ],
        ),
        const SizedBox(height: Sp.md),
        OobliCard(
          radius: Rad.lg,
          padding: const EdgeInsets.symmetric(horizontal: Sp.md),
          child: Column(
            children: [
              for (final (i, a) in plan.allocations.indexed) ...[
                if (i > 0) const Divider(height: 1),
                _BucketRow(
                  allocation: a,
                  used: spend[a.bucket] ?? 0,
                  onTap: a.bucket == PlanBucket.emergency
                      ? null
                      : () => showSpendHistory(
                            context,
                            title: a.label,
                            period: Fmt.monthName(month),
                            icon: _bucketIcon(a.bucket),
                            tone: a.tone,
                            budget: a.amount,
                            breakdown: true,
                            include: (t) =>
                                _inBucket(t, a.bucket) && !t.occurredAt.isBefore(month) && t.occurredAt.isBefore(monthEnd),
                          ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Sp.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TextAction(
              icon: Icons.tune_rounded,
              label: 'Adjust amounts',
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _EditAllocationsSheet(plan: plan),
              ),
            ),
            const SizedBox(width: Sp.xl),
            _TextAction(
              icon: Icons.auto_fix_high_rounded,
              label: 'Re-draft',
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (sheet) => Padding(
                  padding: EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, MediaQuery.viewInsetsOf(sheet).bottom + Sp.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Re-draft your plan', style: sheet.text.titleLarge),
                      const SizedBox(height: Sp.lg),
                      _PlanForm(onDone: () => Navigator.of(sheet).pop()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One plan bucket: what's been used of what was planned.
class _BucketRow extends StatelessWidget {
  const _BucketRow({required this.allocation, required this.used, required this.onTap});

  final PlanAllocation allocation;
  final double used;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final a = allocation;
    final savings = a.bucket == PlanBucket.savings;
    final buffer = a.bucket == PlanBucket.emergency;
    final over = !savings && !buffer && used > a.amount;
    final color = over ? c.error : c.tone(a.tone);

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.md),
      child: Row(
        children: [
          ToneTile(icon: _bucketIcon(a.bucket), tone: a.tone, size: 36, soft: true),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(a.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyLarge)),
                    Text(
                      buffer ? Fmt.kes(a.amount) : '${Fmt.compactKes(used)} / ${Fmt.compactKes(a.amount)}',
                      style: t.labelLarge.copyWith(fontWeight: FontWeight.w700, color: over ? c.error : c.primaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (buffer)
                  Text('Kept aside for surprises', style: t.labelSmall.copyWith(color: c.secondaryText))
                else ...[
                  OobliProgressBar(
                    value: a.amount <= 0 ? 0 : used / a.amount,
                    color: color,
                    height: 5,
                    trackColor: color.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    savings
                        ? '${Fmt.kes(used)} saved'
                        : over
                            ? '${Fmt.kes(used - a.amount)} over'
                            : '${Fmt.kes(a.amount - used)} left',
                    style: t.labelSmall.copyWith(color: over ? c.error : c.secondaryText),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 24,
            child: onTap == null ? null : Icon(Icons.chevron_right_rounded, size: 20, color: c.hint),
          ),
        ],
      ),
    );
    return onTap == null
        ? row
        : Pressable(onTap: onTap!, scale: 0.98, semanticLabel: '${a.label}, ${Fmt.kes(used)} used', child: row);
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: c.primary),
            const SizedBox(width: 6),
            Text(label, style: context.text.labelLarge.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
          ],
        ),
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
