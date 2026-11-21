import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../state/auth_controller.dart';
import '../../state/preferences.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/progress.dart';
import '../../ui/widgets/tiles.dart';

class _Slide {
  const _Slide(this.title, this.body, this.says, this.mood, this.icon);

  final String title;
  final String body;
  final String says;
  final MascotMood mood;
  final IconData icon;
}

/// "Meet Oobli" onboarding carousel (3 slides, auto-advancing).
class MeetOobliScreen extends ConsumerStatefulWidget {
  const MeetOobliScreen({super.key});

  @override
  ConsumerState<MeetOobliScreen> createState() => _MeetOobliScreenState();
}

class _MeetOobliScreenState extends ConsumerState<MeetOobliScreen> {
  final _pages = PageController();
  Timer? _timer;
  int _index = 0;

  late final _slides = [
    const _Slide(
      'Meet Oobli',
      'Your AI financial companion that turns M-Pesa texts into clear spending plans.',
      "I've spotted 12 new M-Pesa transactions. Want me to categorize them?",
      MascotMood.happy,
      Icons.auto_awesome_rounded,
    ),
    const _Slide(
      'Oobli says...',
      'Smart nudges that catch subscriptions, spikes and Pochi patterns before they cost you.',
      "You typically spend KES 800 on 'Pochi la Biashara' on Wednesdays. Heads up!",
      MascotMood.thinking,
      Icons.insights_rounded,
    ),
    _Slide(
      'Oobli Plans',
      'Tell Oobli what you expect to earn and get an AI plan for needs, savings and fun.',
      'Your ${Fmt.monthName(DateTime.now())} plan is ready: 50% needs, 20% savings, 20% flex, 10% emergency.',
      MascotMood.joy,
      Icons.event_note_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pages.hasClients) return;
      _pages.animateToPage(
        (_index + 1) % _slides.length,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _go(bool login) {
    _timer?.cancel();
    ref.read(localStoreProvider).setSeenIntro();
    context.push(Routes.authWith(login: login));
  }

  /// Replaying onboarding while signed in: carry on to the setup steps.
  void _continue() {
    _timer?.cancel();
    context.go(Routes.smsPermission);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final signedIn = ref.watch(authControllerProvider).value != null;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Sp.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: OobliLogo()),
              Expanded(
                child: NotificationListener<ScrollStartNotification>(
                  onNotification: (n) {
                    if (n.dragDetails != null) _timer?.cancel();
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final s = _slides[i];
                      return LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: box.maxHeight),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(height: Sp.lg),
                                OobliMascot(size: 136, mood: s.mood),
                                const SizedBox(height: Sp.xl),
                                Text(
                                  s.title,
                                  textAlign: TextAlign.center,
                                  style: t.headlineLarge.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: Sp.md),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 330),
                                  child: Text(
                                    s.body,
                                    textAlign: TextAlign.center,
                                    style: t.bodyLarge.copyWith(color: c.secondaryText),
                                  ),
                                ),
                                const SizedBox(height: Sp.xl),
                                OobliSaysCard(
                                  message: s.says,
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: c.success.withValues(alpha: 0.25),
                                    ),
                                    child: Icon(s.icon, color: c.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: Sp.xl),
              ProgressDots(count: _slides.length, active: _index),
              const SizedBox(height: Sp.lg),
              if (signedIn)
                OobliButton(label: 'Continue', fullWidth: true, onPressed: _continue)
              else ...[
                OobliButton(label: 'Get Started', fullWidth: true, onPressed: () => _go(false)),
                const SizedBox(height: Sp.md),
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
