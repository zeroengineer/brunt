import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'tokens.dart';

/// Amount keypad. Works on a text buffer of rupees ("1250.5"), max 2 decimals.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.value, required this.onChanged, this.keyHeight = 54, this.allowDecimal = true});

  final String value;
  final ValueChanged<String> onChanged;
  final double keyHeight;
  final bool allowDecimal;

  static String press(String current, String key, {bool allowDecimal = true}) {
    if (key == '<') return current.isEmpty ? current : current.substring(0, current.length - 1);
    if (key == '.') {
      if (!allowDecimal || current.contains('.')) return current;
      return current.isEmpty ? '0.' : '$current.';
    }
    final dot = current.indexOf('.');
    if (dot >= 0 && current.length - dot > 2) return current; // 2 decimals max
    if (dot < 0 && current.replaceAll('.', '').length >= 9) return current; // ₹99,99,99,999 max
    if (current == '0') return key;
    return current + key;
  }

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', allowDecimal ? '.' : '', '0', '<'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.3,
      children: [
        for (final k in keys)
          k.isEmpty
              ? const SizedBox()
              : _Key(
                  label: k,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(press(value, k, allowDecimal: allowDecimal));
                  },
                  onLongPress: k == '<' ? () => onChanged('') : null,
                ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap, this.onLongPress});
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BColors.surfaceRaised,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Center(
          child: label == '<'
              ? Semantics(label: 'Delete', child: const Icon(LucideIcons.delete, size: 22, color: BColors.text))
              : Text(label, style: BText.amount(size: 22, weight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// Six-dot PIN indicator + numeric pad, used by lock screen and onboarding.
class PinPad extends StatelessWidget {
  const PinPad({super.key, required this.length, required this.onDigit, required this.onDelete, this.onBiometric, this.max = 6, this.error = false, this.enabled = true});

  final int length;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;
  final int max;
  final bool error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget key(String l) => _PinKey(
          label: l,
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onDigit(l);
                }
              : null,
        );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Semantics(
        label: '$length of $max digits entered',
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < max; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: error ? BColors.danger : (i < length ? BColors.primaryLight : Colors.transparent),
                border: Border.all(color: error ? BColors.danger : BColors.primaryLight.withValues(alpha: 0.6), width: 1.5),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 36),
      for (final row in const [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final d in row) key(d)]),
        ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _PinKey(
          icon: onBiometric != null ? LucideIcons.fingerprint : null,
          semantic: 'Use biometrics',
          onTap: enabled ? onBiometric : null,
          ghost: true,
        ),
        key('0'),
        _PinKey(icon: LucideIcons.delete, semantic: 'Delete', onTap: enabled ? onDelete : null, ghost: true),
      ]),
    ]);
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({this.label, this.icon, this.onTap, this.ghost = false, this.semantic});
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool ghost;
  final String? semantic;

  @override
  Widget build(BuildContext context) {
    if (label == null && icon == null) return const SizedBox(width: 96, height: 72);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Semantics(
        button: true,
        label: semantic ?? label,
        excludeSemantics: true,
        child: Material(
          color: ghost ? Colors.transparent : BColors.surface.withValues(alpha: 0.85),
          shape: const CircleBorder(side: BorderSide(color: BColors.border)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Center(
                child: icon != null
                    ? Icon(icon, color: onTap == null ? BColors.disabled : BColors.text, size: 26)
                    : Text(label!, style: BText.amount(size: 26, weight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
