import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oobli_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../state/auth_controller.dart';
import '../../state/goals_controller.dart';
import '../../state/preferences.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/tiles.dart';
import 'settings_sheets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final profile = ref.watch(authControllerProvider).value;
    if (profile == null) return const Scaffold();
    final stats = ref.watch(statsProvider);
    final rules = ref.watch(merchantRulesProvider).value ?? const {};
    final themeMode = ref.watch(themeModeProvider);
    final goals = ref.watch(goalsProvider).value ?? const [];
    final accuracy = stats.aiAccuracy(ref.watch(localStoreProvider).aiCorrections);
    final saved = goals.fold<double>(0, (s, g) => s + g.saved);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(Sp.lg, MediaQuery.paddingOf(context).top + Sp.sm, Sp.lg, Sp.lg),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: Shadows.sm,
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: OobliIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => context.pop()),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InitialsAvatar(name: profile.name, size: 72),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.surface, width: 3),
                        ),
                        child: Icon(Icons.check_rounded, size: 16, color: c.onSuccess),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.md),
                Pressable(
                  onTap: () => showEditNameDialog(context, ref, profile.name),
                  child: Text(profile.name, style: t.headlineSmall),
                ),
                const SizedBox(height: Sp.xs),
                Text(
                  'Oobli Member · since ${DateFormat('MMM yyyy').format(profile.createdAt)}',
                  style: t.labelLarge.copyWith(color: c.onSurface),
                ),
                const SizedBox(height: Sp.lg),
                Row(
                  children: [
                    _ProfileStat(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Streak',
                      value: '${profile.streak} ${profile.streak == 1 ? 'Day' : 'Days'}',
                    ),
                    const SizedBox(width: Sp.md),
                    _ProfileStat(icon: Icons.account_balance_wallet_rounded, label: 'Saved', value: Fmt.compactKes(saved)),
                    const SizedBox(width: Sp.md),
                    _ProfileStat(icon: Icons.auto_awesome_rounded, label: 'Accuracy', value: Fmt.percent(accuracy)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Sp.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionLabel('Financial Engine', padding: EdgeInsets.fromLTRB(Sp.xs, 0, Sp.xs, Sp.sm)),
                _SettingRow(
                  icon: Icons.message_rounded,
                  tone: Tone.primary,
                  title: 'SMS Syncing',
                  subtitle: !profile.smsSyncEnabled
                      ? 'Off · tap to import M-Pesa & Bank alerts'
                      : profile.lastSmsSyncAt == null
                          ? 'Managing M-Pesa & Bank alerts'
                          : 'Last synced ${Fmt.timeAgo(profile.lastSmsSyncAt!)}',
                  onTap: () => showSmsSyncSheet(context),
                ),
                _SettingRow(
                  icon: Icons.smart_toy_rounded,
                  tone: Tone.accent,
                  title: 'Oobli AI Brain',
                  subtitle: rules.isEmpty ? 'Categorization: Learning' : 'Categorization: ${rules.length} learned ${rules.length == 1 ? 'rule' : 'rules'}',
                  onTap: () => showAiBrainSheet(context),
                ),
                _SettingRow(
                  icon: Icons.security_rounded,
                  tone: Tone.success,
                  title: 'Privacy & Security',
                  subtitle: 'Only financial SMS · data private to you',
                  onTap: () => showPrivacySheet(context),
                ),
                const SizedBox(height: Sp.lg),
                const SectionLabel('Experience', padding: EdgeInsets.fromLTRB(Sp.xs, 0, Sp.xs, Sp.sm)),
                _SettingRow(
                  icon: Icons.notifications_active_rounded,
                  tone: Tone.warning,
                  title: 'Oobli Insights',
                  subtitle: profile.insightsEnabled ? 'Daily AI spending nudges' : 'Off · basic insights only',
                  trailing: Switch.adaptive(
                    value: profile.insightsEnabled,
                    onChanged: (v) => ref
                        .read(authControllerProvider.notifier)
                        .updateProfile((p) => p.copyWith(insightsEnabled: v))
                        .catchError((Object e) {
                      if (context.mounted) showFailure(context, e);
                    }),
                  ),
                ),
                _SettingRow(
                  icon: Icons.palette_rounded,
                  tone: Tone.secondary,
                  title: 'App Theme',
                  subtitle: switch (themeMode) {
                    ThemeMode.dark => 'Minimalist Dark',
                    ThemeMode.light => 'Minimalist Light',
                    ThemeMode.system => 'Match my phone',
                  },
                  onTap: () => showThemeSheet(context),
                ),
                _SettingRow(
                  icon: Icons.celebration_rounded,
                  tone: Tone.info,
                  title: 'Oobli Wrapped',
                  subtitle: 'Your monthly recap',
                  onTap: () => context.go(Routes.wrapped),
                ),
                const SizedBox(height: Sp.lg),
                const SectionLabel('Support', padding: EdgeInsets.fromLTRB(Sp.xs, 0, Sp.xs, Sp.sm)),
                Consumer(
                  builder: (context, ref, _) {
                    final replay = ref.watch(onboardingReplayProvider).enabled;
                    return _SettingRow(
                      icon: Icons.replay_rounded,
                      tone: Tone.primary,
                      title: 'Replay onboarding',
                      subtitle: replay
                          ? 'Plays next time you open Oobli, then turns off'
                          : 'Go through the intro and setup again',
                      trailing: Switch.adaptive(
                        value: replay,
                        onChanged: (v) {
                          ref.read(onboardingReplayProvider.notifier).setEnabled(v);
                          if (v) showOobliSnack(context, 'Onboarding will play next time you open Oobli');
                        },
                      ),
                    );
                  },
                ),
                _SettingRow(
                  icon: Icons.help_outline_rounded,
                  tone: Tone.neutral,
                  title: 'Help Center',
                  subtitle: 'FAQs and how Oobli works',
                  onTap: () => showHelpSheet(context),
                ),
                _SettingRow(
                  icon: Icons.logout_rounded,
                  tone: Tone.error,
                  title: 'Sign Out',
                  showChevron: false,
                  onTap: () async {
                    final ok = await confirmAction(
                      context,
                      title: 'Sign out?',
                      message: 'Your data stays safe in your account. Log back in anytime.',
                      confirmLabel: 'Sign Out',
                      destructive: true,
                    );
                    if (!ok) return;
                    try {
                      await ref.read(authControllerProvider.notifier).logout();
                    } catch (e) {
                      if (context.mounted) showFailure(context, e);
                    }
                  },
                ),
                const SizedBox(height: Sp.xl),
                Text('Oobli v${ref.watch(appVersionProvider).value ?? '…'}', textAlign: TextAlign.center,
                    style: t.labelSmall.copyWith(color: c.secondaryText)),
                const SizedBox(height: Sp.xs),
                Text('Made with ❤️ in Nairobi', textAlign: TextAlign.center,
                    style: t.labelSmall.copyWith(color: c.secondaryText)),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + Sp.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Sp.md, horizontal: Sp.sm),
        decoration: BoxDecoration(
          borderRadius: Rad.all(Rad.lg),
          border: Border.all(color: c.outline, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: c.primary),
                const SizedBox(width: Sp.xs),
                Text(label, style: t.labelMedium.copyWith(color: c.secondaryText, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: Sp.xs),
            FittedBox(child: Text(value, style: t.titleLarge)),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.tone,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showChevron = true,
  });

  final IconData icon;
  final Tone tone;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.sm),
      child: Pressable(
        onTap: onTap,
        scale: 0.98,
        semanticLabel: title,
        child: OobliCard(
          radius: Rad.lg,
          padding: const EdgeInsets.all(Sp.md),
          child: Row(
            children: [
              ToneTile(icon: icon, tone: tone, size: 40, radius: Rad.md),
              const SizedBox(width: Sp.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.titleMedium.copyWith(color: tone == Tone.error ? c.error : null)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: t.labelMedium.copyWith(color: c.secondaryText, fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ),
              ?trailing,
              if (trailing == null && showChevron) Icon(Icons.chevron_right_rounded, color: c.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
