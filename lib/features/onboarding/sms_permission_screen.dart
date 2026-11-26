import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/services/sms_inbox_service.dart';
import '../../state/auth_controller.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/progress.dart';

class SmsPermissionScreen extends ConsumerStatefulWidget {
  const SmsPermissionScreen({super.key});

  @override
  ConsumerState<SmsPermissionScreen> createState() => _SmsPermissionScreenState();
}

class _SmsPermissionScreenState extends ConsumerState<SmsPermissionScreen> {
  bool _busy = false;

  Future<void> _grant() async {
    final inbox = ref.read(smsInboxServiceProvider);
    if (!inbox.isSupported) {
      showOobliSnack(context, 'Reading M-Pesa SMS is only available on Android. You can add transactions manually.');
      return;
    }
    setState(() => _busy = true);
    try {
      final granted = await inbox.requestPermission();
      if (!mounted) return;
      if (granted) {
        await ref.read(authControllerProvider.notifier).updateProfile((p) => p.copyWith(smsSyncEnabled: true));
        // Import in the background while the user finishes setup.
        ref.read(smsSyncControllerProvider.notifier).sync(silent: true);
        if (mounted) context.go(Routes.setup);
      } else if (await inbox.isPermanentlyDenied()) {
        if (!mounted) return;
        final open = await confirmAction(
          context,
          title: 'SMS access is blocked',
          message: 'Turn on SMS permission for Oobli in your phone settings to import M-Pesa messages.',
          confirmLabel: 'Open Settings',
        );
        if (open) await inbox.openSettings();
      } else if (mounted) {
        showOobliSnack(context, 'No worries! You can add transactions manually or enable SMS later in Settings.');
      }
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - Sp.lg * 2),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        OobliIconButton(
                          icon: Icons.close_rounded,
                          color: c.secondaryText,
                          tooltip: 'Skip',
                          onPressed: () => context.go(Routes.setup),
                        ),
                        const SizedBox(width: Sp.md),
                        const Expanded(child: SegmentedProgress(total: 4, current: 1)),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const Spacer(),
                    const Center(child: OobliMascot(size: 170, mood: MascotMood.peeking, interactive: true)),
                    const SizedBox(height: Sp.lg),
                    Text(
                      'Let me read your M-Pesa',
                      textAlign: TextAlign.center,
                      style: t.headlineMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: Sp.sm),
                    Text(
                      "and I'll sort every shilling for you.",
                      textAlign: TextAlign.center,
                      style: t.bodyLarge.copyWith(color: c.secondaryText),
                    ),
                    const SizedBox(height: Sp.xl),
                    const _FeatureRow(icon: Icons.lock_rounded, text: 'Only M-Pesa and bank messages'),
                    const _FeatureRow(icon: Icons.visibility_off_rounded, text: 'Your chats stay private'),
                    const _FeatureRow(icon: Icons.toggle_off_rounded, text: 'Turn it off anytime'),
                    const Spacer(),
                    const SizedBox(height: Sp.xl),
                    OobliButton(label: 'Allow SMS access', fullWidth: true, loading: _busy, onPressed: _grant),
                    const SizedBox(height: Sp.sm),
                    OobliButton(
                      label: "I'll add transactions myself",
                      variant: OobliButtonVariant.ghost,
                      size: OobliButtonSize.medium,
                      fullWidth: true,
                      onPressed: _busy ? null : () => context.go(Routes.setup),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: c.primary),
          const SizedBox(width: Sp.sm),
          Text(text, style: context.text.bodyMedium),
        ],
      ),
    );
  }
}
