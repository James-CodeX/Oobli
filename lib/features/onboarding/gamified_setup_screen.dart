import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/goal.dart';
import '../../data/models/user_profile.dart';
import '../../state/auth_controller.dart';
import '../../state/goals_controller.dart';
import '../../state/preferences.dart';
import '../../ui/widgets/choice_card.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/oobli_text_field.dart';
import '../../ui/widgets/progress.dart';

class _GoalPreset {
  const _GoalPreset(this.title, this.icon, this.target);

  final String title;
  final GoalIcon icon;
  final double target;
}

/// Three quick questions (focus, income, first goal) before the home screen.
class GamifiedSetupScreen extends ConsumerStatefulWidget {
  const GamifiedSetupScreen({super.key});

  @override
  ConsumerState<GamifiedSetupScreen> createState() => _GamifiedSetupScreenState();
}

class _GamifiedSetupScreenState extends ConsumerState<GamifiedSetupScreen> {
  int _step = 1;
  // Replaying from Settings starts from what the user picked last time.
  late FocusGoal _focus = ref.read(authControllerProvider).value?.focus ?? FocusGoal.debt;
  late final _income = TextEditingController(text: switch (ref.read(authControllerProvider).value?.monthlyIncome) {
    final income? when income > 0 => Fmt.number(income.round()),
    _ => '',
  });
  final _target = TextEditingController();
  _GoalPreset? _goal;
  bool _saving = false;

  static const _focusOptions = [
    (FocusGoal.debt, 'Clear those M-Shwari & Fuliza balances', Icons.local_fire_department_rounded),
    (FocusGoal.saving, 'Build a buffer for the rainy days', Icons.savings_rounded),
    (FocusGoal.investing, 'Grow wealth in M-Mali or Stocks', Icons.trending_up_rounded),
    (FocusGoal.tracking, 'I want to see where my M-Pesa goes', Icons.visibility_rounded),
  ];

  static const _goalPresets = [
    _GoalPreset('New Laptop', GoalIcon.laptop, 120000),
    _GoalPreset('Emergency Fund', GoalIcon.emergency, 50000),
    _GoalPreset('New Phone', GoalIcon.phone, 40000),
    _GoalPreset('Coast Trip', GoalIcon.travel, 30000),
    _GoalPreset('Rent Buffer', GoalIcon.home, 60000),
    _GoalPreset('Grow My Business', GoalIcon.business, 100000),
  ];

  @override
  void dispose() {
    _income.dispose();
    _target.dispose();
    super.dispose();
  }

  String get _question => switch (_step) {
        1 => "Let's set your focus for this month. What's the big plan?",
        2 => 'How much money are you expecting this month?',
        _ => "What's one thing you're saving for?",
      };

  void _next() {
    HapticFeedback.mediumImpact();
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      context.go(Routes.smsPermission);
    }
  }

  Future<void> _finish({bool skipGoal = false}) async {
    setState(() => _saving = true);
    try {
      final income = ThousandsFormatter.parse(_income.text);
      if (!skipGoal && _goal != null) {
        final target = ThousandsFormatter.parse(_target.text) ?? _goal!.target;
        await ref.read(goalsProvider.notifier).create(Goal(
              id: '',
              title: _goal!.title,
              icon: _goal!.icon,
              target: target,
              saved: 0,
              createdAt: DateTime.now(),
              deadline: DateTime(DateTime.now().year, DateTime.now().month + 6, 1),
              isPrimary: true,
            ));
      }
      await ref.read(authControllerProvider.notifier).updateProfile((p) => p.copyWith(
            focus: _focus,
            monthlyIncome: income,
            onboardingComplete: true,
          ));
      await ref.read(onboardingReplayProvider.notifier).finish();
      if (mounted) context.go(Routes.plans);
    } catch (e) {
      if (mounted) {
        showFailure(context, e);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Sp.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  OobliIconButton(
                    icon: _step == 1 ? Icons.close_rounded : Icons.arrow_back_rounded,
                    color: c.secondaryText,
                    tooltip: 'Back',
                    onPressed: _back,
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(child: SegmentedProgress(total: 3, current: _step)),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: Sp.md),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent.withValues(alpha: 0.25)),
                    child: OobliMascot(size: 32, glow: false, mood: _step == 3 ? MascotMood.joy : MascotMood.happy),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Oobli says...', style: t.labelLarge.copyWith(fontWeight: FontWeight.w700, color: c.onBackground)),
                        const SizedBox(height: Sp.xs),
                        AnimatedSwitcher(
                          duration: Motion.medium,
                          child: Text(
                            _question,
                            key: ValueKey(_step),
                            style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.xl),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.medium,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0.1, 0), end: Offset.zero).animate(a),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(key: ValueKey(_step), child: _stepBody()),
                ),
              ),
              const SizedBox(height: Sp.md),
              _hint(),
              const SizedBox(height: Sp.md),
              OobliButton(
                label: _step == 3 ? 'Continue to Oobli Plans' : 'Continue',
                fullWidth: true,
                loading: _saving,
                onPressed: _step == 2 && (ThousandsFormatter.parse(_income.text) ?? 0) <= 0
                    ? null
                    : _step == 3 && _goal == null
                        ? () => _finish(skipGoal: true)
                        : _next,
              ),
              if (_step > 1) ...[
                const SizedBox(height: Sp.sm),
                OobliButton(
                  label: _step == 2 ? 'Skip for now' : "I'll set goals later",
                  variant: OobliButtonVariant.ghost,
                  size: OobliButtonSize.medium,
                  fullWidth: true,
                  onPressed: _saving ? null : (_step == 2 ? _next : () => _finish(skipGoal: true)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody() => switch (_step) {
        1 => ListView.separated(
            itemCount: _focusOptions.length,
            separatorBuilder: (_, _) => const SizedBox(height: Sp.md),
            itemBuilder: (_, i) {
              final (focus, subtitle, icon) = _focusOptions[i];
              return ChoiceCard(
                title: focus.label,
                subtitle: subtitle,
                icon: icon,
                selected: _focus == focus,
                onTap: () => setState(() => _focus = focus),
              );
            },
          ),
        2 => ListView(
            children: [
              OobliTextField(
                label: 'Anticipated Income',
                hint: '85,000',
                icon: Icons.payments_rounded,
                controller: _income,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                fillColor: context.colors.surface,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Sp.lg),
              Wrap(
                spacing: Sp.sm,
                runSpacing: Sp.sm,
                children: [
                  for (final amount in const [20000, 50000, 85000, 150000])
                    PillChoice(
                      label: Fmt.kes(amount),
                      selected: ThousandsFormatter.parse(_income.text) == amount,
                      onTap: () => setState(() => _income.text = Fmt.number(amount)),
                    ),
                ],
              ),
            ],
          ),
        _ => ListView(
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: Sp.md,
                crossAxisSpacing: Sp.md,
                childAspectRatio: 1.6,
                children: [for (final g in _goalPresets) _GoalTile(
                  preset: g,
                  selected: _goal == g,
                  onTap: () => setState(() {
                    _goal = g;
                    _target.text = Fmt.number(g.target);
                  }),
                )],
              ),
              AnimatedSize(
                duration: Motion.medium,
                child: _goal == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: Sp.lg),
                        child: OobliTextField(
                          label: 'Target amount',
                          icon: Icons.flag_rounded,
                          controller: _target,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsFormatter()],
                          fillColor: context.colors.surface,
                        ),
                      ),
              ),
            ],
          ),
      };

  Widget _hint() {
    final c = context.colors;
    final message = switch (_step) {
      1 => "Most Oobli users in Nairobi start with 'Kill the Debt' to save on interest.",
      2 => 'Oobli uses this to draft your first AI plan. You can change it anytime.',
      _ => 'Goals with a target get milestones and a projected finish date.',
    };
    return Container(
      padding: const EdgeInsets.all(Sp.lg),
      decoration: BoxDecoration(color: c.surfaceVariant.withValues(alpha: 0.45), borderRadius: Rad.all(Rad.lg)),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 18, color: c.onSurfaceVariant),
          const SizedBox(width: Sp.sm),
          Expanded(child: Text(message, style: context.text.bodySmall.copyWith(color: c.secondaryText))),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.preset, required this.selected, required this.onTap});

  final _GoalPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: Motion.medium,
        padding: const EdgeInsets.all(Sp.md),
        decoration: BoxDecoration(
          color: selected ? c.primaryContainer : c.surface,
          borderRadius: Rad.all(Rad.lg),
          border: Border.all(color: selected ? c.primary : c.outline, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(preset.icon.icon, color: selected ? c.primary : c.primaryText),
            Text(preset.title, style: context.text.titleSmall),
          ],
        ),
      ),
    );
  }
}
