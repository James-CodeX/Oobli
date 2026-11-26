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
    final ready = data != null && !data!.recap.isEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(Sp.lg, MediaQuery.paddingOf(context).top + Sp.md, Sp.lg, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OobliIconButton(
                icon: Icons.close_rounded,
                color: c.secondaryText,
                tooltip: 'Close',
                onPressed: () => context.go(Routes.feed),
              ),
              if (ready)
                OobliIconButton(
                  icon: Icons.ios_share_rounded,
                  color: c.secondaryText,
                  tooltip: 'Share',
                  onPressed: () => _share(context),
                ),
            ],
          ),
          const OobliMascot(size: 120, glow: false, mood: MascotMood.party, interactive: true),
          const SizedBox(height: Sp.md),
          Text(
            'Oobli Wrapped',
            style: t.labelLarge.copyWith(color: c.primary, fontWeight: FontWeight.w700, letterSpacing: 0.4),
          ),
          const SizedBox(height: Sp.xs),
          Text(
            Fmt.monthYear(month),
            textAlign: TextAlign.center,
            style: t.headlineMedium.copyWith(fontWeight: FontWeight.w800),
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
    final top = recap.categories.entries.take(4).toList();
    final rest = recap.categories.entries.skip(4).fold<double>(0, (s, e) => s + e.value);
    final nextMonth = DateTime(recap.month.year, recap.month.month + 1);
    final previousMonth = DateTime(recap.month.year, recap.month.month - 1);
    final change = recap.total - recap.previousTotal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.xl, Sp.lg, Sp.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The headline number.
          Text('You spent', textAlign: TextAlign.center, style: t.bodyLarge.copyWith(color: c.secondaryText)),
          const SizedBox(height: Sp.xs),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: recap.total),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              Fmt.kes(v),
              textAlign: TextAlign.center,
              style: t.headlineLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 36),
            ),
          ),
          const SizedBox(height: Sp.xs),
          Text(
            [
              'across ${recap.transactionCount} ${recap.transactionCount == 1 ? 'payment' : 'payments'}',
              if (recap.previousTotal > 0)
                '${Fmt.kes(change.abs())} ${change <= 0 ? 'less' : 'more'} than ${Fmt.monthName(previousMonth)}',
            ].join(' · '),
            textAlign: TextAlign.center,
            style: t.bodyMedium.copyWith(color: c.secondaryText),
          ),
          if (story.badges.isNotEmpty) ...[
            const SizedBox(height: Sp.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Sp.sm,
              runSpacing: Sp.sm,
              children: [for (final badge in story.badges) _BadgePill(badge: badge)],
            ),
          ],
          const SizedBox(height: Sp.xl),
          OobliSaysCard(centered: true, message: story.insight),
          const SizedBox(height: Sp.xl),

          // Where it went.
          Text('Where it went', style: t.titleLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: Sp.md),
          OobliCard(
            radius: Rad.lg,
            padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.sm),
            child: Column(
              children: [
                for (final (i, e) in top.indexed) ...[
                  if (i > 0) Divider(height: 1, color: c.divider),
                  _CategoryShare(category: e.key, amount: e.value, total: recap.total),
                ],
                if (rest > 0) ...[
                  Divider(height: 1, color: c.divider),
                  _CategoryShare(amount: rest, total: recap.total),
                ],
              ],
            ),
          ),
          const SizedBox(height: Sp.xl),

          // The month's win.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ToneTile(icon: Icons.emoji_events_rounded, tone: Tone.primary, size: 40, radius: Rad.md, soft: true),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(story.winTitle, style: t.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: Sp.xs),
                    Text(story.winBody, style: t.bodyMedium.copyWith(color: c.secondaryText, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.xxl),
          OobliButton(
            label: 'Plan ${Fmt.monthName(nextMonth)}',
            fullWidth: true,
            onPressed: () => context.go(Routes.plans),
          ),
          const SizedBox(height: Sp.sm),
          OobliButton(
            label: 'See the full breakdown',
            variant: OobliButtonVariant.ghost,
            size: OobliButtonSize.medium,
            fullWidth: true,
            onPressed: () => context.push(Routes.analytics),
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
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.outline),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: Sp.xs),
          Text(badge.label, style: context.text.labelMedium.copyWith(fontWeight: FontWeight.w600, color: c.primaryText)),
        ],
      ),
    );
  }
}

/// One line of "Where it went": the category, what it cost and a thin bar
/// for its share of the month. Without [category] it's the "Other" line.
class _CategoryShare extends StatelessWidget {
  const _CategoryShare({this.category, required this.amount, required this.total});

  final TxCategory? category;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final cat = category;
    final share = total <= 0 ? 0.0 : (amount / total).clamp(0.0, 1.0);
    final color = cat == null ? c.secondaryText : c.tone(cat.tone);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.md),
      child: Row(
        children: [
          cat == null
              ? ToneTile(icon: Icons.more_horiz_rounded, tone: Tone.neutral, size: 36, radius: Rad.md, soft: true)
              : ToneTile(icon: cat.icon, tone: cat.tone, size: 36, radius: Rad.md, soft: true),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(cat?.label ?? 'Everything else',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                    ),
                    Text(Fmt.kes(amount), style: t.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: Sp.sm),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: share,
                          minHeight: 4,
                          color: color,
                          backgroundColor: c.surfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: Sp.md),
                    SizedBox(
                      width: 36,
                      child: Text('${(share * 100).round()}%',
                          textAlign: TextAlign.end, style: t.labelMedium.copyWith(color: c.secondaryText)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (cat == null) return row;
    return Pressable(
      onTap: () => context.push('${Routes.activity}?q=${Uri.encodeComponent(cat.label)}'),
      scale: 0.98,
      child: row,
    );
  }
}
