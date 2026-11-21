import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Onboarding page dots: the active one stretches into a pill.
class ProgressDots extends StatelessWidget {
  const ProgressDots({super.key, required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: Motion.medium,
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? c.primary : c.primary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}

/// "Step 1 of 3" segmented bar (Gamified Setup).
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({super.key, required this.total, required this.current});

  final int total;

  /// 1-based.
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: Sp.sm),
          Expanded(
            child: AnimatedContainer(
              duration: Motion.medium,
              height: 8,
              decoration: BoxDecoration(
                color: i < current ? c.primary : c.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Rounded progress bar that animates to [value] (0..1).
class OobliProgressBar extends StatelessWidget {
  const OobliProgressBar({
    super.key,
    required this.value,
    this.color,
    this.trackColor,
    this.height = 12,
    this.radius,
  });

  final double value;
  final Color? color;
  final Color? trackColor;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = BorderRadius.circular(radius ?? height);
    return ClipRRect(
      borderRadius: r,
      child: Container(
        height: height,
        color: trackColor ?? c.divider,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0, 1)),
          duration: Motion.slow,
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            heightFactor: 1,
            child: Container(decoration: BoxDecoration(color: color ?? c.success, borderRadius: r)),
          ),
        ),
      ),
    );
  }
}
