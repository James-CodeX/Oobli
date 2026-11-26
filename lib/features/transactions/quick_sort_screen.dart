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
import '../../domain/sorting.dart';
import '../../state/preferences.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/mascot.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/tiles.dart';
import 'similar_sheet.dart';
import 'transaction_editor_sheet.dart';
import 'transaction_widgets.dart';

/// Quick sort: one tap per transaction. The open card shows every category;
/// tapping one files it (instantly, uploaded in the background), collapses
/// the card and opens the next one.
///
/// It shows what Oobli couldn't file on its own from the **last 7 days**,
/// newest first, with big spends flagged. Older ones are one tab away (with
/// "keep Oobli's guesses" to clear them in one go), and search finds any
/// transaction, sorted or not, to file it again.
class QuickSortScreen extends ConsumerStatefulWidget {
  const QuickSortScreen({super.key, this.focusId});

  /// Opens this transaction first (e.g. the "big one today" from home).
  final String? focusId;

  @override
  ConsumerState<QuickSortScreen> createState() => _QuickSortScreenState();
}

enum _Scope { recent, older }

class _QuickSortScreenState extends ConsumerState<QuickSortScreen> {
  _Scope _scope = _Scope.recent;
  final _search = TextEditingController();
  String _query = '';

  /// Filed by the user on this screen: they stay in the list (ticked) so
  /// the list doesn't jump; anything Oobli files on its own just leaves.
  final _sortedHere = <String>{};
  String? _openId;
  bool _started = false;
  late bool _remember = ref.read(localStoreProvider).quickSortRemember;
  final _keys = <String, GlobalKey>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _searching => _query.trim().isNotEmpty;

  List<Transaction> _items(List<Transaction> all, DateTime now) {
    if (_searching) return SortQueue.search(all, _query, now);
    final recent = _scope == _Scope.recent;
    final focus = widget.focusId;
    return [
      for (final t in all)
        if ((!t.confirmed || _sortedHere.contains(t.id) || t.id == focus) && SortQueue.isRecent(t, now) == recent) t,
    ];
  }

  /// The first unsorted item after [fromId] (wrapping), skipping [skip].
  String? _nextUnsorted(List<Transaction> items, String fromId, {bool Function(Transaction t)? skip}) {
    final start = items.indexWhere((t) => t.id == fromId);
    for (var step = 1; step <= items.length; step++) {
      final t = items[(start + step) % items.length];
      if (t.id != fromId && !t.confirmed && !_sortedHere.contains(t.id) && !(skip?.call(t) ?? false)) return t.id;
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

  void _setScope(_Scope scope) {
    if (scope == _scope) return;
    setState(() {
      _scope = scope;
      _openId = null;
      _started = false; // open the first card of the new list
    });
  }

  void _pick(Transaction tx, TxCategory category, List<Transaction> items) {
    HapticFeedback.selectionClick();
    // Same-merchant ones that "remember" will file too: skip past them.
    final key = Transaction.merchantKey(tx.merchant);
    final learns = _remember && TransactionsController.canLearn(tx, category);
    final next = _nextUnsorted(items, tx.id,
        skip: (t) => learns && t.direction == tx.direction && Transaction.merchantKey(t.merchant) == key);
    _sortedHere.add(tx.id);
    _open(next);

    ref.read(transactionsProvider.notifier).quickCategorize(tx, category, remember: _remember).then((count) {
      if (!mounted) return;
      if (count > 1) {
        showOobliSnack(context, '${tx.merchant}: ${count - 1} more filed under ${category.label}');
      }
      // A correction may apply to other merchants too ("other matatu SACCOs").
      if (category != tx.category) offerSimilar(context, tx, category);
    }).catchError((Object e) {
      if (mounted) showFailure(context, e);
    });
  }

  void _keepGuesses(List<Transaction> items) {
    final waiting = [for (final t in items) if (!t.confirmed) t];
    final count = ref.read(transactionsProvider.notifier).acceptGuesses(waiting);
    _sortedHere.addAll(waiting.map((t) => t.id));
    HapticFeedback.mediumImpact();
    setState(() => _openId = null);
    showOobliSnack(context, 'Kept Oobli\'s guesses for $count ${count == 1 ? 'transaction' : 'transactions'}');
  }

  void _setRemember(bool value) {
    setState(() => _remember = value);
    ref.read(localStoreProvider).setQuickSortRemember(value);
  }

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(transactionsProvider);
    final big = ref.watch(bigAmountProvider);
    final auto = ref.watch(autoSortStatusProvider);
    return Scaffold(
      body: txs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => SafeArea(
          child: ErrorRetry(error: e, onRetry: () => ref.invalidate(transactionsProvider)),
        ),
        data: (list) {
          final now = DateTime.now();
          final items = _items(list, now);
          if (!_started) {
            _started = true;
            final focus = widget.focusId;
            _openId = focus != null && items.any((t) => t.id == focus)
                ? focus
                : items.where((t) => !t.confirmed).firstOrNull?.id;
          }
          final recentLeft = SortQueue.recent(list, now).length;
          final olderLeft = SortQueue.older(list, now).length;
          final sorted = items.where((t) => t.confirmed).length;
          final left = items.length - sorted;

          Widget? top;
          if (_searching) {
            top = null;
          } else if (_scope == _Scope.older && left > 0) {
            top = _KeepGuessesCard(count: left, onKeep: () => _keepGuesses(items));
          } else if (items.isNotEmpty && left == 0) {
            top = _AllSorted(count: items.length, onDone: () => context.pop());
          }

          return Column(
            children: [
              _Header(
                search: _search,
                onQuery: (q) => setState(() {
                  _query = q;
                  _openId = null;
                  _started = q.trim().isEmpty ? false : _started;
                }),
                scope: _searching ? null : _scope,
                recentLeft: recentLeft,
                olderLeft: olderLeft,
                onScope: _setScope,
                total: _searching ? 0 : items.length,
                sorted: sorted,
                remember: _remember,
                onRemember: _setRemember,
                autoSorting: auto.running ? auto.asking : 0,
              ),
              Expanded(
                child: items.isEmpty
                    ? _Empty(
                        searching: _searching,
                        scope: _scope,
                        olderLeft: olderLeft,
                        onOlder: () => _setScope(_Scope.older),
                        onDone: () => context.pop(),
                      )
                    : ListView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, Sp.xxl + MediaQuery.paddingOf(context).bottom),
                        itemCount: items.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) return top ?? const SizedBox.shrink();
                          final tx = items[i - 1];
                          return Padding(
                            key: _keys.putIfAbsent(tx.id, GlobalKey.new),
                            padding: const EdgeInsets.only(bottom: Sp.sm),
                            child: _SortCard(
                              tx: tx,
                              big: SortPolicy.isBig(tx, big),
                              open: tx.id == _openId,
                              onOpen: () => _open(tx.id == _openId ? null : tx.id),
                              onPick: (cat) => _pick(tx, cat, items),
                              onSkip: () => _open(_nextUnsorted(items, tx.id)),
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
  const _Header({
    required this.search,
    required this.onQuery,
    required this.scope,
    required this.recentLeft,
    required this.olderLeft,
    required this.onScope,
    required this.total,
    required this.sorted,
    required this.remember,
    required this.onRemember,
    required this.autoSorting,
  });

  final TextEditingController search;
  final ValueChanged<String> onQuery;

  /// Null while searching (tabs hidden).
  final _Scope? scope;
  final int recentLeft;
  final int olderLeft;
  final ValueChanged<_Scope> onScope;
  final int total;
  final int sorted;
  final bool remember;
  final ValueChanged<bool> onRemember;

  /// Transactions the AI is looking at right now (0 when idle).
  final int autoSorting;

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: Sp.sm),
              Padding(
                padding: const EdgeInsets.only(left: Sp.sm),
                child: _SearchField(controller: search, onChanged: onQuery),
              ),
              if (scope != null) ...[
                const SizedBox(height: Sp.sm),
                Padding(
                  padding: const EdgeInsets.only(left: Sp.sm),
                  child: Row(
                    children: [
                      _ScopeChip(
                        label: 'This week',
                        count: recentLeft,
                        selected: scope == _Scope.recent,
                        onTap: () => onScope(_Scope.recent),
                      ),
                      const SizedBox(width: Sp.sm),
                      _ScopeChip(
                        label: 'Older',
                        count: olderLeft,
                        selected: scope == _Scope.older,
                        onTap: () => onScope(_Scope.older),
                      ),
                    ],
                  ),
                ),
              ],
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
              ],
              AnimatedSize(
                duration: Motion.medium,
                child: autoSorting > 0
                    ? Padding(
                        padding: const EdgeInsets.only(left: Sp.sm, top: Sp.sm),
                        child: Row(
                          children: [
                            SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
                            ),
                            const SizedBox(width: Sp.sm),
                            Expanded(
                              child: Text(
                                'Oobli is filing the obvious ones for you…',
                                style: t.labelMedium.copyWith(color: c.secondaryText),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: Sp.xs),
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
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: Sp.md),
      decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(99)),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: c.secondaryText),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: t.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Find a name, code, amount or "boda last week"',
                hintStyle: t.bodyMedium.copyWith(color: c.hint),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => controller.text.isEmpty
                ? const SizedBox.shrink()
                : Pressable(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    semanticLabel: 'Clear search',
                    child: Icon(Icons.close_rounded, size: 20, color: c.secondaryText),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.label, required this.count, required this.selected, required this.onTap});

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label, $count to sort',
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.primaryContainer : c.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? c.primary : c.outline, width: 1.5),
        ),
        child: Text(
          '$label · $count',
          style: t.labelLarge.copyWith(color: selected ? c.onPrimaryContainer : c.secondaryText),
        ),
      ),
    );
  }
}

class _KeepGuessesCard extends StatelessWidget {
  const _KeepGuessesCard({required this.count, required this.onKeep});

  final int count;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.md),
      child: OobliCard(
        color: c.surfaceVariant,
        borderColor: Colors.transparent,
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Older than a week', style: t.titleSmall),
            const SizedBox(height: 2),
            Text(
              "Oobli already filed what it was sure about. Sort the ones that matter, or keep Oobli's guesses for the rest.",
              style: t.bodySmall.copyWith(color: c.secondaryText),
            ),
            const SizedBox(height: Sp.md),
            OobliButton(
              label: "Keep Oobli's guesses for all $count",
              icon: Icons.done_all_rounded,
              size: OobliButtonSize.small,
              onPressed: onKeep,
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.searching,
    required this.scope,
    required this.olderLeft,
    required this.onOlder,
    required this.onDone,
  });

  final bool searching;
  final _Scope scope;
  final int olderLeft;
  final VoidCallback onOlder;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    if (searching) {
      return const EmptyState(
        title: 'No matches',
        message: 'Try a name, an M-Pesa code, an amount, or something like "food this week".',
      );
    }
    if (scope == _Scope.recent && olderLeft > 0) {
      return EmptyState(
        title: 'This week is sorted',
        message: '$olderLeft older ${olderLeft == 1 ? 'one is' : 'ones are'} waiting, if you want to look.',
        mood: MascotMood.celebrating,
        action: OobliButton(label: 'Done', onPressed: onDone),
        secondary: OobliButton(label: 'See older', variant: OobliButtonVariant.secondary, onPressed: onOlder),
      );
    }
    return EmptyState(
      title: 'Nothing to sort',
      message: 'Oobli files what it is sure about. New M-Pesa messages land here only when Oobli needs you.',
      mood: MascotMood.relaxed,
      action: OobliButton(label: 'Done', onPressed: onDone),
    );
  }
}

class _SortCard extends StatelessWidget {
  const _SortCard({
    required this.tx,
    required this.big,
    required this.open,
    required this.onOpen,
    required this.onPick,
    required this.onSkip,
    required this.onDetails,
  });

  final Transaction tx;

  /// A big spend for this user: flagged so it gets a moment's thought.
  final bool big;
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (big) ...[
                            _BigBadge(color: c.warning),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '${Fmt.relativeDay(tx.occurredAt)} · ${Fmt.time12(tx.occurredAt)}',
                            style: t.labelSmall.copyWith(color: c.hint),
                          ),
                        ],
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

class _BigBadge extends StatelessWidget {
  const _BigBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(99)),
        child: Text('Big', style: context.text.labelSmall.copyWith(color: color, fontWeight: FontWeight.w800)),
      );
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
            const OobliMascot(size: 52, glow: false, mood: MascotMood.party),
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
