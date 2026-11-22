import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../../data/services/ai_service.dart';
import '../../domain/natural_search.dart';
import '../../state/insights_controller.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/tiles.dart';
import '../transactions/transaction_editor_sheet.dart';
import '../transactions/transaction_widgets.dart';

sealed class _Item {}

class _Section extends _Item {
  _Section(this.label);
  final String label;
}

class _Tx extends _Item {
  _Tx(this.tx);
  final Transaction tx;
}

/// Full transaction history ("Activity").
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  late final _search = TextEditingController(text: widget.initialQuery ?? '');
  late bool _searching = widget.initialQuery?.isNotEmpty ?? false;

  /// The structured reading of the last submitted search, if any.
  SearchFilter? _smart;
  bool _thinking = false;
  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery;
    if (q != null && q.trim().contains(' ')) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _smartSearch(q));
    }
  }

  /// Reads the query offline at once, then lets the AI refine it.
  Future<void> _smartSearch(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) return;
    final seq = ++_searchSeq;
    final words = q.split(RegExp(r'\s+')).length;
    setState(() {
      _smart = NaturalSearch.parse(q);
      _thinking = words >= 2;
    });
    if (words < 2) return;
    try {
      final ai = await ref.read(aiServiceProvider).search(q).timeout(const Duration(seconds: 10));
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        if (ai != null) _smart = ai;
        _thinking = false;
      });
    } catch (_) {
      // Offline or slow: keep the on-device reading.
      if (mounted && seq == _searchSeq) setState(() => _thinking = false);
    }
  }

  void _clearSmart() => setState(() {
        _searchSeq++;
        _smart = null;
        _thinking = false;
      });

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Iterable<Transaction> _filtered(List<Transaction> txs) {
    final smart = _smart;
    if (smart != null) return txs.where(smart.matches);
    final q = _search.text.trim().toLowerCase();
    return q.isEmpty
        ? txs
        : txs.where((t) =>
            t.merchant.toLowerCase().contains(q) ||
            t.category.label.toLowerCase().contains(q) ||
            (t.reference?.toLowerCase().contains(q) ?? false));
  }

  List<_Item> _items(List<Transaction> txs) {
    final filtered = _filtered(txs);
    final items = <_Item>[];
    String? current;
    for (final tx in filtered) {
      final label = switch (Fmt.relativeDay(tx.occurredAt)) {
        'Today' => 'TODAY',
        'Yesterday' => 'YESTERDAY',
        _ => Fmt.dayMonth(tx.occurredAt),
      };
      if (label != current) {
        items.add(_Section(label));
        current = label;
      }
      items.add(_Tx(tx));
    }
    return items;
  }

  Future<void> _confirm(Transaction tx) async {
    try {
      await ref.read(transactionsProvider.notifier).confirm(tx);
      if (mounted) showOobliSnack(context, 'Got it! Oobli will remember ${tx.merchant}.');
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<bool> _delete(Transaction tx) async {
    final ok = await confirmAction(
      context,
      title: 'Delete transaction?',
      message: '${tx.merchant} · ${Fmt.kes(tx.amount)} will be removed from your history.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return false;
    try {
      await ref.read(transactionsProvider.notifier).delete(tx);
      return true;
    } catch (e) {
      if (mounted) showFailure(context, e);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final txs = ref.watch(transactionsProvider);
    final note = ref.watch(currentInsightsProvider).activityNote;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border(bottom: BorderSide(color: c.divider)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.lg),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            OobliIconButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Back',
                              onPressed: () => context.pop(),
                            ),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: Motion.medium,
                                child: _searching
                                    ? TextField(
                                        key: const ValueKey('search'),
                                        controller: _search,
                                        autofocus: widget.initialQuery == null,
                                        textInputAction: TextInputAction.search,
                                        onChanged: (_) => setState(() {
                                          // Typing again goes back to plain matching until submitted.
                                          _searchSeq++;
                                          _smart = null;
                                          _thinking = false;
                                        }),
                                        onSubmitted: _smartSearch,
                                        style: t.bodyLarge,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Try 'boda last month' or 'Naivas'",
                                          hintStyle: t.bodyLarge.copyWith(color: c.hint),
                                        ),
                                      )
                                    : Text('Activity',
                                        key: const ValueKey('title'),
                                        textAlign: TextAlign.center,
                                        style: t.titleLarge.copyWith(fontSize: 17, color: c.primaryText)),
                              ),
                            ),
                            if (!_searching && ref.watch(unsortedCountProvider) > 0)
                              OobliIconButton(
                                icon: Icons.bolt_rounded,
                                tooltip: 'Quick sort',
                                color: c.primary,
                                onPressed: () => context.push(Routes.quickSort),
                              ),
                            OobliIconButton(
                              icon: _searching ? Icons.close_rounded : Icons.search_rounded,
                              tooltip: _searching ? 'Close search' : 'Search',
                              onPressed: () => setState(() {
                                _searching = !_searching;
                                if (!_searching) {
                                  _search.clear();
                                  _clearSmart();
                                }
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sp.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Sp.sm),
                          child: OobliSaysCard(
                            tinted: true,
                            message: note,
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                              child: Icon(Icons.face_6_rounded, color: c.onSurface, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_searching && (_smart != null || _thinking))
                _SearchSummary(
                  filter: _smart,
                  thinking: _thinking,
                  matches: _filtered(txs.value ?? const []).toList(),
                  onClear: _clearSmart,
                ),
              Expanded(
                child: txs.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(transactionsProvider)),
                  data: (list) {
                    final items = _items(list);
                    if (items.isEmpty) {
                      return EmptyState(
                        title: _search.text.isEmpty ? 'No activity yet' : 'No matches',
                        message: _search.text.isEmpty
                            ? 'Transactions from M-Pesa, banks and manual entries show up here.'
                            : 'Try a different merchant, category or M-Pesa code.',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, 120),
                      itemCount: items.length,
                      itemBuilder: (context, i) => switch (items[i]) {
                        _Section(:final label) => SectionLabel(
                            label,
                            padding: EdgeInsets.only(top: i == 0 ? 0 : Sp.lg, bottom: Sp.md),
                          ),
                        _Tx(:final tx) => Padding(
                            padding: const EdgeInsets.only(bottom: Sp.md),
                            child: Dismissible(
                              key: ValueKey(tx.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => _delete(tx),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: Sp.lg),
                                decoration: BoxDecoration(color: c.error, borderRadius: Rad.all(Rad.lg)),
                                child: Icon(Icons.delete_rounded, color: c.onError),
                              ),
                              child: TransactionCard(
                                tx: tx,
                                onTap: () => showTransactionEditor(context, tx: tx),
                                onConfirm: () => _confirm(tx),
                              ),
                            ),
                          ),
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
                padding: EdgeInsets.fromLTRB(Sp.lg, Sp.xl, Sp.lg, Sp.lg + MediaQuery.paddingOf(context).bottom),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [c.background, c.background.withValues(alpha: 0)],
                  ),
                ),
                child: OobliButton(
                  label: 'Add Transaction',
                  icon: Icons.add_rounded,
                  fullWidth: true,
                  onPressed: () => showTransactionEditor(context),
                ),
              ),
          ),
        ],
      ),
    );
  }
}

/// "KES 3,450 spent · 12 transactions" for a plain-English search, with what
/// Oobli understood, so the user can trust (or clear) the reading.
class _SearchSummary extends StatelessWidget {
  const _SearchSummary({required this.filter, required this.thinking, required this.matches, required this.onClear});

  final SearchFilter? filter;
  final bool thinking;
  final List<Transaction> matches;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final spent = matches.where((x) => x.isOutgoing).fold<double>(0, (s, x) => s + x.amount);
    final received = matches.where((x) => !x.isOutgoing).fold<double>(0, (s, x) => s + x.amount);
    final f = filter;
    final totals = [
      if (spent > 0 || received == 0) '${Fmt.kes(spent)} spent',
      if (received > 0) '${Fmt.kes(received)} received',
      '${matches.length} ${matches.length == 1 ? 'transaction' : 'transactions'}',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, 0),
      padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.xs, Sp.sm),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.1),
        borderRadius: Rad.all(Rad.lg),
        border: Border.all(color: c.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 18, color: c.primary),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f == null ? 'Reading your question…' : totals, style: t.titleSmall),
                Text(
                  [
                    if (f != null && f.label.isNotEmpty) f.label,
                    if (thinking) 'Oobli is refining…' else if (f?.fromAi ?? false) 'Understood by Oobli AI',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelSmall.copyWith(color: c.secondaryText, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (thinking)
            Padding(
              padding: const EdgeInsets.all(Sp.sm),
              child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.primary)),
            ),
          OobliIconButton(icon: Icons.close_rounded, size: 18, tooltip: 'Clear', onPressed: onClear),
        ],
      ),
    );
  }
}
