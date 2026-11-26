import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oobli_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/ai_models.dart';
import '../../data/models/category.dart';
import '../../state/wrapped_controller.dart';
import '../../ui/widgets/charts.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/tiles.dart';

/// "Oobli Wrapped": the monthly recap story.
class WrappedScreen extends ConsumerWidget {
  const WrappedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(wrappedProvider);
    final month = ref.watch(wrappedMonthProvider);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(month: month, data: data.value),
          data.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Sp.lg),
              child: Column(
                children: [
                  SkeletonBox(height: 60, width: 220),
                  SizedBox(height: Sp.xl),
                  SkeletonBox(height: 140, radius: Rad.lg),
                  SizedBox(height: Sp.lg),
                  SkeletonBox(height: 240, radius: Rad.lg),
                ],
              ),
            ),
            error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(wrappedProvider)),
            data: (d) => d.recap.isEmpty
                ? EmptyState(
                    title: 'Your story is still being written',
                    message: 'Once Oobli sees some spending this month, your Wrapped appears here.',
                    mood: MascotMood.sleeping,
                    action: OobliButton(
                      label: 'Go to Oobli Says',
                      size: OobliButtonSize.medium,
                      onPressed: () => context.go(Routes.feed),
                    ),
                  )
                : _Body(data: d),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.month, required this.data});

  final DateTime month;
  final WrappedData? data;

  void _share(BuildContext context) {
    final d = data;
    if (d == null || d.recap.isEmpty) return;
    final top = d.recap.categories.entries.take(3).map((e) => '• ${e.key.label}: ${Fmt.kes(e.value)}').join('\n');
    SharePlus.instance.share(ShareParams(
      subject: 'My Oobli Wrapped · ${Fmt.monthYear(month)}',
      text: 'My Oobli Wrapped for ${Fmt.monthYear(month)} 🎉\n'
          'I handled ${Fmt.kes(d.recap.total)} across ${d.recap.transactionCount} transactions.\n\n'
          'Where it went:\n$top\n\n${d.story.winBody}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: EdgeInsets.fromLTRB(Sp.lg, MediaQuery.paddingOf(context).top + Sp.md, Sp.lg, Sp.xl),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.primary, c.accent],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OobliIconButton(
                icon: Icons.close_rounded,
                color: Colors.black,
                tooltip: 'Close',
                onPressed: () => context.go(Routes.feed),
              ),
              OobliIconButton(
                icon: Icons.share_rounded,
                color: Colors.black,
                tooltip: 'Share',
                onPressed: () => _share(context),
              ),
            ],
          ),
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: const OobliMascot(size: 64, glow: false, mood: MascotMood.party),
          ),
          const SizedBox(height: Sp.lg),
          Text(
            'Oobli Wrapped',
            style: t.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800, shadows: const [
              Shadow(color: Color(0x33000000), offset: Offset(0, 2)),
            ]),
          ),
          const SizedBox(height: Sp.xs),
          Text(
            Fmt.monthYear(month).toUpperCase(),
            style: t.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});

  final WrappedData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final recap = data.recap;
    final story = data.story;
    final top = recap.categories.entries.take(3).toList();
    final rest = recap.categories.entries.skip(3).fold<double>(0, (s, e) => s + e.value);
    final rankColors = [c.primary, c.accent, c.secondary];
    final nextMonth = DateTime(recap.month.year, recap.month.month + 1);

    return Padding(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('You handled', textAlign: TextAlign.center, style: t.bodyMedium.copyWith(color: c.secondaryText)),
          const SizedBox(height: Sp.md),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: recap.total),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              Fmt.kes(v),
              textAlign: TextAlign.center,
              style: t.headlineLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 32),
            ),
          ),
          const SizedBox(height: Sp.md),
          for (final badge in story.badges) ...[
            _BadgePill(badge: badge),
            const SizedBox(height: Sp.sm),
          ],
          const SizedBox(height: Sp.lg),
          OobliCard(
            radius: Rad.lg,
            color: c.surfaceVariant,
            borderColor: c.outline,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ToneTile(icon: Icons.psychology_rounded, tone: Tone.primary, size: 40, radius: Rad.md),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Oobli says...', style: t.titleMedium),
                      const SizedBox(height: Sp.sm),
                      Text(story.insight, style: t.bodyMedium.copyWith(color: c.secondaryText)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Sp.xl),
          Text('Where it went', style: t.titleLarge),
          const SizedBox(height: Sp.md),
          for (final (i, e) in top.indexed) ...[
            _CategoryRank(category: e.key, amount: e.value, color: rankColors[i]),
            const SizedBox(height: Sp.md),
          ],
          const SizedBox(height: Sp.md),
          OobliCard(
            radius: Rad.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spending Flow', style: t.titleMedium),
                const SizedBox(height: Sp.lg),
                Center(
                  child: DonutChart(
                    size: 140,
                    legend: LegendPosition.bottom,
                    centerValue: Fmt.compactKes(recap.total),
                    centerLabel: 'spent',
                    slices: [
                      for (final (i, e) in top.indexed)
                        DonutSlice(label: e.key.label.split(' ').first, value: e.value, color: rankColors[i]),
                      if (rest > 0) DonutSlice(label: 'Other', value: rest, color: c.surfaceVariant),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Sp.xl),
          OobliCard(
            radius: Rad.lg,
            color: c.success.withValues(alpha: 0.1),
            borderColor: c.success.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded, size: 32, color: c.onSurface),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(story.winTitle, style: t.titleSmall.copyWith(color: c.onSurface)),
                      const SizedBox(height: Sp.xs),
                      Text(story.winBody, style: t.bodySmall.copyWith(color: c.primaryText)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Sp.xl),
          OobliButton(
            label: 'View Full Breakdown',
            variant: OobliButtonVariant.outline,
            size: OobliButtonSize.medium,
            fullWidth: true,
            onPressed: () => context.push(Routes.analytics),
          ),
          const SizedBox(height: Sp.md),
          OobliButton(
            label: 'Update ${Fmt.monthName(nextMonth)} Plan',
            icon: Icons.arrow_forward_rounded,
            size: OobliButtonSize.medium,
            fullWidth: true,
            onPressed: () => context.go(Routes.plans),
          ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.badge});

  final WrappedBadge badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (IconData icon, Color color) = switch (badge.icon) {
      'saver' => (Icons.eco_rounded, c.success),
      'power' => (Icons.bolt_rounded, c.warning),
      'streak' => (Icons.local_fire_department_rounded, c.warning),
      'shield' => (Icons.shield_rounded, c.info),
      'trend' => (Icons.trending_down_rounded, c.success),
      _ => (Icons.star_rounded, c.accent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(99)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c.onSurface),
          const SizedBox(width: Sp.sm),
          Text(badge.label, style: context.text.labelMedium.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
        ],
      ),
    );
  }
}

class _CategoryRank extends StatelessWidget {
  const _CategoryRank({required this.category, required this.amount, required this.color});

  final TxCategory category;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable(
      onTap: () => context.push('${Routes.activity}?q=${Uri.encodeComponent(category.label)}'),
      scale: 0.98,
      child: OobliCard(
        radius: Rad.lg,
        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.lg),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(category.icon, size: 18, color: Colors.black.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.label, style: t.titleMedium),
                  const SizedBox(height: Sp.xs),
                  Text(Fmt.kes(amount), style: t.bodyMedium.copyWith(color: c.secondaryText)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.secondaryText),
          ],
        ),
      ),
    );
  }
}
