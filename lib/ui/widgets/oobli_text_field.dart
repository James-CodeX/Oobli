import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Filled text field with the label above it (Oobli Plans / auth forms).
class OobliTextField extends StatefulWidget {
  const OobliTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.maxLength,
    this.fillColor,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final int? maxLength;
  final Color? fillColor;

  @override
  State<OobliTextField> createState() => _OobliTextFieldState();
}

class _OobliTextFieldState extends State<OobliTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    OutlineInputBorder border(Color color, [double width = 1.5]) => OutlineInputBorder(
          borderRadius: Rad.all(Rad.md),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: t.labelLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: Sp.sm),
        ],
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _hidden,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          autofocus: widget.autofocus,
          maxLength: widget.maxLength,
          style: t.bodyLarge.copyWith(color: c.primaryText),
          cursorColor: c.primary,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: t.bodyLarge.copyWith(color: c.hint),
            filled: true,
            fillColor: widget.fillColor ?? c.background,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 14),
            prefixIcon: widget.icon == null ? null : Icon(widget.icon, color: c.secondaryText, size: 20),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: c.secondaryText,
                      size: 20,
                    ),
                  )
                : null,
            border: border(Colors.transparent),
            enabledBorder: border(c.outline),
            focusedBorder: border(c.primary, 2),
            errorBorder: border(c.error),
            focusedErrorBorder: border(c.error, 2),
            errorStyle: t.bodySmall.copyWith(color: c.error),
          ),
        ),
      ],
    );
  }
}

/// Formats digits as "85,000" while typing.
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  static double? parse(String text) => double.tryParse(text.replaceAll(',', ''));
}
