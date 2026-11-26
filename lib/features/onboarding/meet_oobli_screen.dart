import 'dart:async';

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
import '../../state/auth_controller.dart';
import '../../state/preferences.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/progress.dart';
import '../../ui/widgets/tiles.dart';

/// The first screens: three short slides. Oobli starts asleep (tap to wake
/// him), then shows what he does with a tiny live demo on each slide.
class MeetOobliScreen extends ConsumerStatefulWidget {
  const MeetOobliScreen({super.key});

  @override
  ConsumerState<MeetOobliScreen> createState() => _MeetOobliScreenState();
}

class _MeetOobliScreenState extends ConsumerState<MeetOobliScreen> {
  final _pages = PageController();
  int _index = 0;
  bool _awake = false;
  int _bounce = 0;

  static const _count = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _wake() {
    if (_awake) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _awake = true;
      _bounce++;
    });
  }

  void _next() {
    _wake();
    _pages.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
  }

  void _go(bool login) {
    ref.read(localStoreProvider).setSeenIntro();
    context.push(Routes.authWith(login: login));
  }

  /// Replaying onboarding while signed in: carry on to the setup steps.
  void _continue() => context.go(Routes.smsPermission);

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(authControllerProvider).value != null;
    final last = _index == _count - 1;

    final slides = [
      _Slide(
        mood: _awake ? MascotMood.winking : MascotMood.sleeping,
        title: _awake ? "Hi, I'm Oobli" : 'Meet Oobli',
        body: 'Your M-Pesa, made simple.',
        onMascotTap: _wake,
        bounce: _bounce,
        extra: AnimatedOpacity(
          opacity: _awake ? 0 : 1,
          duration: Motion.medium,
          child: const _TapHint(),
        ),
      ),
      _Slide(
        mood: MascotMood.thinking,
        title: 'I read your M-Pesa',
        body: 'Every message, sorted for you.',
        extra: _SortDemo(play: _index == 1),
      ),
      _Slide(
        mood: MascotMood.love,
        title: 'Plans that stick',
        body: "Always know what's left.",
        extra: _PlanDemo(play: _index == 2),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, Sp.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: OobliLogo(size: 28)),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _index = i;
                      if (i > 0) _awake = true;
                    });
                  },
                  children: slides,
                ),
              ),
              ProgressDots(count: _count, active: _index),
              const SizedBox(height: Sp.xl),
              if (signedIn)
                // Seen it before: one tap carries on to setup.
                OobliButton(label: 'Continue', fullWidth: true, onPressed: _continue)
              else ...[
                AnimatedSwitcher(
                  duration: Motion.fast,
                  child: OobliButton(
                    key: ValueKey(last),
                    label: last ? 'Get Started' : 'Next',
                    fullWidth: true,
                    onPressed: last ? () => _go(false) : _next,
                  ),
                ),
                const SizedBox(height: Sp.sm),
                OobliButton(
                  label: 'I already have an account',
                  variant: OobliButtonVariant.ghost,
                  size: OobliButtonSize.medium,
                  fullWidth: true,
                  onPressed: () => _go(true),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.mood,
    required this.title,
    required this.body,
    this.extra,
    this.onMascotTap,
    this.bounce = 0,
  });

  final MascotMood mood;
  final String title;
  final String body;
  final Widget? extra;
  final VoidCallback? onMascotTap;
  final int bounce;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OobliMascot(
                size: box.maxHeight < 520 ? 150 : 190,
                mood: mood,
                interactive: true,
                onTap: onMascotTap,
                bounce: bounce,
              ),
              const SizedBox(height: Sp.lg),
              AnimatedSwitcher(
                duration: Motion.medium,
                child: Text(
                  title,
                  key: ValueKey(title),
                  textAlign: TextAlign.center,
                  style: t.headlineLarge.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: Sp.sm),
              Text(body, textAlign: TextAlign.center, style: t.bodyLarge.copyWith(color: c.secondaryText)),
              const SizedBox(height: Sp.xl),
              SizedBox(height: 118, child: extra),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Tap me" under the sleeping Oobli, gently pulsing.
class _TapHint extends StatefulWidget {
  const _TapHint();

  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: Tween(begin: 0.45, end: 1.0).animate(_pulse),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, size: 18, color: c.primary),
            const SizedBox(width: Sp.xs),
            Text('Tap to wake him', style: context.text.labelLarge.copyWith(color: c.primary)),
          ],
        ),
      ),
    );
  }
}

/// A raw M-Pesa SMS that turns into a neat, categorised transaction.
class _SortDemo extends StatefulWidget {
  const _SortDemo({required this.play});

  final bool play;

  @override
  State<_SortDemo> createState() => _SortDemoState();
}

class _SortDemoState extends State<_SortDemo> {
  bool _sorted = false;
  Timer? _timer;

  @override
  void didUpdateWidget(_SortDemo old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) {
      _timer?.cancel();
      setState(() => _sorted = false);
      _timer = Timer(const Duration(milliseconds: 1300), () {
        if (mounted) setState(() => _sorted = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    const food = TxCategory.food;
    return GestureDetector(
      onTap: () => setState(() => _sorted = !_sorted),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(a), child: child),
        ),
        child: _sorted
            ? OobliCard(
                key: const ValueKey('sorted'),
                radius: Rad.lg,
                padding: const EdgeInsets.all(Sp.md),
                child: Row(
                  children: [
                    ToneTile(icon: food.icon, tone: food.tone, size: 40, soft: true),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mama Oliech', style: t.titleSmall),
                          Text(food.label, style: t.labelSmall.copyWith(color: c.tone(food.tone))),
                        ],
                      ),
                    ),
                    Text('- ${Fmt.kes(450)}', style: t.titleSmall.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: Sp.sm),
                    Icon(Icons.check_circle_rounded, color: c.primary, size: 20),
                  ],
                ),
              )
            : Container(
                key: const ValueKey('sms'),
                padding: const EdgeInsets.all(Sp.md),
                decoration: BoxDecoration(
                  color: c.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Rad.lg),
                    topRight: Radius.circular(Rad.lg),
                    bottomRight: Radius.circular(Rad.lg),
                    bottomLeft: Radius.circular(Rad.xs),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MPESA', style: t.labelSmall.copyWith(color: c.secondaryText, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'TKL4X9 Confirmed. Ksh450.00 paid to MAMA OLIECH. on 26/11/26 at 1:12 PM. '
                      'New M-PESA balance is Ksh3,215.00.',
                      style: t.bodySmall.copyWith(color: c.primaryText),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Two plan buckets filling up, so "what's left" makes sense at a glance.
class _PlanDemo extends StatelessWidget {
  const _PlanDemo({required this.play});

  final bool play;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    Widget bar(String label, double used, String left, Tone tone, int delay) => TweenAnimationBuilder<double>(
          key: ValueKey('$label-$play'),
          tween: Tween(begin: 0, end: play ? used : 0),
          duration: Duration(milliseconds: 900 + delay),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: t.labelLarge)),
                  Text(left, style: t.labelMedium.copyWith(color: c.secondaryText)),
                ],
              ),
              const SizedBox(height: 6),
              OobliProgressBar(value: v, color: c.tone(tone), height: 8, trackColor: c.tone(tone).withValues(alpha: 0.15)),
            ],
          ),
        );
    return OobliCard(
      radius: Rad.lg,
      padding: const EdgeInsets.all(Sp.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          bar('Needs', 0.62, '${Fmt.kes(5700)} left', Tone.primary, 0),
          const SizedBox(height: Sp.md),
          bar('Wants', 0.85, '${Fmt.kes(900)} left', Tone.accent, 250),
        ],
      ),
    );
  }
}
