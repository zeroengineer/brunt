import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Labelled text field in the BRUNT style.
class BField extends StatelessWidget {
  const BField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.onChanged,
    this.prefix,
    this.inputFormatters,
    this.obscure = false,
    this.autofocus = false,
    this.maxLength,
    this.initialValue,
    this.textInputAction,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? prefix;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscure;
  final bool autofocus;
  final int? maxLength;
  final String? initialValue;
  final TextInputAction? textInputAction;

  /// Amount field (rupees with up to 2 decimals).
  factory BField.amount({Key? key, required String label, TextEditingController? controller, ValueChanged<String>? onChanged, String? hint, bool autofocus = false}) =>
      BField(
        key: key,
        label: label,
        controller: controller,
        onChanged: onChanged,
        hint: hint ?? '0',
        prefix: '₹ ',
        autofocus: autofocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}(\.\d{0,2})?'))],
      );

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 6), child: Text(label, style: BText.caption)),
      TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscure,
        autofocus: autofocus,
        maxLength: maxLength,
        textInputAction: textInputAction,
        style: keyboardType != null && keyboardType!.decimal != null ? BText.amount(size: 16, weight: FontWeight.w600) : BText.body,
        cursorColor: BColors.primaryLight,
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          prefixText: prefix,
          prefixStyle: BText.body.copyWith(color: BColors.textMuted),
          hintStyle: BText.bodyMuted.copyWith(color: BColors.disabled),
          filled: true,
          fillColor: BColors.surfaceRaised,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(BRadius.field), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BRadius.field), borderSide: const BorderSide(color: BColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BRadius.field), borderSide: const BorderSide(color: BColors.primaryLight, width: 1.4)),
        ),
      ),
    ]);
  }
}

/// A row with a label and a trailing switch.
class SwitchRow extends StatelessWidget {
  const SwitchRow({super.key, required this.label, required this.value, required this.onChanged, this.sub});

  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: BText.body),
            if (sub != null) Text(sub!, style: BText.caption),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: BColors.text,
          activeTrackColor: BColors.primary,
          inactiveThumbColor: BColors.textMuted,
          inactiveTrackColor: BColors.surfaceRaised,
        ),
      ]),
    );
  }
}

/// Tappable stepper for a day of month (1–31).
class DayStepper extends StatelessWidget {
  const DayStepper({super.key, required this.label, required this.value, required this.onChanged, this.min = 1, this.max = 31, this.format});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String Function(int)? format;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(label, style: BText.body)),
      IconButton(
        tooltip: 'Decrease',
        onPressed: value > min ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove_rounded),
        color: BColors.primaryLight,
      ),
      SizedBox(width: 56, child: Center(child: Text(format?.call(value) ?? '$value', style: BText.amount(size: 16)))),
      IconButton(
        tooltip: 'Increase',
        onPressed: value < max ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add_rounded),
        color: BColors.primaryLight,
      ),
    ]);
  }
}
