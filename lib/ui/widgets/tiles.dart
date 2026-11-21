import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/oobli_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';

/// Coloured rounded-square icon tile used across cards and list rows.
class ToneTile extends StatelessWidget {
  const ToneTile({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 48,
    this.radius,
    this.soft = false,
  });

  final IconData icon;
  final Tone tone;
  final double size;
  final double? radius;

  /// Tinted background with a coloured icon instead of a solid fill.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: soft ? c.toneContainer(tone) : c.tone(tone),
        borderRadius: BorderRadius.circular(radius ?? size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: soft ? c.tone(tone) : c.onTone(tone)),
    );
  }
}

/// Circle avatar with initials (dashboard, goals, profile).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.background,
    this.foreground,
  });

  final String name;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background ?? c.primary),
      child: Text(
        Fmt.initials(name),
        style: context.text.titleMedium.copyWith(
          color: foreground ?? c.onPrimary,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// "AI Categorized" pill.
class AiChip extends StatelessWidget {
  const AiChip({super.key, this.label = 'AI Categorized'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 3),
      decoration: BoxDecoration(color: c.secondaryContainer, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: context.text.labelSmall.copyWith(color: c.secondary, fontWeight: FontWeight.w700)),
    );
  }
}

/// Small solid badge ("AI Draft", "Active").
class OobliBadge extends StatelessWidget {
  const OobliBadge(this.label, {super.key, this.tone = Tone.accent});

  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 2),
      decoration: BoxDecoration(color: c.tone(tone), borderRadius: Rad.all(Rad.sm)),
      child: Text(label, style: context.text.labelMedium.copyWith(color: c.onTone(tone), fontWeight: FontWeight.w500)),
    );
  }
}

/// Standard surface card: rounded, bordered, optional hard shadow.
class OobliCard extends StatelessWidget {
  const OobliCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Sp.lg),
    this.radius = Rad.xl,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: Rad.all(radius),
        border: Border.all(color: borderColor ?? c.divider, width: borderWidth),
        boxShadow: shadow ? Shadows.sm : null,
      ),
      child: child,
    );
  }
}

/// The recurring "Oobli says..." speech card.
class OobliSaysCard extends StatelessWidget {
  const OobliSaysCard({
    super.key,
    required this.message,
    this.leading,
    this.centered = false,
    this.tinted = false,
    this.messageStyle,
    this.actions,
    this.title = 'Oobli says...',
  });

  final String message;
  final Widget? leading;
  final bool centered;

  /// Uses the primary tint (green) background instead of the surface colour.
  final bool tinted;
  final TextStyle? messageStyle;
  final Widget? actions;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final text = Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: t.labelMedium.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
        const SizedBox(height: Sp.xs),
        AnimatedSwitcher(
          duration: Motion.medium,
          child: Text(
            message,
            key: ValueKey(message),
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: messageStyle ?? t.bodyMedium.copyWith(color: c.primaryText),
          ),
        ),
        if (actions != null) ...[const SizedBox(height: Sp.md), actions!],
      ],
    );

    return OobliCard(
      shadow: !tinted,
      borderWidth: tinted ? 1 : 2,
      color: tinted ? c.primaryContainer : c.surface,
      borderColor: tinted ? c.primary.withValues(alpha: 0.2) : c.outline,
      radius: tinted ? Rad.lg : Rad.xl,
      padding: EdgeInsets.all(tinted ? Sp.md : Sp.lg),
      child: leading == null
          ? SizedBox(width: double.infinity, child: text)
          : Row(
              children: [
                leading!,
                const SizedBox(width: Sp.md),
                Expanded(child: text),
              ],
            ),
    );
  }
}

/// Section title used in lists ("TODAY", "Financial Engine").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.upper = false, this.padding = EdgeInsets.zero});

  final String text;
  final bool upper;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Text(
          upper ? text.toUpperCase() : text,
          style: context.text.labelLarge.copyWith(color: context.colors.secondaryText, fontWeight: FontWeight.w700),
        ),
      );
}
