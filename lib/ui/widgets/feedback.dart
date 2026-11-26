import 'package:material_ui/material_ui.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import 'mascot.dart';
import 'oobli_button.dart';

void showOobliSnack(
  BuildContext context,
  String message, {
  bool error = false,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final c = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: error ? c.error : c.surfaceVariant,
      duration: Duration(seconds: onAction == null ? 4 : 8),
      action: onAction == null
          ? null
          : SnackBarAction(label: actionLabel ?? 'Open', textColor: c.primary, onPressed: onAction),
      content: Row(
        children: [
          Icon(icon ?? (error ? Icons.error_outline_rounded : Icons.auto_awesome_rounded),
              color: error ? c.onError : c.primary, size: 20),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Text(message, style: context.text.bodyMedium.copyWith(color: error ? c.onError : c.primaryText)),
          ),
        ],
      ),
    ));
}

void showFailure(BuildContext context, Object error) =>
    showOobliSnack(context, AppFailure.from(error).message, error: true);

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
      actions: [
        Row(
          children: [
            Expanded(
              child: OobliButton(
                label: 'Cancel',
                variant: OobliButtonVariant.outline,
                size: OobliButtonSize.medium,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: OobliButton(
                label: confirmLabel,
                variant: destructive ? OobliButtonVariant.danger : OobliButtonVariant.primary,
                size: OobliButtonSize.medium,
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Friendly empty state with the mascot.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.secondary,
    this.mood = MascotMood.peeking,
  });

  final String title;
  final String message;
  final Widget? action;
  final Widget? secondary;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OobliMascot(size: 72, mood: mood),
          const SizedBox(height: Sp.md),
          Text(title, textAlign: TextAlign.center, style: context.text.titleMedium),
          const SizedBox(height: Sp.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium.copyWith(color: context.colors.secondaryText),
          ),
          if (action != null) ...[const SizedBox(height: Sp.lg), action!],
          if (secondary != null) ...[const SizedBox(height: Sp.sm), secondary!],
        ],
      ),
    );
  }
}

/// Inline error with retry.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = AppFailure.from(error);
    return EmptyState(
      title: 'Oops, a small hiccup',
      mood: MascotMood.crying,
      message: failure.message,
      action: OobliButton(
        label: 'Try again',
        icon: Icons.refresh_rounded,
        size: OobliButtonSize.medium,
        onPressed: onRetry,
      ),
      secondary: FailureDetails(failure: failure),
    );
  }
}

/// "Show details" toggle revealing the technical cause (selectable, for support).
class FailureDetails extends StatefulWidget {
  const FailureDetails({super.key, required this.failure});

  final AppFailure failure;

  @override
  State<FailureDetails> createState() => _FailureDetailsState();
}

class _FailureDetailsState extends State<FailureDetails> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final details = widget.failure.details;
    if (details == null || details.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => setState(() => _open = !_open),
          child: Text(_open ? 'Hide details' : 'Show details',
              style: context.text.labelMedium.copyWith(color: c.secondaryText)),
        ),
        if (_open)
          SelectableText(
            details,
            textAlign: TextAlign.center,
            style: context.text.bodySmall.copyWith(color: c.hint, fontSize: 11),
          ),
      ],
    );
  }
}

/// Pulsing placeholder block for loading states.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius = Rad.md});

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.4, end: 0.9).animate(_c),
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant,
            borderRadius: Rad.all(widget.radius),
          ),
        ),
      );
}
