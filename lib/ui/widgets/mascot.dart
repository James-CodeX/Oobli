import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Oobli's poses (stickers in `assets/mascot/`). Pick the one that fits the
/// moment:
/// * [sleeping]: welcome, idle, offline.
/// * [winking]: hello, tips, "got it".
/// * [thinking]: Oobli is working something out.
/// * [working]: the AI assistant and AI-drafted plans.
/// * [love]: goals and things you care about.
/// * [celebrating] / [party]: milestones, goals reached, all sorted.
/// * [cool]: streaks and good habits.
/// * [crying]: overspending and things that went wrong.
/// * [cozy]: calm moments (sign in, settings).
/// * [peeking]: empty lists, "nothing here yet".
/// * [relaxed]: nothing left to do.
enum MascotMood {
  sleeping('sleeping'),
  winking('winking'),
  thinking('thinking'),
  working('working-at-laptop'),
  love('hugging-heart'),
  celebrating('celebrating'),
  party('party'),
  cool('cool'),
  crying('crying'),
  cozy('holding-mug'),
  peeking('peeking'),
  relaxed('belly-up');

  const MascotMood(this.file);

  final String file;

  String get asset => 'assets/mascot/$file.webp';
}

/// Oobli the cat. Floats gently; when [interactive], a tap makes it hop.
class OobliMascot extends StatefulWidget {
  const OobliMascot({
    super.key,
    this.size = 160,
    this.mood = MascotMood.winking,
    this.glow = true,
    this.animate = true,
    this.interactive = false,
    this.onTap,
    this.bounce = 0,
  });

  final double size;
  final MascotMood mood;

  /// A soft circle behind Oobli.
  final bool glow;
  final bool animate;

  /// Hop (with a little haptic) when tapped.
  final bool interactive;
  final VoidCallback? onTap;

  /// Change this number to make Oobli hop (e.g. when the user picks something).
  final int bounce;

  @override
  State<OobliMascot> createState() => _OobliMascotState();
}

class _OobliMascotState extends State<OobliMascot> with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _float.repeat();
  }

  @override
  void didUpdateWidget(OobliMascot old) {
    super.didUpdateWidget(old);
    if (old.bounce != widget.bounce) _hop.forward(from: 0);
    if (old.animate != widget.animate) widget.animate ? _float.repeat() : _float.stop();
  }

  @override
  void dispose() {
    _float.dispose();
    _hop.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.lightImpact();
    _hop.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = widget.size;
    final box = widget.glow ? s * 1.25 : s;

    final sticker = Image.asset(
      widget.mood.asset,
      width: s,
      height: s,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      semanticLabel: 'Oobli',
    );

    Widget body = RepaintBoundary(
      child: SizedBox.square(
        dimension: box,
        child: AnimatedBuilder(
          animation: Listenable.merge([_float, _hop]),
          builder: (context, child) {
            final t = _float.value;
            final float = widget.animate ? math.sin(t * 2 * math.pi) * s * 0.02 : 0.0;
            // Hop: up and back down, squashing a little on landing.
            final h = _hop.value;
            final lift = math.sin(h * math.pi) * s * 0.12;
            final squash = h > 0.75 ? 1 - math.sin((h - 0.75) / 0.25 * math.pi) * 0.05 : 1.0;
            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.glow)
                  Container(
                    width: box,
                    height: box,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary.withValues(alpha: 0.08)),
                  ),
                Transform.translate(
                  offset: Offset(0, float - lift),
                  child: Transform.scale(scaleY: squash, scaleX: 2 - squash, alignment: Alignment.bottomCenter, child: child),
                ),
              ],
            );
          },
          child: AnimatedSwitcher(
            duration: Motion.medium,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(a), child: child),
            ),
            child: KeyedSubtree(key: ValueKey(widget.mood), child: sticker),
          ),
        ),
      ),
    );
    if (widget.interactive || widget.onTap != null) {
      body = GestureDetector(behavior: HitTestBehavior.opaque, onTap: _tap, child: body);
    }
    return body;
  }
}

/// Oobli wordmark: the peeking cat and the name.
class OobliLogo extends StatelessWidget {
  const OobliLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(MascotMood.peeking.asset, height: size, filterQuality: FilterQuality.medium),
        SizedBox(width: size * 0.2),
        Text(
          'Oobli',
          style: context.text.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: size * 0.62),
        ),
      ],
    );
  }
}
