import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/oobli_colors.dart';
import '../../core/theme/tokens.dart';
import 'pressable.dart';
import 'tiles.dart';

/// Selectable option card (Gamified Setup): green border, tint and check when selected.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(Sp.lg),
        decoration: BoxDecoration(
          color: selected ? c.primaryContainer : c.surface,
          borderRadius: Rad.all(Rad.xl),
          border: Border.all(color: selected ? c.primary : c.outline, width: 2),
          boxShadow: selected ? null : Shadows.sm,
        ),
        child: Row(
          children: [
            ToneTile(icon: icon, tone: Tone.primary, size: 48, radius: Rad.lg),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: Sp.xs),
                    Text(subtitle!, style: t.bodyMedium.copyWith(color: c.secondaryText)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Sp.sm),
            AnimatedSwitcher(
              duration: Motion.medium,
              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
              child: selected
                  ? Container(
                      key: const ValueKey('on'),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                      child: Icon(Icons.check_rounded, size: 20, color: c.onPrimary),
                    )
                  : Container(
                      key: const ValueKey('off'),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: c.outline, width: 2),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact rounded pill used for quick picks (amount presets, filters).
class PillChoice extends StatelessWidget {
  const PillChoice({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.primaryContainer : c.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? c.primary : c.outline, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? c.primary : c.secondaryText),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: context.text.labelLarge.copyWith(color: selected ? c.primary : c.primaryText),
            ),
          ],
        ),
      ),
    );
  }
}
