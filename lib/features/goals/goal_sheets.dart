import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/oobli_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/goal.dart';
import '../../data/models/category.dart';
import '../../state/goals_controller.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/choice_card.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/oobli_text_field.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/progress.dart';
import '../../ui/widgets/tiles.dart';

Future<void> showGoalEditor(BuildContext context, {Goal? goal}) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _GoalEditorSheet(goal: goal),
    );

Future<void> showGoalDetails(BuildContext context, Goal goal) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _GoalDetailsSheet(goalId: goal.id),
    );

/// Add money, edit, make primary or delete a goal.
class _GoalDetailsSheet extends ConsumerStatefulWidget {
  const _GoalDetailsSheet({required this.goalId});

  final String goalId;

  @override
  ConsumerState<_GoalDetailsSheet> createState() => _GoalDetailsSheetState();
}

class _GoalDetailsSheetState extends ConsumerState<_GoalDetailsSheet> {
  final _amount = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {String? success, bool close = false}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (success != null) showOobliSnack(context, success);
      if (close) Navigator.pop(context);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final goals = ref.watch(goalsProvider).value ?? const [];
    final goal = goals.where((g) => g.id == widget.goalId).firstOrNull;
    if (goal == null) return const SizedBox(height: 120);
    final deposits = ref
        .watch(statsProvider)
        .all
        .where((t) => t.merchant == goalDepositMerchant(goal) && t.category == TxCategory.savings)
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ToneTile(icon: goal.icon.icon, tone: goal.tone, size: 48, radius: Rad.lg),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title, style: t.headlineSmall),
                      Text(
                        goal.deadline == null ? 'No deadline' : 'By ${Fmt.monthYear(goal.deadline!)}',
                        style: t.bodySmall.copyWith(color: c.secondaryText),
                      ),
                    ],
                  ),
                ),
                if (goal.isComplete) const OobliMascot(size: 48, glow: false, mood: MascotMood.joy),
              ],
            ),
            const SizedBox(height: Sp.lg),
            OobliProgressBar(value: goal.progress, color: c.tone(goal.tone)),
            const SizedBox(height: Sp.sm),
            Text('${Fmt.ksh(goal.saved)} of ${Fmt.ksh(goal.target)} · ${Fmt.percent(goal.progress)}',
                style: t.labelLarge.copyWith(color: c.secondaryText)),
            if (!goal.isComplete) ...[
              const SizedBox(height: Sp.lg),
              OobliTextField(
                label: 'Add money',
                hint: '1,000',
                icon: Icons.add_card_rounded,
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                fillColor: c.surface,
              ),
              const SizedBox(height: Sp.sm),
              Wrap(
                spacing: Sp.sm,
                children: [
                  for (final v in const [500, 1000, 5000])
                    PillChoice(
                      label: '+${Fmt.number(v)}',
                      selected: false,
                      onTap: () => setState(() => _amount.text = Fmt.number(v)),
                    ),
                ],
              ),
              const SizedBox(height: Sp.md),
              OobliButton(
                label: 'Add to goal',
                fullWidth: true,
                loading: _busy,
                onPressed: () {
                  final amount = ThousandsFormatter.parse(_amount.text) ?? 0;
                  if (amount <= 0) {
                    HapticFeedback.heavyImpact();
                    return;
                  }
                  HapticFeedback.mediumImpact();
                  _run(
                    () => ref.read(goalsProvider.notifier).deposit(goal, amount),
                    success: goal.saved + amount >= goal.target
                        ? 'Goal reached! Oobli is so proud of you!'
                        : '${Fmt.ksh(amount)} added to ${goal.title}',
                    close: true,
                  );
                },
              ),
            ],
            const SizedBox(height: Sp.lg),
            Text('History', style: t.titleMedium),
            const SizedBox(height: Sp.xs),
            for (final d in deposits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Sp.sm),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 18, color: c.tone(goal.tone)),
                    const SizedBox(width: Sp.sm),
                    Expanded(
                      child: Text(
                        '${Fmt.shortDate(d.occurredAt)}, ${d.occurredAt.year} · ${Fmt.time12(d.occurredAt)}',
                        style: t.bodyMedium,
                      ),
                    ),
                    Text('+${Fmt.ksh(d.amount)}', style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.sm),
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, size: 18, color: c.secondaryText),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: Text(
                      'Started ${Fmt.shortDate(goal.createdAt)}, ${goal.createdAt.year}',
                      style: t.bodyMedium.copyWith(color: c.secondaryText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Sp.lg),
            Row(
              children: [
                Expanded(
                  child: OobliButton(
                    label: 'Edit',
                    icon: Icons.edit_rounded,
                    variant: OobliButtonVariant.outline,
                    size: OobliButtonSize.medium,
                    onPressed: _busy
                        ? null
                        : () {
                            Navigator.pop(context);
                            showGoalEditor(context, goal: goal);
                          },
                  ),
                ),
                if (!goal.isPrimary) ...[
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: OobliButton(
                      label: 'Make primary',
                      icon: Icons.star_rounded,
                      variant: OobliButtonVariant.outline,
                      size: OobliButtonSize.medium,
                      onPressed: _busy
                          ? null
                          : () => _run(() => ref.read(goalsProvider.notifier).save(goal.copyWith(isPrimary: true)),
                              close: true),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: Sp.sm),
            OobliButton(
              label: 'Delete goal',
              icon: Icons.delete_outline_rounded,
              variant: OobliButtonVariant.ghost,
              size: OobliButtonSize.medium,
              onPressed: _busy
                  ? null
                  : () async {
                      final ok = await confirmAction(
                        context,
                        title: 'Delete ${goal.title}?',
                        message: 'Your saved progress on this goal will be removed.',
                        confirmLabel: 'Delete',
                        destructive: true,
                      );
                      if (ok) await _run(() => ref.read(goalsProvider.notifier).delete(goal), close: true);
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalEditorSheet extends ConsumerStatefulWidget {
  const _GoalEditorSheet({this.goal});

  final Goal? goal;

  @override
  ConsumerState<_GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends ConsumerState<_GoalEditorSheet> {
  late final _title = TextEditingController(text: widget.goal?.title ?? '');
  late final _target = TextEditingController(
    text: widget.goal == null ? '' : Fmt.number(widget.goal!.target.round()),
  );
  late GoalIcon _icon = widget.goal?.icon ?? GoalIcon.star;
  late Tone _tone = widget.goal?.tone ?? Tone.primary;
  late DateTime? _deadline = widget.goal?.deadline;
  bool _saving = false;

  static const _tones = [Tone.primary, Tone.accent, Tone.secondary, Tone.warning, Tone.error];

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final target = ThousandsFormatter.parse(_target.text) ?? 0;
    if (title.isEmpty || target <= 0) {
      HapticFeedback.heavyImpact();
      showOobliSnack(context, 'Give your goal a name and a target amount.', error: true);
      return;
    }
    setState(() => _saving = true);
    final controller = ref.read(goalsProvider.notifier);
    try {
      final existing = widget.goal;
      if (existing == null) {
        await controller.create(Goal(
          id: '',
          title: title,
          icon: _icon,
          target: target,
          saved: 0,
          createdAt: DateTime.now(),
          deadline: _deadline,
          tone: _tone,
        ));
      } else {
        await controller.save(existing.copyWith(
          title: title,
          icon: _icon,
          target: target,
          tone: _tone,
          deadline: _deadline,
          clearDeadline: _deadline == null,
        ));
      }
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.goal == null ? 'New goal' : 'Edit goal', style: t.headlineSmall),
            const SizedBox(height: Sp.lg),
            OobliTextField(
              label: 'What are you saving for?',
              hint: 'New MacBook Pro',
              icon: Icons.flag_rounded,
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              fillColor: c.surface,
              maxLength: 120,
            ),
            const SizedBox(height: Sp.md),
            OobliTextField(
              label: 'Target amount (KSh)',
              hint: '240,000',
              icon: Icons.payments_rounded,
              controller: _target,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              fillColor: c.surface,
            ),
            const SizedBox(height: Sp.md),
            Pressable(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline ?? DateTime.now().add(const Duration(days: 180)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(Sp.md),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: Rad.all(Rad.md),
                  border: Border.all(color: c.outline, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded, color: c.secondaryText, size: 20),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Text(
                        _deadline == null ? 'Add a deadline (optional)' : 'By ${Fmt.shortDate(_deadline!)} ${_deadline!.year}',
                        style: t.bodyLarge.copyWith(color: _deadline == null ? c.hint : c.primaryText),
                      ),
                    ),
                    if (_deadline != null)
                      GestureDetector(
                        onTap: () => setState(() => _deadline = null),
                        child: Icon(Icons.close_rounded, color: c.secondaryText, size: 20),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Sp.lg),
            Text('Icon', style: t.labelLarge.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: Sp.sm),
            Wrap(
              spacing: Sp.sm,
              runSpacing: Sp.sm,
              children: [
                for (final icon in GoalIcon.values)
                  Pressable(
                    onTap: () => setState(() => _icon = icon),
                    child: AnimatedContainer(
                      duration: Motion.fast,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: icon == _icon ? c.toneContainer(_tone) : c.surface,
                        borderRadius: Rad.all(Rad.md),
                        border: Border.all(color: icon == _icon ? c.tone(_tone) : c.outline, width: 1.5),
                      ),
                      child: Icon(icon.icon, color: icon == _icon ? c.tone(_tone) : c.secondaryText),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Sp.lg),
            Text('Colour', style: t.labelLarge.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: Sp.sm),
            Row(
              children: [
                for (final tone in _tones)
                  Padding(
                    padding: const EdgeInsets.only(right: Sp.md),
                    child: Pressable(
                      onTap: () => setState(() => _tone = tone),
                      child: AnimatedContainer(
                        duration: Motion.fast,
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c.tone(tone),
                          shape: BoxShape.circle,
                          border: Border.all(color: tone == _tone ? c.primaryText : Colors.transparent, width: 3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Sp.xl),
            OobliButton(
              label: widget.goal == null ? 'Create goal' : 'Save changes',
              fullWidth: true,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
