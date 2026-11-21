import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oobli_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../domain/spending_stats.dart';
import '../../state/insights_controller.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/charts.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/progress.dart';
import '../../ui/widgets/tiles.dart';
import '../assistant/ask_oobli_sheet.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  FlowRange range = FlowRange.week;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final stats = ref.watch(statsProvider);
    final period = stats.rangeFor(range);
    final channels = stats.byChannel(period.start, period.end);
    final categories = stats.byCategory(period.start, period.end);
    final periodTotal = channels.values.fold<double>(0, (s, v) => s + v);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: c.surface,
            padding: EdgeInsets.fromLTRB(Sp.lg, MediaQuery.paddingOf(context).top + Sp.md, Sp.lg, Sp.lg),
            child: Row(
              children: [
                OobliIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => context.pop()),
                const SizedBox(width: Sp.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Oobli Analytics', style: t.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: Sp.xs),
                      Text('Insights from your M-Pesa & Banks', style: t.bodySmall.copyWith(color: c.secondaryText)),
                    ],
                  ),
                ),
                Pressable(
                  onTap: () => showAskOobli(context),
                  semanticLabel: 'Ask Oobli',
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: c.secondaryBackground, shape: BoxShape.circle),
                    child: Icon(Icons.auto_awesome_rounded, color: c.onSurface),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Sp.lg),
            child: OobliCard(
              shadow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('Spending Flow', style: t.titleMedium),
                      const SizedBox(width: Sp.md),
                      Expanded(
                        child: _RangeDropdown(
                          value: range,
                          onChanged: (r) => setState(() => range = r),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.lg),
                  FlowLineChart(points: stats.series(range)),
                  const SizedBox(height: Sp.lg),
                  const Divider(),
                  const SizedBox(height: Sp.lg),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: Sp.sm,
                    crossAxisSpacing: Sp.sm,
                    childAspectRatio: 2.7,
                    children: [
                      for (final (label, channel, tone) in const [
                        ('Paybill', TxChannel.paybill, Tone.primary),
                        ('Tills', TxChannel.till, Tone.secondary),
                        ('Pochi', TxChannel.pochi, Tone.accent),
                        ('Send Money', TxChannel.send, Tone.warning),
                      ])
                        _ChannelChip(
                          label: label,
                          value: channels[channel] ?? 0,
                          share: periodTotal <= 0 ? 0 : (channels[channel] ?? 0) / periodTotal,
                          tone: tone,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Sp.lg),
          const _SuggestionPanel(),
          Padding(
            padding: const EdgeInsets.all(Sp.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Sp.md),
                Text('Distribution', style: t.titleMedium),
                const SizedBox(height: Sp.md),
                OobliCard(
                  radius: Rad.lg,
                  child: channels.isEmpty
                      ? const EmptyState(
                          title: 'Nothing here yet',
                          message: 'Spend data for this period will appear here.',
                        )
                      : Column(
                          children: [
                            DonutChart(
                              size: 132,
                              slices: _channelSlices(context, channels),
                              centerValue: Fmt.compactKes(periodTotal),
                              centerLabel: range.label.toLowerCase(),
                            ),
                            const SizedBox(height: Sp.lg),
                            for (final (i, e) in categories.entries.take(3).indexed) ...[
                              if (i > 0) const Divider(),
                              _CategoryRow(category: e.key, amount: e.value),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: Sp.xl),
                OobliButton(
                  label: 'Generate AI Spending Plan',
                  icon: Icons.auto_graph_rounded,
                  fullWidth: true,
                  onPressed: () => context.go(Routes.plans),
                ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + Sp.md),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<DonutSlice> _channelSlices(BuildContext context, Map<TxChannel, double> channels) {
    final c = context.colors;
    final palette = [c.primary, c.secondary, c.accent, c.warning];
    final top = channels.entries.take(3).toList();
    final rest = channels.entries.skip(3).fold<double>(0, (s, e) => s + e.value);
    return [
      for (final (i, e) in top.indexed) DonutSlice(label: e.key.label, value: e.value, color: palette[i]),
      if (rest > 0) DonutSlice(label: 'Other', value: rest, color: palette[3]),
    ];
  }
}

class _RangeDropdown extends StatelessWidget {
  const _RangeDropdown({required this.value, required this.onChanged});

  final FlowRange value;
  final ValueChanged<FlowRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.md),
      decoration: BoxDecoration(
        color: c.secondaryBackground,
        borderRadius: Rad.all(Rad.md),
        border: Border.all(color: c.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FlowRange>(
          value: value,
          isExpanded: true,
          dropdownColor: c.surface,
          borderRadius: Rad.all(Rad.md),
          icon: Icon(Icons.arrow_drop_down_rounded, color: c.secondaryText),
          style: context.text.bodyLarge.copyWith(color: c.primaryText),
          items: [for (final r in FlowRange.values) DropdownMenuItem(value: r, child: Text(r.label))],
          onChanged: (r) => r == null ? null : onChanged(r),
        ),
      ),
    );
  }
}

/// Compact channel stat: tinted tile with a share bar.
class _ChannelChip extends StatelessWidget {
  const _ChannelChip({required this.label, required this.value, required this.share, required this.tone});

  final String label;
  final double value;
  final double share;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final color = c.tone(tone);
    return Container(
      padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: Rad.all(Rad.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: t.labelSmall.copyWith(color: c.secondaryText))),
              Text('${(share * 100).round()}%', style: t.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(Fmt.compactKes(value), style: t.titleSmall.copyWith(fontWeight: FontWeight.w700)),
          OobliProgressBar(value: share, color: color, height: 3, trackColor: color.withValues(alpha: 0.15)),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.amount});

  final TxCategory category;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Pressable(
      onTap: () => context.push('${Routes.activity}?q=${Uri.encodeComponent(category.label)}'),
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.md),
        child: Row(
          children: [
            Icon(category.icon, color: context.colors.onSurface),
            const SizedBox(width: Sp.md),
            Expanded(child: Text(category.label, style: t.bodyLarge)),
            Text(Fmt.kes(amount), style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Full-width "Oobli says..." panel with an optional one-tap recategorisation.
class _SuggestionPanel extends ConsumerStatefulWidget {
  const _SuggestionPanel();

  @override
  ConsumerState<_SuggestionPanel> createState() => _SuggestionPanelState();
}

class _SuggestionPanelState extends ConsumerState<_SuggestionPanel> {
  bool _busy = false;

  Future<void> _apply() async {
    final s = ref.read(currentInsightsProvider).suggestion;
    if (s == null) return;
    setState(() => _busy = true);
    try {
      final n = await ref.read(transactionsProvider.notifier).recategorizeMerchant(s.merchant, s.to);
      await ref.read(insightsProvider.notifier).dismissSuggestion();
      if (mounted) showOobliSnack(context, 'Moved $n transactions to ${s.to.label}');
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
    final insights = ref.watch(currentInsightsProvider);
    final s = insights.suggestion;
    final fg = c.onPrimaryContainer;

    return Container(
      color: c.primaryContainer,
      padding: const EdgeInsets.all(Sp.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
            child: Text('O', style: t.headlineSmall.copyWith(color: c.onSurface, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Oobli says...', style: t.labelLarge.copyWith(color: fg, fontWeight: FontWeight.w700)),
                const SizedBox(height: Sp.sm),
                AnimatedSwitcher(
                  duration: Motion.medium,
                  child: Text(
                    s?.body ?? insights.analyticsNote,
                    key: ValueKey(s?.body ?? insights.analyticsNote),
                    style: t.bodyMedium.copyWith(color: fg),
                  ),
                ),
                if (s != null) ...[
                  const SizedBox(height: Sp.sm),
                  Wrap(
                    spacing: Sp.sm,
                    runSpacing: Sp.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OobliButton(
                        label: 'Yes, Recategorize',
                        size: OobliButtonSize.small,
                        loading: _busy,
                        onPressed: _apply,
                      ),
                      OobliButton(
                        label: 'Keep as ${s.from.label}',
                        variant: OobliButtonVariant.ghost,
                        size: OobliButtonSize.small,
                        onPressed: _busy ? null : () => ref.read(insightsProvider.notifier).dismissSuggestion(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
