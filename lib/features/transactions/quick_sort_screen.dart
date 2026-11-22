import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/oobli_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../state/preferences.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/tiles.dart';
import 'transaction_editor_sheet.dart';
import 'transaction_widgets.dart';

/// Quick sort: one tap per transaction. The open card shows every category;
/// tapping one files it (saved in the background), collapses the card and
/// opens the next unsorted one.
class QuickSortScreen extends ConsumerStatefulWidget {
  const QuickSortScreen({super.key});

  @override
  ConsumerState<QuickSortScreen> createState() => _QuickSortScreenState();
}

class _QuickSortScreenState extends ConsumerState<QuickSortScreen> {
  /// Ids to sort this session, newest first. Fixed when the screen opens so
  /// sorted cards stay in place instead of jumping out of the list.
  List<String>? _queue;
  String? _openId;
  late bool _remember = ref.read(localStoreProvider).quickSortRemember;
  final _keys = <String, GlobalKey>{};

  void _ensureQueue(List<Transaction> txs) {
    if (_queue != null) return;
    _queue = [for (final t in txs) if (!t.confirmed) t.id];
    _openId = _queue!.firstOrNull;
  }

  /// The first unsorted transaction after [fromId], wrapping to the top.
  String? _nextUnsorted(Map<String, Transaction> byId, String fromId) {
    final queue = _queue!;
    final start = queue.indexOf(fromId);
    for (var step = 1; step <= queue.length; step++) {
      final id = queue[(start + step) % queue.length];
      final tx = byId[id];
      if (tx != null && !tx.confirmed && id != fromId) return id;
    }
    return null;
  }

  void _open(String? id) {
    setState(() => _openId = id);
    if (id == null) return;
    // Let the previous card finish collapsing, then bring this one up.
    Future.delayed(Motion.medium, () {
      final ctx = _keys[id]?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, alignment: 0.08, duration: Motion.medium, curve: Curves.easeOutCubic);
      }
    });
  }

  void _pick(Transaction tx, TxCategory category, Map<String, Transaction> byId) {
    HapticFeedback.selectionClick();
    // Same-merchant spends that "remember" will sort too: skip past them.
    final key = Transaction.merchantKey(tx.merchant);
    final autoSorted = <String, Transaction>{
      for (final e in byId.entries)
        e.key: _remember &&
                TransactionsController.canLearn(tx, category) &&
                e.value.direction == tx.direction &&
                !e.value.confirmed &&
                Transaction.merchantKey(e.value.merchant) == key
            ? e.value.copyWith(confirmed: true)
            : e.value,
      tx.id: tx.copyWith(confirmed: true),
    };
    _open(_nextUnsorted(autoSorted, tx.id));

    ref
        .read(transactionsProvider.notifier)
        .quickCategorize(tx, category, remember: _remember)
        .then((count) {
      if (mounted && count > 1) {
        showOobliSnack(context, '${tx.merchant}: ${count - 1} more filed under ${category.label}');
      }
    }).catchError((Object e) {
      if (!mounted) return;
      showFailure(context, e);
      _open(tx.id);
    });
  }

  void _setRemember(bool value) {
    setState(() => _remember = value);
    ref.read(localStoreProvider).setQuickSortRemember(value);
  }

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(transactionsProvider);
    return Scaffold(
      body: txs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => SafeArea(
          child: ErrorRetry(error: e, onRetry: () => ref.invalidate(transactionsProvider)),
        ),
        data: (list) {
          _ensureQueue(list);
          final byId = {for (final t in list) t.id: t};
          final items = [for (final id in _queue!) ?byId[id]];
          final sorted = items.where((t) => t.confirmed).length;
          return Column(
            children: [
              _Header(
                total: items.length,
                sorted: sorted,
                remember: _remember,
                onRemember: _setRemember,
              ),
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        title: 'Nothing to sort',
                        message: 'Every transaction has a category. New M-Pesa messages land here when Oobli needs you.',
                        mood: MascotMood.joy,
                        action: OobliButton(label: 'Done', onPressed: () => context.pop()),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, Sp.xxl + MediaQuery.paddingOf(context).bottom),
                        itemCount: items.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return sorted == items.length
                                ? _AllSorted(count: items.length, onDone: () => context.pop())
                                : const SizedBox.shrink();
                          }
                          final tx = items[i - 1];
                          return Padding(
                            key: _keys.putIfAbsent(tx.id, GlobalKey.new),
                            padding: const EdgeInsets.only(bottom: Sp.sm),
                            child: _SortCard(
                              tx: tx,
                              open: tx.id == _openId,
                              onOpen: () => _open(tx.id == _openId ? null : tx.id),
                              onPick: (cat) => _pick(tx, cat, byId),
                              onSkip: () => _open(_nextUnsorted(byId, tx.id)),
                              onDetails: () => showTransactionEditor(context, tx: tx),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.sorted, required this.remember, required this.onRemember});

  final int total;
  final int sorted;
  final bool remember;
  final ValueChanged<bool> onRemember;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final left = total - sorted;
    return Container(
      decoration: BoxDecoration(color: c.surface, border: Border(bottom: BorderSide(color: c.divider))),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.lg, Sp.md),
          child: Column(
            children: [
              Row(
                children: [
                  OobliIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => context.pop()),
                  const SizedBox(width: Sp.xs),
                  Expanded(child: Text('Quick sort', style: t.titleLarge.copyWith(fontSize: 17))),
                  if (total > 0)
                    Text(
                      left == 0 ? 'All done' : '$left left',
                      style: t.labelLarge.copyWith(color: left == 0 ? c.primary : c.secondaryText),
                    ),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: Sp.sm),
                Padding(
                  padding: const EdgeInsets.only(left: Sp.sm),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: sorted / total),
                      duration: Motion.medium,
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        color: c.primary,
                        backgroundColor: c.surfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Sp.sm),
                Padding(
                  padding: const EdgeInsets.only(left: Sp.sm),
                  child: Row(
                    children: [
                      Icon(Icons.auto_fix_high_rounded, size: 18, color: remember ? c.primary : c.secondaryText),
                      const SizedBox(width: Sp.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Remember for this merchant', style: t.labelLarge),
                            Text(
                              'Also sorts their other transactions and future ones',
                              style: t.labelSmall.copyWith(color: c.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(value: remember, onChanged: onRemember),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SortCard extends StatelessWidget {
  const _SortCard({
    required this.tx,
    required this.open,
    required this.onOpen,
    required this.onPick,
    required this.onSkip,
    required this.onDetails,
  });

  final Transaction tx;
  final bool open;
  final VoidCallback onOpen;
  final ValueChanged<TxCategory> onPick;
  final VoidCallback onSkip;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final done = tx.confirmed;
    final tone = c.tone(tx.category.tone);

    final status = done
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 14, color: c.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(tx.category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelMedium.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          )
        : Text(
            tx.aiCategorized ? 'Oobli guessed ${tx.category.label}' : 'Guess: ${tx.category.label}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.labelMedium.copyWith(color: c.secondaryText),
          );

    return AnimatedContainer(
      duration: Motion.medium,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: Rad.all(Rad.lg),
        border: Border.all(color: open ? c.primary : c.divider, width: open ? 1.5 : 1),
        boxShadow: open ? Shadows.sm : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: onOpen,
            scale: 0.99,
            semanticLabel: '${tx.merchant}, ${Fmt.kes(tx.amount)}',
            child: Padding(
              padding: const EdgeInsets.all(Sp.md),
              child: Row(
                children: [
                  AnimatedOpacity(
                    duration: Motion.medium,
                    opacity: done && !open ? 0.6 : 1,
                    child: ToneTile(icon: tx.category.icon, tone: tx.category.tone, size: 36, radius: Rad.md, soft: !done),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.merchant, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                        const SizedBox(height: 2),
                        status,
                      ],
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Fmt.signedKes(tx.amount, outgoing: tx.isOutgoing, spaced: false),
                        style: t.titleSmall.copyWith(color: tx.isOutgoing ? c.primaryText : c.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Fmt.relativeDay(tx.occurredAt)} · ${Fmt.time12(tx.occurredAt)}',
                        style: t.labelSmall.copyWith(color: c.hint),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.medium,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, Sp.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Divider(color: tone.withValues(alpha: 0.2), height: 1),
                        const SizedBox(height: Sp.md),
                        Wrap(
                          spacing: Sp.sm,
                          runSpacing: Sp.sm,
                          children: [
                            for (final cat in categoryChoices(tx.direction))
                              CategoryChip(
                                category: cat,
                                selected: cat == tx.category,
                                onTap: () => onPick(cat),
                              ),
                          ],
                        ),
                        const SizedBox(height: Sp.sm),
                        Row(
                          children: [
                            _TextAction(label: 'Details', icon: Icons.tune_rounded, onTap: onDetails),
                            const Spacer(),
                            if (!done) _TextAction(label: 'Skip', icon: Icons.skip_next_rounded, onTap: onSkip),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.xs, horizontal: Sp.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: c.secondaryText),
            const SizedBox(width: 4),
            Text(label, style: context.text.labelMedium.copyWith(color: c.secondaryText)),
          ],
        ),
      ),
    );
  }
}

class _AllSorted extends StatelessWidget {
  const _AllSorted({required this.count, required this.onDone});

  final int count;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.md),
      child: OobliCard(
        color: c.primaryContainer,
        borderColor: Colors.transparent,
        padding: const EdgeInsets.all(Sp.md),
        child: Row(
          children: [
            const OobliMascot(size: 48, mood: MascotMood.joy),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All sorted!', style: t.titleMedium.copyWith(color: c.onPrimaryContainer)),
                  Text(
                    '$count ${count == 1 ? 'transaction' : 'transactions'} filed. Tap any card to change it.',
                    style: t.bodySmall.copyWith(color: c.onPrimaryContainer),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Sp.sm),
            OobliButton(label: 'Done', size: OobliButtonSize.small, onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
