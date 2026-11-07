import 'package:flutter/material.dart';

import 'tokens.dart';

class SegmentItem {
  const SegmentItem(this.label, [this.icon]);
  final String label;
  final IconData? icon;
}

/// Top segmented tabs (reference: Dashboard / Schedule / Analytics / History),
/// also used for the Expense | Income | Transfer switch.
class SegmentTabs extends StatelessWidget {
  const SegmentTabs({super.key, required this.items, required this.selected, required this.onChanged, this.height = 44});

  final List<SegmentItem> items;
  final int selected;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BColors.surface,
        borderRadius: BorderRadius.circular(BRadius.pill),
        border: Border.all(color: BColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Semantics(
                selected: i == selected,
                button: true,
                label: items[i].label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: i == selected ? BColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(BRadius.pill),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (items[i].icon != null) ...[
                          Icon(items[i].icon, size: 15, color: i == selected ? BColors.text : BColors.primaryLight),
                          const SizedBox(width: 5),
                        ],
                        Text(items[i].label,
                            style: BText.label.copyWith(
                                fontSize: 13, color: i == selected ? BColors.text : BColors.primaryLight)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 1m · 3m · 6m · 1y switch (reference period pill switch).
class PeriodSwitch extends StatelessWidget {
  const PeriodSwitch({super.key, required this.options, required this.selected, required this.onChanged});

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: BColors.surface,
        borderRadius: BorderRadius.circular(BRadius.pill),
        border: Border.all(color: BColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < options.length; i++)
          Semantics(
            selected: i == selected,
            button: true,
            label: options[i],
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == selected ? BColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(BRadius.pill),
                ),
                child: Text(options[i],
                    style: BText.label.copyWith(fontSize: 12, color: i == selected ? BColors.text : BColors.textMuted)),
              ),
            ),
          ),
      ]),
    );
  }
}
