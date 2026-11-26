import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../state/update_controller.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/progress.dart';

Future<void> showUpdateSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _UpdateSheet(),
    );

/// Checks now (from Settings): opens the sheet when there's an update, or
/// says Oobli is up to date.
Future<void> checkForUpdatesNow(BuildContext context, WidgetRef ref) async {
  try {
    final update = await ref.read(updateProvider.notifier).check(manual: true);
    if (!context.mounted) return;
    if (update == null) {
      final installed = ref.read(installedAppProvider).value?.version;
      showOobliSnack(context, "You're on the latest version${installed == null ? '' : ' (v$installed)'}");
    } else {
      await showUpdateSheet(context);
    }
  } catch (_) {
    if (context.mounted) {
      showOobliSnack(context, ref.read(updateProvider).error ?? "Couldn't check for updates.", error: true);
    }
  }
}

String _size(int bytes) => bytes <= 0 ? '' : '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';

class _UpdateSheet extends ConsumerWidget {
  const _UpdateSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final s = ref.watch(updateProvider);
    final update = s.available;
    final installed = ref.watch(installedAppProvider).value?.version;
    if (update == null) return const SizedBox(height: 120);
    final controller = ref.read(updateProvider.notifier);
    final highlights = update.highlights;

    final (String label, VoidCallback? action) = switch (s.phase) {
      UpdatePhase.downloading => ('Downloading… ${(s.progress * 100).round()}%', null),
      UpdatePhase.needsPermission => ('Install', controller.downloadAndInstall),
      UpdatePhase.installing => ('Install again', controller.downloadAndInstall),
      UpdatePhase.failed => ('Try again', controller.downloadAndInstall),
      _ => ('Download and install${update.size > 0 ? ' · ${_size(update.size)}' : ''}', controller.downloadAndInstall),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const OobliMascot(size: 56, glow: false, mood: MascotMood.party),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Oobli ${update.version} is ready', style: t.titleLarge),
                    if (installed != null)
                      Text('You have $installed', style: t.bodySmall.copyWith(color: c.secondaryText)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.lg),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (update.headline.isNotEmpty) Text(update.headline, style: t.titleSmall),
                  for (final h in highlights.take(8))
                    Padding(
                      padding: const EdgeInsets.only(top: Sp.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7, right: Sp.sm),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                            ),
                          ),
                          Expanded(child: Text(h, style: t.bodyMedium.copyWith(color: c.secondaryText))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Sp.lg),
          if (s.phase == UpdatePhase.downloading) ...[
            OobliProgressBar(value: s.progress, color: c.primary, height: 6),
            const SizedBox(height: Sp.md),
          ],
          if (s.phase == UpdatePhase.needsPermission) ...[
            _Note(
              icon: Icons.verified_user_rounded,
              text: 'Turn on "Allow from this source" for Oobli, come back, then tap Install. '
                  'Android only asks the first time.',
            ),
            const SizedBox(height: Sp.md),
          ],
          if (s.phase == UpdatePhase.installing) ...[
            const _Note(
              icon: Icons.install_mobile_rounded,
              text: 'Tap "Update" on the Android screen. Oobli restarts on the new version, and your data stays.',
            ),
            const SizedBox(height: Sp.md),
          ],
          if (s.phase == UpdatePhase.failed && s.error != null) ...[
            _Note(icon: Icons.error_outline_rounded, text: s.error!, error: true),
            const SizedBox(height: Sp.md),
          ],
          OobliButton(
            label: label,
            icon: s.phase == UpdatePhase.downloading ? null : Icons.system_update_rounded,
            fullWidth: true,
            onPressed: action,
          ),
          const SizedBox(height: Sp.sm),
          OobliButton(
            label: 'Later',
            variant: OobliButtonVariant.ghost,
            size: OobliButtonSize.medium,
            fullWidth: true,
            onPressed: () {
              controller.dismiss();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.error = false});

  final IconData icon;
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = error ? c.error : c.primary;
    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: Rad.all(Rad.md),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: Sp.sm),
          Expanded(child: Text(text, style: context.text.bodySmall)),
        ],
      ),
    );
  }
}
