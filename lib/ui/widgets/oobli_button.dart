import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import 'pressable.dart';

enum OobliButtonVariant { primary, secondary, outline, ghost, danger }

enum OobliButtonSize { small, medium, large }

class OobliButton extends StatelessWidget {
  const OobliButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = OobliButtonVariant.primary,
    this.size = OobliButtonSize.large,
    this.fullWidth = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final OobliButtonVariant variant;
  final OobliButtonSize size;
  final bool fullWidth;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final enabled = onPressed != null && !loading;

    final (Color bg, Color fg, Color? border) = switch (variant) {
      OobliButtonVariant.primary => (c.primary, c.onPrimary, null),
      OobliButtonVariant.secondary => (c.surfaceVariant, c.primaryText, null),
      OobliButtonVariant.outline => (Colors.transparent, c.primaryText, c.outline),
      OobliButtonVariant.ghost => (Colors.transparent, c.primary, null),
      OobliButtonVariant.danger => (c.error, c.onError, null),
    };
    final (double height, double radius, double hPad, TextStyle style, double iconSize) = switch (size) {
      OobliButtonSize.small => (34.0, Rad.sm, Sp.md, t.labelMedium, 16.0),
      OobliButtonSize.medium => (44.0, Rad.md, Sp.lg, t.labelLarge, 18.0),
      OobliButtonSize.large => (52.0, Rad.lg, Sp.lg, t.labelLarge, 20.0),
    };

    final content = loading
        ? SizedBox.square(
            dimension: iconSize,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize, color: fg),
                const SizedBox(width: Sp.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.copyWith(color: fg, letterSpacing: 0.6),
                ),
              ),
            ],
          );

    final hasFill = variant == OobliButtonVariant.primary || variant == OobliButtonVariant.danger;

    return Opacity(
      opacity: enabled || loading ? 1 : 0.5,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        semanticLabel: label,
        child: Container(
          height: height,
          width: fullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: Rad.all(radius),
            border: border == null ? null : Border.all(color: border, width: 1.5),
            boxShadow: hasFill && enabled ? Shadows.sm : null,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Small text link in the primary colour ("Details", "Edit").
class OobliLink extends StatelessWidget {
  const OobliLink(this.label, {super.key, required this.onTap, this.color});

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Sp.xs),
          child: Text(
            label,
            style: context.text.labelLarge.copyWith(color: color ?? context.colors.primary),
          ),
        ),
      );
}

/// Round icon button used in headers (close, back, search, share).
class OobliIconButton extends StatelessWidget {
  const OobliIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onPressed,
        scale: 0.9,
        semanticLabel: tooltip,
        child: SizedBox.square(
          dimension: 44,
          child: Icon(icon, size: size, color: color ?? context.colors.primaryText),
        ),
      );
}
