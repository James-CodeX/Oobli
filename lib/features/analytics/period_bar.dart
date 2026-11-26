import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../domain/spending_stats.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/pressable.dart';

/// Segmented buttons for picking what a chart shows. "Month" and "Year" open
/// a short list to choose which one.
class PeriodBar extends ConsumerWidget {
  const PeriodBar({
    super.key,
    required this.value,
    required this.onChanged,
    this.options = PeriodKind.values,
    this.dense = false,
  });

  final Period value;
  final ValueChanged<Period> onChanged;
  final List<PeriodKind> options;

  /// Smaller buttons that share the width (for cards).
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = ref.watch(statsProvider).now;

    Future<void> pick(PeriodKind kind) async {
      HapticFeedback.selectionClick();
      final Future<Period?> next = switch (kind) {
        PeriodKind.today => Future.value(Period.today(now)),
        PeriodKind.yesterday => Future.value(Period.yesterday(now)),
        PeriodKind.week => Future.value(Period.week(now)),
        PeriodKind.sixMonths => Future.value(Period.sixMonths(now)),
        PeriodKind.month => _pickMonth(context, ref, value),
        PeriodKind.year => _pickYear(context, ref, value),
      };
      final picked = await next;
      if (picked != null && picked != value) onChanged(picked);
    }

    String label(PeriodKind kind) => switch (kind) {
          PeriodKind.today => 'Today',
          PeriodKind.yesterday => 'Yesterday',
          PeriodKind.week => 'This week',
          PeriodKind.sixMonths => '6 months',
          PeriodKind.month => value.kind == kind ? value.label(now) : 'Month',
          PeriodKind.year => value.kind == kind ? value.label(now) : 'Year',
        };

    final buttons = [
      for (final kind in options)
        _Segment(
          label: label(kind),
          selected: value.kind == kind,
          dropdown: kind == PeriodKind.month || kind == PeriodKind.year,
          dense: dense,
          onTap: () => pick(kind),
        ),
    ];

    final track = BoxDecoration(
      color: c.surfaceVariant.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(99),
    );
    if (dense) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: track,
        child: Row(children: [for (final b in buttons) Expanded(child: b)]),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: track,
        child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
      ),
    );
  }

  static Future<Period?> _pickMonth(BuildContext context, WidgetRef ref, Period current) {
    final stats = ref.read(statsProvider);
    final months = stats.spendingMonths();
    return _choose(
      context,
      title: 'Choose a month',
      items: [
        for (final m in months)
          (
            period: Period.month(m.month),
            title: m.month.year == stats.now.year ? Fmt.monthName(m.month) : Fmt.monthYear(m.month),
            amount: m.total,
          ),
      ],
      current: current,
    );
  }

  static Future<Period?> _pickYear(BuildContext context, WidgetRef ref, Period current) {
    final stats = ref.read(statsProvider);
    return _choose(
      context,
      title: 'Choose a year',
      items: [
        for (final y in stats.spendingYears())
          (
            period: Period.year(y),
            title: '$y',
            amount: stats.spentBetween(DateTime(y), DateTime(y + 1)),
          ),
      ],
      current: current,
    );
  }

  static Future<Period?> _choose(
    BuildContext context, {
    required String title,
    required List<({Period period, String title, double amount})> items,
    required Period current,
  }) {
    // One option: nothing to choose.
    if (items.length == 1) return Future.value(items.single.period);
    return showModalBottomSheet<Period>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final c = context.colors;
        final t = context.text;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.sm),
                child: Text(title, style: t.titleLarge),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: Sp.lg),
                  children: [
                    for (final item in items)
                      Pressable(
                        onTap: () => Navigator.pop(context, item.period),
                        scale: 0.99,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: t.bodyLarge.copyWith(
                                    fontWeight: item.period == current ? FontWeight.w700 : null,
                                    color: item.period == current ? c.primary : c.primaryText,
                                  ),
                                ),
                              ),
                              Text(
                                item.amount > 0 ? Fmt.kes(item.amount) : 'Nothing spent',
                                style: t.bodyMedium.copyWith(color: c.secondaryText),
                              ),
                              if (item.period == current) ...[
                                const SizedBox(width: Sp.sm),
                                Icon(Icons.check_rounded, size: 18, color: c.primary),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.dropdown,
    required this.dense,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool dropdown;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final fg = selected ? c.onPrimary : c.secondaryText;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: Motion.fast,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: dense ? Sp.sm : Sp.md, vertical: dense ? 6 : 8),
        decoration: BoxDecoration(
          color: selected ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.labelMedium.copyWith(color: fg, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
              ),
            ),
            if (dropdown) Icon(Icons.expand_more_rounded, size: 16, color: fg),
          ],
        ),
      ),
    );
  }
}
