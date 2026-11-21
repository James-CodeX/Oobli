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
import '../../ui/widgets/tiles.dart';

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
                        const Expanded(child: OobliProgressBar(value: 0.92)),
                      ],
                    ),
                    const Spacer(),
                    const Center(child: OobliMascot(size: 96, glow: false)),
                    const SizedBox(height: Sp.lg),
                    OobliSaysCard(
                      centered: true,
                      message: 'I need to see your messages to magically organize your M-Pesa & Bank spending!',
                      messageStyle: t.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const SizedBox(height: Sp.lg),
                    OobliCard(
                      child: Column(
                        children: const [
                          _FeatureRow(
                            icon: Icons.sms_rounded,
                            title: 'SMS Access',
                            body: 'To read M-Pesa, Pochi, and Bank transaction alerts automatically.',
                          ),
                          SizedBox(height: Sp.lg),
                          _FeatureRow(
                            icon: Icons.auto_awesome_rounded,
                            title: 'AI Categorization',
                            body: 'Oobli learns your habits to group groceries, rent, and fun.',
                          ),
                          SizedBox(height: Sp.lg),
                          _FeatureRow(
                            icon: Icons.security_rounded,
                            title: 'Privacy First',
                            body: 'Only financial messages are processed. Personal chats stay private.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Sp.lg),
                    OobliButton(label: 'Grant Access', fullWidth: true, loading: _busy, onPressed: _grant),
                    const SizedBox(height: Sp.md),
                    OobliButton(
                      label: "I'll add transactions manually",
                      variant: OobliButtonVariant.ghost,
                      size: OobliButtonSize.medium,
                      fullWidth: true,
                      onPressed: _busy ? null : () => context.go(Routes.setup),
                    ),
                    const SizedBox(height: Sp.md),
                    Text(
                      'You can revoke this access anytime in your phone settings.',
                      textAlign: TextAlign.center,
                      style: t.labelSmall.copyWith(color: c.onBackground),
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
  const _FeatureRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: Rad.all(Rad.md)),
          child: Icon(icon, color: c.primary),
        ),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.titleMedium),
              const SizedBox(height: Sp.xs),
              Text(body, style: t.bodyMedium.copyWith(color: c.secondaryText)),
            ],
          ),
        ),
      ],
    );
  }
}
