import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/oobli_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../domain/similar_merchants.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/tiles.dart';

/// After the user files [tx] under [category], looks for similar merchants in
/// the background and, if any turn up, offers to file them too. Never blocks.
Future<void> offerSimilar(BuildContext context, Transaction tx, TxCategory category) async {
  final container = ProviderScope.containerOf(context, listen: false);
  // The snack outlives the screen that asked (Quick sort's Done closes it),
  // so Review opens the sheet from the app's own navigator, not [context].
  final navigator = Navigator.of(context, rootNavigator: true);
  final groups = await container.read(transactionsProvider.notifier).similarTo(tx, category);
  if (groups.isEmpty || !context.mounted) return;
  final count = groups.fold<int>(0, (s, g) => s + g.count);
  showOobliSnack(
    context,
    '$count similar ${count == 1 ? 'transaction' : 'transactions'} could be ${category.label} too',
    icon: Icons.auto_awesome_rounded,
    actionLabel: 'Review',
    onAction: () {
      if (!navigator.mounted) return;
      showSimilarSheet(navigator.context, source: tx, category: category, groups: groups);
    },
  );
}

Future<void> showSimilarSheet(
  BuildContext context, {
  required Transaction source,
  required TxCategory category,
  required List<MerchantGroup> groups,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SimilarSheet(source: source, category: category, groups: groups),
    );

class _SimilarSheet extends ConsumerStatefulWidget {
  const _SimilarSheet({required this.source, required this.category, required this.groups});

  final Transaction source;
  final TxCategory category;
  final List<MerchantGroup> groups;

  @override
  ConsumerState<_SimilarSheet> createState() => _SimilarSheetState();
}

class _SimilarSheetState extends ConsumerState<_SimilarSheet> {
  late final Set<String> _selected = {for (final g in widget.groups) g.key};
  bool _saving = false;

  int get _count => widget.groups.where((g) => _selected.contains(g.key)).fold(0, (s, g) => s + g.count);

  Future<void> _apply() async {
    setState(() => _saving = true);
    final chosen = widget.groups.where((g) => _selected.contains(g.key)).toList();
    try {
      final changed = await ref
          .read(transactionsProvider.notifier)
          .fileMerchants(chosen, widget.category, direction: widget.source.direction);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
      showOobliSnack(context, 'Filed $changed under ${widget.category.label}. Oobli will remember these merchants.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final cat = widget.category;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ToneTile(icon: cat.icon, tone: cat.tone, size: 40, radius: Rad.md),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('File these as ${cat.label} too?', style: t.titleLarge),
                    Text(
                      'Similar to ${widget.source.merchant}',
                      style: t.bodySmall.copyWith(color: c.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.md),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final g in widget.groups)
                  CheckboxListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _selected.contains(g.key),
                    activeColor: c.tone(cat.tone),
                    onChanged: (v) => setState(() => v == true ? _selected.add(g.key) : _selected.remove(g.key)),
                    title: Text(g.merchant, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                    subtitle: Text(
                      '${g.count} ${g.count == 1 ? 'transaction' : 'transactions'} · ${Fmt.kes(g.total)} · now ${g.transactions.first.category.label}',
                      style: t.labelMedium.copyWith(color: c.secondaryText),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Sp.md),
          OobliButton(
            label: _count == 0 ? 'Nothing selected' : 'File $_count as ${cat.label}',
            fullWidth: true,
            loading: _saving,
            onPressed: _count == 0 ? null : _apply,
          ),
          const SizedBox(height: Sp.sm),
          OobliButton(
            label: 'Not now',
            variant: OobliButtonVariant.ghost,
            size: OobliButtonSize.medium,
            fullWidth: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
