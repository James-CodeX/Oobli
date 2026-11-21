import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/services/sms_inbox_service.dart';
import '../../state/auth_controller.dart';
import '../../state/preferences.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/choice_card.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/oobli_text_field.dart';

Future<void> _sheet(BuildContext context, Widget child) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
          child: child,
        ),
      ),
    );

Future<void> showEditNameDialog(BuildContext context, WidgetRef ref, String current) async {
  final controller = TextEditingController(text: current);
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Your name'),
      content: OobliTextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.words),
      actions: [
        OobliButton(
          label: 'Save',
          size: OobliButtonSize.medium,
          onPressed: () => Navigator.pop(context, controller.text.trim()),
        ),
      ],
    ),
  );
  controller.dispose();
  if (name == null || name.length < 2 || name == current) return;
  try {
    await ref.read(authControllerProvider.notifier).updateName(name);
  } catch (e) {
    if (context.mounted) showFailure(context, e);
  }
}

Future<void> showSmsSyncSheet(BuildContext context) => _sheet(context, const _SmsSyncSheet());

class _SmsSyncSheet extends ConsumerWidget {
  const _SmsSyncSheet();

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final inbox = ref.read(smsInboxServiceProvider);
    if (!inbox.isSupported) {
      showOobliSnack(context, 'SMS sync is available on Android only.');
      return;
    }
    if (!await inbox.hasPermission() && !await inbox.requestPermission()) {
      if (await inbox.isPermanentlyDenied()) await inbox.openSettings();
      return;
    }
    try {
      final added = await ref.read(smsSyncControllerProvider.notifier).sync();
      if (context.mounted) {
        showOobliSnack(context, added == 0 ? "You're all caught up!" : 'Imported $added new transactions');
      }
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final profile = ref.watch(authControllerProvider).value;
    final sync = ref.watch(smsSyncControllerProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('SMS Syncing', style: t.headlineSmall),
        const SizedBox(height: Sp.sm),
        Text(
          'Oobli reads only messages from M-Pesa and Kenyan banks to build your spending history. '
          'Personal chats are filtered out on your phone and never uploaded.',
          style: t.bodyMedium.copyWith(color: c.secondaryText),
        ),
        const SizedBox(height: Sp.lg),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('Auto-sync when I open Oobli', style: t.titleSmall),
          value: profile?.smsSyncEnabled ?? false,
          onChanged: (v) async {
            if (v && !await ref.read(smsInboxServiceProvider).requestPermission()) return;
            await ref.read(authControllerProvider.notifier).updateProfile((p) => p.copyWith(smsSyncEnabled: v));
          },
        ),
        if (profile?.lastSmsSyncAt != null)
          Text('Last synced ${Fmt.timeAgo(profile!.lastSmsSyncAt!)}', style: t.labelMedium.copyWith(color: c.secondaryText)),
        if (sync.phase == SyncPhase.failed && sync.message != null) ...[
          const SizedBox(height: Sp.sm),
          Text(sync.message!, style: t.bodySmall.copyWith(color: c.error)),
        ],
        const SizedBox(height: Sp.lg),
        OobliButton(
          label: 'Sync now',
          icon: Icons.sync_rounded,
          fullWidth: true,
          loading: sync.isSyncing,
          onPressed: () => _syncNow(context, ref),
        ),
      ],
    );
  }
}

Future<void> showAiBrainSheet(BuildContext context) => _sheet(context, const _AiBrainSheet());

class _AiBrainSheet extends ConsumerWidget {
  const _AiBrainSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final rules = ref.watch(merchantRulesProvider).value ?? const {};
    final entries = rules.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const OobliMascot(size: 40, glow: false, mood: MascotMood.thinking),
              const SizedBox(width: Sp.md),
              Expanded(child: Text('Oobli AI Brain', style: t.headlineSmall)),
            ],
          ),
          const SizedBox(height: Sp.sm),
          Text(
            'Every time you correct a category, Oobli remembers it for that merchant. '
            'Remove a rule to let the AI decide again.',
            style: t.bodyMedium.copyWith(color: c.secondaryText),
          ),
          const SizedBox(height: Sp.md),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.lg),
              child: Text('No learned rules yet.', textAlign: TextAlign.center, style: t.bodyMedium),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, i) {
                  final e = entries[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(e.value.icon, color: c.secondaryText),
                    title: Text(e.key, style: t.titleSmall),
                    subtitle: Text(e.value.label, style: t.bodySmall.copyWith(color: c.secondaryText)),
                    trailing: IconButton(
                      icon: Icon(Icons.close_rounded, color: c.secondaryText),
                      onPressed: () => ref.read(merchantRulesProvider.notifier).remove(e.key).catchError((Object err) {
                        if (context.mounted) showFailure(context, err);
                      }),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showPrivacySheet(BuildContext context) => _sheet(context, const _PrivacySheet());

class _PrivacySheet extends ConsumerWidget {
  const _PrivacySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    Widget point(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: Sp.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: c.primary, size: 20),
              const SizedBox(width: Sp.md),
              Expanded(child: Text(text, style: t.bodyMedium)),
            ],
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Privacy & Security', style: t.headlineSmall),
        const SizedBox(height: Sp.lg),
        point(Icons.filter_alt_rounded, 'Only SMS from M-Pesa and banks are read. Everything else is filtered on your phone.'),
        point(Icons.lock_rounded, 'Your transactions are stored in your private Appwrite account. Only you can read them.'),
        point(Icons.auto_awesome_rounded,
            'AI requests send spending summaries, not raw message history, and run on Oobli\'s secure server.'),
        point(Icons.key_rounded, 'No API keys or secrets live on your phone.'),
        const SizedBox(height: Sp.sm),
        OobliButton(
          label: 'Manage SMS permission',
          icon: Icons.settings_rounded,
          variant: OobliButtonVariant.outline,
          size: OobliButtonSize.medium,
          fullWidth: true,
          onPressed: () => ref.read(smsInboxServiceProvider).openSettings(),
        ),
      ],
    );
  }
}

Future<void> showThemeSheet(BuildContext context) => _sheet(context, const _ThemeSheet());

class _ThemeSheet extends ConsumerWidget {
  const _ThemeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    const options = [
      (ThemeMode.dark, 'Minimalist Dark', Icons.dark_mode_rounded),
      (ThemeMode.light, 'Minimalist Light', Icons.light_mode_rounded),
      (ThemeMode.system, 'Match my phone', Icons.phone_android_rounded),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('App Theme', style: context.text.headlineSmall),
        const SizedBox(height: Sp.lg),
        for (final (m, label, icon) in options) ...[
          ChoiceCard(
            title: label,
            icon: icon,
            selected: mode == m,
            onTap: () => ref.read(themeModeProvider.notifier).set(m),
          ),
          const SizedBox(height: Sp.md),
        ],
      ],
    );
  }
}

Future<void> showHelpSheet(BuildContext context) => _sheet(context, const _HelpSheet());

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  static const _faqs = [
    (
      'How does Oobli read my M-Pesa?',
      'With your permission, Oobli reads confirmation SMS from M-Pesa and your bank, extracts the amount, '
          'who you paid and when, then groups them into categories.'
    ),
    (
      'Why is a payment in the wrong category?',
      "Tap it and pick the right one. Keep 'Remember this category' on and Oobli will use it for that merchant from now on."
    ),
    (
      'What is the difference between Pochi, Till and Paybill?',
      'Pochi la Biashara is a small-business wallet on a phone number, Tills are Buy Goods numbers in shops, '
          'and Paybills are for bills like KPLC or rent. Oobli tracks each separately.'
    ),
    (
      'Can I use Oobli without SMS access?',
      'Yes. Add transactions manually with the + button. Plans, goals and Wrapped work the same way.'
    ),
    (
      'How is my plan created?',
      'Oobli\'s AI looks at your anticipated income, your main goal and your recent spending to split your money '
          'into needs, savings, flex spending and an emergency buffer. You can fine-tune it anytime.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Help Center', style: t.headlineSmall),
          const SizedBox(height: Sp.md),
          for (final (q, a) in _faqs)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                iconColor: c.primary,
                collapsedIconColor: c.secondaryText,
                title: Text(q, style: t.titleSmall),
                childrenPadding: const EdgeInsets.only(bottom: Sp.md),
                children: [Text(a, style: t.bodyMedium.copyWith(color: c.secondaryText))],
              ),
            ),
        ],
      ),
    );
  }
}
