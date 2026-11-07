import 'package:flutter/material.dart';

import 'tokens.dart';

enum ChipStatus { paid, pending, skipped, overdue, confirmed, unconfirmed }

/// Small status chip (reference: Confirmed / Created / Completed).
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.label});

  final ChipStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String text) = switch (status) {
      ChipStatus.paid => (BColors.primary, BColors.text, 'Paid'),
      ChipStatus.confirmed => (BColors.primary, BColors.text, 'Logged'),
      ChipStatus.pending => (BColors.primaryLight, const Color(0xFF0B1A2E), 'Pending'),
      ChipStatus.unconfirmed => (BColors.primaryLight, const Color(0xFF0B1A2E), 'Unconfirmed'),
      ChipStatus.skipped => (BColors.disabled, BColors.text, 'Skipped'),
      ChipStatus.overdue => (BColors.danger, const Color(0xFF2A0C0C), 'Overdue'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(BRadius.pill)),
      child: Text(label ?? text, style: BText.caption.copyWith(color: fg, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}

/// A colour-tinted pill for status lines on the dashboard (🟢 / 🟡 / 🔴).
class TonePill extends StatelessWidget {
  const TonePill({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(BRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 6)] else ...[
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
        ],
        Text(label, style: BText.label.copyWith(color: color, fontSize: 12)),
      ]),
    );
  }
}

class ChoiceItem<T> {
  const ChoiceItem(this.value, this.label, {this.icon, this.color, this.sub});
  final T value;
  final String label;
  final IconData? icon;
  final Color? color;
  final String? sub;
}

/// Horizontal pill picker — used as AccountChips in every entry sheet.
class ChoicePills<T> extends StatelessWidget {
  const ChoicePills({super.key, required this.items, required this.selected, required this.onChanged, this.wrap = false});

  final List<ChoiceItem<T>> items;
  final T? selected;
  final ValueChanged<T> onChanged;
  final bool wrap;

  Widget _pill(ChoiceItem<T> it) {
    final sel = it.value == selected;
    return Semantics(
      selected: sel,
      button: true,
      label: it.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => onChanged(it.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: sel ? BColors.primary : BColors.surface,
            borderRadius: BorderRadius.circular(BRadius.pill),
            border: Border.all(color: sel ? BColors.primaryLight.withValues(alpha: 0.5) : BColors.borderStrong),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (it.icon != null) ...[
              Icon(it.icon, size: 15, color: sel ? BColors.text : (it.color ?? BColors.primaryLight)),
              const SizedBox(width: 6),
            ] else if (it.color != null) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: it.color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            Text(it.label, style: BText.label.copyWith(fontSize: 13, color: sel ? BColors.text : BColors.text)),
            if (it.sub != null) ...[
              const SizedBox(width: 6),
              Text(it.sub!, style: BText.caption.copyWith(fontSize: 11, color: sel ? BColors.primarySoft : BColors.textMuted)),
            ],
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Wrap(spacing: 8, runSpacing: 8, children: [for (final it in items) _pill(it)]);
    }
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _pill(items[i]),
      ),
    );
  }
}

/// Mon–Sun toggle chips for schedule days (Sunday on by default).
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({super.key, required this.mask, required this.onChanged});

  final int mask;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var w = 1; w <= 7; w++)
          Builder(builder: (_) {
            final on = mask & (1 << (w - 1)) != 0;
            return Semantics(
              toggled: on,
              label: names[w - 1],
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onChanged(mask ^ (1 << (w - 1))),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? BColors.primary : BColors.surface,
                    border: Border.all(color: on ? BColors.primaryLight.withValues(alpha: 0.5) : BColors.borderStrong),
                  ),
                  child: Text(labels[w - 1], style: BText.label.copyWith(color: on ? BColors.text : BColors.textMuted)),
                ),
              ),
            );
          }),
      ],
    );
  }
}
