import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/oobli_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/tiles.dart';

String _amount(Transaction tx, {bool spaced = true}) =>
    Fmt.signedKes(tx.amount, outgoing: tx.isOutgoing, spaced: spaced);

/// Compact row for the dashboard's "Recent M-Pesa" list.
class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key, required this.tx, required this.onEdit});

  final Transaction tx;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final when = Fmt.relativeDay(tx.occurredAt) == 'Today'
        ? Fmt.time12(tx.occurredAt)
        : Fmt.relativeDay(tx.occurredAt);
    return Pressable(
      onTap: onEdit,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.md),
        child: Row(
          children: [
            SizedBox(width: 36, child: Icon(tx.category.icon, color: c.secondaryText, size: 22)),
            const SizedBox(width: Sp.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tx.merchant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyLarge.copyWith(color: c.primaryText),
                        ),
                      ),
                      if (tx.needsReview) ...[const SizedBox(width: Sp.sm), const AiChip()],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$when • ${tx.source.label}',
                    style: t.labelMedium.copyWith(color: c.secondaryText, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Sp.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _amount(tx),
                  style: t.titleMedium.copyWith(
                    fontSize: 14,
                    color: tx.isOutgoing ? c.primaryText : c.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Edit', style: t.labelSmall.copyWith(color: c.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for the Activity screen. Unreviewed AI categorisations show the
/// "Is this 'Groceries'?" confirmation footer.
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.tx,
    required this.onTap,
    this.onConfirm,
    this.onEdit,
  });

  final Transaction tx;
  final VoidCallback onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final review = tx.needsReview && onConfirm != null;

    final header = Row(
      children: [
        ToneTile(icon: tx.category.icon, tone: tx.category.tone, size: 40, radius: Rad.md, soft: review),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(tx.merchant,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleMedium),
                  ),
                  const SizedBox(width: Sp.sm),
                  Text(
                    _amount(tx, spaced: false),
                    style: t.titleMedium.copyWith(color: tx.isOutgoing ? c.primaryText : c.primary),
                  ),
                ],
              ),
              const SizedBox(height: Sp.xs),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      tx.category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelMedium.copyWith(color: review ? c.primaryText : c.secondaryText, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('  •  ${Fmt.time24(tx.occurredAt)}',
                      style: t.labelMedium.copyWith(color: review ? c.primaryText : c.hint)),
                  const Spacer(),
                  if (tx.reference != null && !review)
                    Text(tx.reference!, style: t.labelMedium.copyWith(color: c.hint)),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: Motion.medium,
        padding: const EdgeInsets.all(Sp.md),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: Rad.all(Rad.lg),
          border: Border.all(
            color: review ? c.primary.withValues(alpha: 0.3) : c.divider,
            width: review ? 2 : 1,
          ),
          boxShadow: review ? Shadows.sm : null,
        ),
        child: review
            ? Column(
                children: [
                  header,
                  const SizedBox(height: Sp.md),
                  const Divider(),
                  const SizedBox(height: Sp.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text("Is this '${tx.category.label}'?",
                            style: t.bodySmall.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
                      ),
                      OobliButton(
                        label: 'Edit',
                        variant: OobliButtonVariant.outline,
                        size: OobliButtonSize.small,
                        onPressed: onEdit ?? onTap,
                      ),
                      const SizedBox(width: Sp.sm),
                      OobliButton(label: 'Yes', size: OobliButtonSize.small, onPressed: onConfirm),
                    ],
                  ),
                ],
              )
            : header,
      ),
    );
  }
}

/// Tone-coloured square used in insight card headers.
class ToneDot extends StatelessWidget {
  const ToneDot({super.key, required this.tone, required this.icon, this.size = 28});

  final Tone tone;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => ToneTile(icon: icon, tone: tone, size: size, radius: Rad.xs);
}

/// Categories offered for a transaction going in [direction].
List<TxCategory> categoryChoices(TxDirection direction) => direction == TxDirection.inbound
    ? const [TxCategory.income, TxCategory.savings, TxCategory.debt, TxCategory.transfer, TxCategory.other]
    : TxCategory.spending;

/// Pill with a category icon and label, tinted by the category tone when selected.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, required this.selected, required this.onTap});

  final TxCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = c.tone(category.tone);
    return Pressable(
      onTap: onTap,
      semanticLabel: category.label,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : c.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? color : c.outline, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 16, color: selected ? color : c.secondaryText),
            const SizedBox(width: 6),
            Text(category.label, style: context.text.labelMedium.copyWith(color: c.primaryText)),
          ],
        ),
      ),
    );
  }
}
