import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

enum MascotMood { happy, thinking, joy }

/// Oobli, the gradient blob mascot. It floats gently and blinks; the [joy]
/// mood shows happy "^ ^" eyes for celebrations.
class OobliMascot extends StatefulWidget {
  const OobliMascot({
    super.key,
    this.size = 160,
    this.mood = MascotMood.happy,
    this.glow = true,
    this.animate = true,
  });

  final double size;
  final MascotMood mood;
  final bool glow;
  final bool animate;

  @override
  State<OobliMascot> createState() => _OobliMascotState();
}

class _OobliMascotState extends State<OobliMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = widget.size;
    final box = widget.glow ? s * 1.25 : s;

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: box,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final float = math.sin(t * 2 * math.pi) * s * 0.025;
            // Blink twice per loop, each ~120ms.
            final blink = (t > 0.46 && t < 0.49) || (t > 0.93 && t < 0.96);
            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.glow)
                  Container(
                    width: box,
                    height: box,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primary.withValues(alpha: 0.08),
                    ),
                  ),
                Transform.translate(
                  offset: Offset(0, float),
                  child: Container(
                    width: s,
                    height: s,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(s * 0.375),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.primary, c.accent],
                      ),
                    ),
                    child: CustomPaint(
                      painter: _EyesPainter(mood: widget.mood, blink: blink && widget.animate),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EyesPainter extends CustomPainter {
  _EyesPainter({required this.mood, required this.blink});

  final MascotMood mood;
  final bool blink;

  static const _eye = Color(0xFF131F24);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final eyeW = w * 0.1;
    final eyeH = w * 0.15;
    final gap = w * 0.15;
    final cy = size.height * (mood == MascotMood.thinking ? 0.44 : 0.5);
    final shift = mood == MascotMood.thinking ? w * 0.04 : 0.0;
    final centers = [
      Offset(w / 2 - gap / 2 - eyeW / 2 + shift, cy),
      Offset(w / 2 + gap / 2 + eyeW / 2 + shift, cy),
    ];

    if (mood == MascotMood.joy) {
      final paint = Paint()
        ..color = _eye
        ..style = PaintingStyle.stroke
        ..strokeWidth = eyeW * 0.6
        ..strokeCap = StrokeCap.round;
      for (final c in centers) {
        final rect = Rect.fromCenter(center: c.translate(0, eyeH * 0.15), width: eyeW * 1.6, height: eyeH);
        canvas.drawArc(rect, math.pi * 1.1, math.pi * 0.8, false, paint);
      }
      final smile = Rect.fromCenter(center: Offset(w / 2, cy + eyeH * 0.9), width: gap * 1.2, height: eyeH * 0.8);
      canvas.drawArc(smile, math.pi * 0.15, math.pi * 0.7, false, paint);
      return;
    }

    final paint = Paint()..color = _eye;
    for (final c in centers) {
      final h = blink ? eyeH * 0.12 : eyeH;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: eyeW, height: h),
          Radius.circular(eyeW / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EyesPainter old) => old.mood != mood || old.blink != blink;
}

/// "[wallet] Oobli" wordmark from the onboarding header.
class OobliLogo extends StatelessWidget {
  const OobliLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(size / 4)),
          child: Icon(Icons.account_balance_wallet_rounded, size: size * 0.62, color: c.onSurface),
        ),
        SizedBox(width: size * 0.2),
        Text(
          'Oobli',
          style: context.text.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: size * 0.62),
        ),
      ],
    );
  }
}
