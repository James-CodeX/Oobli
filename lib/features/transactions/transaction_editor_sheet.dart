import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/oobli_text_field.dart';
import '../../ui/widgets/pressable.dart';
import 'transaction_widgets.dart';

/// Opens the add/edit transaction sheet. Pass [tx] to edit.
Future<void> showTransactionEditor(BuildContext context, {Transaction? tx}) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TransactionEditorSheet(tx: tx),
    );

class TransactionEditorSheet extends ConsumerStatefulWidget {
  const TransactionEditorSheet({super.key, this.tx});

  final Transaction? tx;

  @override
  ConsumerState<TransactionEditorSheet> createState() => _TransactionEditorSheetState();
}

class _TransactionEditorSheetState extends ConsumerState<TransactionEditorSheet> {
  late final _amount = TextEditingController(
    text: widget.tx == null ? '' : Fmt.number(widget.tx!.amount.round()),
  );
  late final _merchant = TextEditingController(text: widget.tx?.merchant ?? '');
  late final _note = TextEditingController(text: widget.tx?.note ?? '');
  late TxDirection _direction = widget.tx?.direction ?? TxDirection.out;
  late TxCategory _category = widget.tx?.category ?? TxCategory.groceries;
  late DateTime _when = widget.tx?.occurredAt ?? DateTime.now();
  late bool _learn = widget.tx?.source != TxSource.manual;
  bool _saving = false;
  bool _showRaw = false;

  bool get _editing => widget.tx != null;

  List<TxCategory> get _choices => categoryChoices(_direction);

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now().subtract(const Duration(days: 400)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when));
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time?.hour ?? _when.hour, time?.minute ?? _when.minute);
    });
  }

  Future<void> _save() async {
    final amount = ThousandsFormatter.parse(_amount.text) ?? 0;
    final merchant = _merchant.text.trim();
    if (amount <= 0 || merchant.isEmpty) {
      HapticFeedback.heavyImpact();
      showOobliSnack(context, 'Add an amount and who it was for.', error: true);
      return;
    }
    setState(() => _saving = true);
    final controller = ref.read(transactionsProvider.notifier);
    try {
      if (_editing) {
        final before = widget.tx!;
        final after = before.copyWith(
          amount: amount,
          merchant: merchant,
          direction: _direction,
          category: _category,
          occurredAt: _when,
          note: _note.text.trim(),
        );
        await controller.edit(before, after, applyToMerchant: _learn && before.category != _category);
      } else {
        await controller.add(
          Transaction(
            id: '',
            fingerprint: 'manual-${DateTime.now().microsecondsSinceEpoch}',
            amount: amount,
            direction: _direction,
            merchant: merchant,
            category: _category,
            channel: TxChannel.other,
            source: TxSource.manual,
            occurredAt: _when,
            confirmed: true,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          ),
          learnRule: _learn,
        );
      }
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        showOobliSnack(context, _editing ? 'Updated. Oobli will remember that.' : 'Transaction added');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showFailure(context, e);
      }
    }
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'Delete transaction?',
      message: 'This removes it from your history and charts.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(transactionsProvider.notifier).delete(widget.tx!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_editing ? 'Edit transaction' : 'Add transaction', style: t.headlineSmall),
            const SizedBox(height: Sp.lg),
            _DirectionToggle(
              value: _direction,
              onChanged: (d) => setState(() {
                _direction = d;
                if (!_choices.contains(_category)) _category = _choices.first;
              }),
            ),
            const SizedBox(height: Sp.lg),
            TextField(
              controller: _amount,
              autofocus: !_editing,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              textAlign: TextAlign.center,
              style: t.displaySmall.copyWith(color: c.primaryText),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: t.displaySmall.copyWith(color: c.hint),
                prefixText: 'KES ',
                prefixStyle: t.titleLarge.copyWith(color: c.secondaryText),
              ),
            ),
            const SizedBox(height: Sp.md),
            OobliTextField(
              label: _direction == TxDirection.out ? 'Paid to' : 'Received from',
              hint: 'e.g. Naivas, Mama Mboga, John',
              icon: Icons.storefront_rounded,
              controller: _merchant,
              textCapitalization: TextCapitalization.words,
              fillColor: c.surface,
            ),
            const SizedBox(height: Sp.lg),
            Text('Category', style: t.labelLarge.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: Sp.sm),
            Wrap(
              spacing: Sp.sm,
              runSpacing: Sp.sm,
              children: [
                for (final cat in _choices)
                  CategoryChip(
                    category: cat,
                    selected: cat == _category,
                    onTap: () => setState(() => _category = cat),
                  ),
              ],
            ),
            const SizedBox(height: Sp.lg),
            Pressable(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(Sp.md),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: Rad.all(Rad.md),
                  border: Border.all(color: c.outline, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded, color: c.secondaryText, size: 20),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Text('${Fmt.relativeDay(_when)} · ${Fmt.time12(_when)}', style: t.bodyLarge),
                    ),
                    Icon(Icons.chevron_right_rounded, color: c.secondaryText),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Sp.md),
            OobliTextField(hint: 'Note (optional)', icon: Icons.notes_rounded, controller: _note, fillColor: c.surface),
            if (_direction == TxDirection.out) ...[
              const SizedBox(height: Sp.sm),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _learn,
                onChanged: (v) => setState(() => _learn = v),
                title: Text('Remember this category', style: t.titleSmall),
                subtitle: Text(
                  'Oobli will use it for this merchant from now on.',
                  style: t.bodySmall.copyWith(color: c.secondaryText),
                ),
              ),
            ],
            if (widget.tx?.rawMessage != null) ...[
              const SizedBox(height: Sp.sm),
              Pressable(
                onTap: () => setState(() => _showRaw = !_showRaw),
                child: Row(
                  children: [
                    Icon(Icons.sms_rounded, size: 18, color: c.secondaryText),
                    const SizedBox(width: Sp.sm),
                    Text('Original message', style: t.labelLarge.copyWith(color: c.secondaryText)),
                    Icon(_showRaw ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: c.secondaryText),
                  ],
                ),
              ),
              AnimatedSize(
                duration: Motion.medium,
                child: _showRaw
                    ? Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: Sp.sm),
                        padding: const EdgeInsets.all(Sp.md),
                        decoration: BoxDecoration(color: c.surface, borderRadius: Rad.all(Rad.md)),
                        child: SelectableText(widget.tx!.rawMessage!, style: t.bodySmall),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
            const SizedBox(height: Sp.lg),
            OobliButton(
              label: _editing ? 'Save changes' : 'Add transaction',
              fullWidth: true,
              loading: _saving,
              onPressed: _save,
            ),
            if (_editing) ...[
              const SizedBox(height: Sp.sm),
              OobliButton(
                label: 'Delete',
                icon: Icons.delete_outline_rounded,
                variant: OobliButtonVariant.ghost,
                size: OobliButtonSize.medium,
                fullWidth: true,
                onPressed: _saving ? null : _delete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DirectionToggle extends StatelessWidget {
  const _DirectionToggle({required this.value, required this.onChanged});

  final TxDirection value;
  final ValueChanged<TxDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget option(TxDirection d, String label, IconData icon) {
      final selected = d == value;
      return Expanded(
        child: Pressable(
          onTap: () => onChanged(d),
          child: AnimatedContainer(
            duration: Motion.fast,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? c.primary : Colors.transparent,
              borderRadius: Rad.all(Rad.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? c.onPrimary : c.secondaryText),
                const SizedBox(width: Sp.sm),
                Text(label,
                    style: context.text.labelLarge.copyWith(color: selected ? c.onPrimary : c.secondaryText)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surface, borderRadius: Rad.all(Rad.lg)),
      child: Row(
        children: [
          option(TxDirection.out, 'Spent', Icons.north_east_rounded),
          option(TxDirection.inbound, 'Received', Icons.south_west_rounded),
        ],
      ),
    );
  }
}
