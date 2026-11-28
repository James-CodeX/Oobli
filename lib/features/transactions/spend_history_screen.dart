import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/oobli_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/progress.dart';
import '../../ui/widgets/tiles.dart';
import 'transaction_editor_sheet.dart';
import 'transaction_widgets.dart';

/// Opens the list of every transaction matching [include], newest first,
/// where any of them can be re-filed with one tap.
Future<void> showSpendHistory(
  BuildContext context, {
  required String title,
  required String period,
  required IconData icon,
  required Tone tone,
  required bool Function(Transaction t) include,
  double? budget,
  bool breakdown = false,
}) =>
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
      builder: (_) => SpendHistoryScreen(
        title: title,
        period: period,
        icon: icon,
        tone: tone,
        include: include,
        budget: budget,
        breakdown: breakdown,
      ),
    ));

class SpendHistoryScreen extends ConsumerStatefulWidget {
  const SpendHistoryScreen({
    super.key,
    required this.title,
    required this.period,
    required this.icon,
    required this.tone,
    required this.include,
    this.budget,
    this.breakdown = false,
  });

  final String title;

  /// "November", "This week"…
  final String period;
  final IconData icon;
  final Tone tone;
  final bool Function(Transaction t) include;

  /// What the plan allows for this, if anything.
  final double? budget;

  /// Offer a filter per category (when the list mixes several).
  final bool breakdown;

  @override
  ConsumerState<SpendHistoryScreen> createState() => _SpendHistoryScreenState();
}

class _SpendHistoryScreenState extends ConsumerState<SpendHistoryScreen> {
  TxCategory? _only;
  String? _open;

  Future<void> _refile(Transaction tx, TxCategory category, {required bool everyOne}) async {
    HapticFeedback.mediumImpact();
    setState(() => _open = null);
    final controller = ref.read(transactionsProvider.notifier);
    final before = tx.category;
    try {
      if (everyOne) {
        final n = await controller.recategorizeMerchant(tx.merchant, category, direction: tx.direction);
        if (mounted) showOobliSnack(context, 'Moved $n from ${tx.merchant} to ${category.label}');
      } else {
        await controller.quickCategorize(tx, category);
        if (!mounted) return;
        showOobliSnack(
          context,
          '${tx.merchant} moved to ${category.label}',
          actionLabel: 'Undo',
          onAction: () => controller.quickCategorize(tx.copyWith(category: category), before),
        );
      }
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final all = ref.watch(statsProvider).all.where(widget.include).toList();
    final byCategory = <TxCategory, double>{};
    for (final tx in all) {
      byCategory[tx.category] = (byCategory[tx.category] ?? 0) + tx.amount;
    }
    final categories = byCategory.keys.toList()..sort((a, b) => byCategory[b]!.compareTo(byCategory[a]!));
    final only = categories.contains(_only) ? _only : null;
    final shown = only == null ? all : all.where((tx) => tx.category == only).toList();
    final total = all.fold<double>(0, (s, tx) => s + tx.amount);
    final budget = widget.budget;
    final accent = c.tone(widget.tone);

    // Group by day, newest first (the list is already sorted that way).
    final days = <DateTime, List<Transaction>>{};
    for (final tx in shown) {
      days.putIfAbsent(tx.occurredAt.dateOnly, () => []).add(tx);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(Sp.sm, MediaQuery.paddingOf(context).top + Sp.sm, Sp.lg, 0),
              child: Row(
                children: [
                  OobliIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: Sp.xs),
                  ToneTile(icon: widget.icon, tone: widget.tone, size: 36, soft: true),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: t.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          '${widget.period} · ${all.length} ${all.length == 1 ? 'payment' : 'payments'}',
                          style: t.bodySmall.copyWith(color: c.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Fmt.kes(total), style: t.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
                  if (budget != null && budget > 0) ...[
                    const SizedBox(height: Sp.sm),
                    OobliProgressBar(
                      value: total / budget,
                      color: total > budget ? c.error : accent,
                      height: 6,
                    ),
                    const SizedBox(height: Sp.xs),
                    Text(
                      total > budget
                          ? '${Fmt.kes(total - budget)} over the ${Fmt.kes(budget)} planned'
                          : '${Fmt.kes(budget - total)} left of ${Fmt.kes(budget)}',
                      style: t.labelMedium.copyWith(color: total > budget ? c.error : c.secondaryText),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (widget.breakdown && categories.length > 1)
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.md),
                child: Row(
                  children: [
                    _FilterChip(label: 'All', selected: only == null, onTap: () => setState(() => _only = null)),
                    for (final cat in categories)
                      _FilterChip(
                        label: '${cat.label} · ${Fmt.compactKes(byCategory[cat]!)}',
                        icon: cat.icon,
                        selected: only == cat,
                        onTap: () => setState(() => _only = only == cat ? null : cat),
                      ),
                  ],
                ),
              ),
            ),
          if (shown.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: 'Nothing here',
                message: 'No ${widget.title.toLowerCase()} ${widget.period.toLowerCase()} yet.',
              ),
            )
          else
            SliverList.list(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.sm),
                child: Text(
                  'Tap one to change its category',
                  style: t.labelMedium.copyWith(color: c.hint),
                ),
              ),
              for (final day in days.entries) ...[
                _DayHeader(day: day.key, total: day.value.fold(0, (s, tx) => s + tx.amount)),
                for (final tx in day.value)
                  _HistoryRow(
                    key: ValueKey(tx.id),
                    tx: tx,
                    open: _open == tx.id,
                    onToggle: () => setState(() => _open = _open == tx.id ? null : tx.id),
                    onPick: (cat, everyOne) => _refile(tx, cat, everyOne: everyOne),
                    onDetails: () => showTransactionEditor(context, tx: tx),
                  ),
              ],
              SizedBox(height: MediaQuery.paddingOf(context).bottom + Sp.xl),
            ]),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: Sp.sm),
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? c.primary : c.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? c.primary : c.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? c.onPrimary : c.secondaryText),
                const SizedBox(width: 6),
              ],
              Text(label, style: context.text.labelMedium.copyWith(color: selected ? c.onPrimary : c.primaryText)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.total});

  final DateTime day;
  final double total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final rel = Fmt.relativeDay(day);
    final name = rel == 'Today' || rel == 'Yesterday' ? rel : '${Fmt.weekdayName(day)}, ${Fmt.shortDate(day)}';
    return Container(
      color: c.secondaryBackground,
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(name, style: t.labelMedium.copyWith(color: c.secondaryText, fontWeight: FontWeight.w700))),
          Text(Fmt.kes(total), style: t.labelMedium.copyWith(color: c.secondaryText)),
        ],
      ),
    );
  }
}

/// A transaction that opens into category buttons when tapped.
class _HistoryRow extends ConsumerStatefulWidget {
  const _HistoryRow({
    super.key,
    required this.tx,
    required this.open,
    required this.onToggle,
    required this.onPick,
    required this.onDetails,
  });

  final Transaction tx;
  final bool open;
  final VoidCallback onToggle;
  final void Function(TxCategory category, bool everyOne) onPick;
  final VoidCallback onDetails;

  @override
  ConsumerState<_HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends ConsumerState<_HistoryRow> {
  bool _everyOne = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final tx = widget.tx;
    final key = Transaction.merchantKey(tx.merchant);
    final others = widget.open
        ? ref
            .read(statsProvider)
            .all
            .where((o) => o.id != tx.id && o.direction == tx.direction && Transaction.merchantKey(o.merchant) == key)
            .length
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pressable(
          onTap: widget.onToggle,
          scale: 0.99,
          semanticLabel: '${tx.merchant}, ${Fmt.kes(tx.amount)}, ${tx.label}',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
            child: Row(
              children: [
                ToneTile(icon: tx.category.icon, tone: tx.category.tone, size: 34, soft: true),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.merchant, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyLarge),
                      const SizedBox(height: 2),
                      Text(
                        '${tx.label} · ${Fmt.time12(tx.occurredAt)}',
                        style: t.labelSmall.copyWith(color: c.secondaryText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Sp.sm),
                Text(
                  Fmt.signedKes(tx.amount, outgoing: tx.isOutgoing),
                  style: t.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tx.isOutgoing ? c.primaryText : c.primary,
                  ),
                ),
                const SizedBox(width: Sp.xs),
                AnimatedRotation(
                  turns: widget.open ? 0.5 : 0,
                  duration: Motion.fast,
                  child: Icon(Icons.expand_more_rounded, size: 18, color: c.hint),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: Motion.medium,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !widget.open
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: Sp.sm,
                        runSpacing: Sp.sm,
                        children: [
                          for (final cat in categoryChoices(tx.direction))
                            CategoryChip(
                              category: cat,
                              selected: cat == tx.category,
                              inbound: !tx.isOutgoing,
                              onTap: () => cat == tx.category && !_everyOne ? widget.onToggle() : widget.onPick(cat, _everyOne),
                            ),
                        ],
                      ),
                      const SizedBox(height: Sp.sm),
                      Row(
                        children: [
                          if (others > 0)
                            Expanded(
                              child: Pressable(
                                onTap: () => setState(() => _everyOne = !_everyOne),
                                semanticLabel: 'Also change the other $others from ${tx.merchant}',
                                child: Row(
                                  children: [
                                    Icon(
                                      _everyOne ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                      size: 20,
                                      color: _everyOne ? c.primary : c.secondaryText,
                                    ),
                                    const SizedBox(width: Sp.xs),
                                    Flexible(
                                      child: Text(
                                        'Also the other $others from ${tx.merchant}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.labelMedium.copyWith(color: c.secondaryText),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          OobliLink('Details', onTap: widget.onDetails),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
        Divider(height: 1, indent: Sp.lg + 34 + Sp.md, color: c.divider),
      ],
    );
  }
}
