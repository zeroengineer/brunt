import 'package:flutter/material.dart';

import '../core/dates.dart';
import 'tokens.dart';

enum DayMark { none, done, partial, missed }

/// Mon 20 · Tue 21 … day chips (reference). Scrolls to keep the selected day visible.
class DateStrip extends StatefulWidget {
  const DateStrip({
    super.key,
    required this.days,
    required this.selected,
    required this.onChanged,
    this.marks = const {},
  });

  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  final Map<DateTime, DayMark> marks;

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  static const _w = 56.0;
  static const _gap = 8.0;
  late final ScrollController _c;

  int get _index => widget.days.indexWhere((d) => DateUtils.isSameDay(d, widget.selected));

  @override
  void initState() {
    super.initState();
    _c = ScrollController(initialScrollOffset: _offsetFor(_index));
  }

  double _offsetFor(int i) => i < 2 ? 0 : (i - 2) * (_w + _gap);

  @override
  void didUpdateWidget(DateStrip old) {
    super.didUpdateWidget(old);
    if (!DateUtils.isSameDay(old.selected, widget.selected) && _c.hasClients) {
      _c.animateTo(_offsetFor(_index).clamp(0, _c.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = Dates.day(DateTime.now());
    return SizedBox(
      height: 78,
      child: ListView.separated(
        controller: _c,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BSpace.gutter),
        itemCount: widget.days.length,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (_, i) {
          final d = widget.days[i];
          final sel = DateUtils.isSameDay(d, widget.selected);
          final isToday = DateUtils.isSameDay(d, today);
          final future = d.isAfter(today);
          final mark = widget.marks[Dates.day(d)] ?? DayMark.none;
          return Semantics(
            selected: sel,
            button: true,
            label: '${Dates.weekdayShort[d.weekday - 1]} ${d.day}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => widget.onChanged(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: _w,
                decoration: BoxDecoration(
                  color: sel ? BColors.surfaceRaised : BColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? BColors.primaryLight.withValues(alpha: 0.6) : BColors.border),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(Dates.weekdayShort[d.weekday - 1],
                      style: BText.caption.copyWith(fontSize: 11, color: future ? BColors.disabled : BColors.textMuted)),
                  const SizedBox(height: 5),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sel ? BColors.primary : Colors.transparent,
                      border: isToday && !sel ? Border.all(color: BColors.primaryLight) : null,
                    ),
                    child: Text('${d.day}',
                        style: BText.amount(size: 13, color: future && !sel ? BColors.disabled : BColors.text)),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: switch (mark) {
                        DayMark.done => BColors.success,
                        DayMark.partial => BColors.warning,
                        DayMark.missed => BColors.danger,
                        DayMark.none => Colors.transparent,
                      },
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
