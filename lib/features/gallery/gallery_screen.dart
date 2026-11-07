import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/dates.dart';
import '../../design/design.dart';

/// Debug-only component gallery, laid out like design-reference.png (Phase 0).
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int _tab = 0;
  int _nav = 0;
  int _period = 0;
  int _pill = 0;
  int _mask = WeekMask.all;
  String _amount = '';
  late DateTime _day = Dates.day(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final today = Dates.day(DateTime.now());
    return BruntScaffold(
      title: 'Component gallery',
      showBack: true,
      body: ListView(padding: const EdgeInsets.all(BSpace.gutter), children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final w in const [FontWeight.w400, FontWeight.w500, FontWeight.w700])
            Padding(
              padding: EdgeInsets.zero,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(color: BColors.surface, borderRadius: BorderRadius.circular(BRadius.pill)),
                child: Text(w == FontWeight.w400 ? 'Regular' : (w == FontWeight.w500 ? 'Medium' : 'Bold'), style: BText.body.copyWith(fontWeight: w)),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Text('Hh1', style: BText.display.copyWith(fontSize: 96, fontWeight: FontWeight.w500)),
        Text('Manrope', style: BText.h1.copyWith(color: BColors.primary)),
        const Text('Aa Bb Cc Dd Ee Ff Gg Hh Ii Jj Kk Ll Mm', style: BText.bodyMuted),
        Text('1 2 3 4 5 6 7 8 9 0   ₹12,34,567.89', style: BText.amount(size: 15, color: BColors.textMuted)),
        const SizedBox(height: 24),
        Center(
          child: MoneyRing(
            size: 280,
            thickness: 34,
            segments: const [
              RingSegment(30, BColors.tierPriority),
              RingSegment(14, BColors.tierSavings),
              RingSegment(14, BColors.tierFixed),
              RingSegment(16, BColors.tierDaily),
              RingSegment(16, BColors.surface),
            ],
            child: Text('Color', style: BText.h1.copyWith(fontSize: 36, fontWeight: FontWeight.w500)),
          ),
        ),
        const SectionHeader('Pill buttons'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          PillButton(label: 'Active', onPressed: () {}),
          PillButton(label: 'Active', variant: PillVariant.outline, onPressed: () {}),
          const PillButton(label: 'Disabled'),
          const PillButton(label: 'Disabled', variant: PillVariant.outline),
          PillButton(label: 'Dense', dense: true, onPressed: () {}),
          PillButton(label: 'Danger', danger: true, onPressed: () {}),
        ]),
        const SectionHeader('Segment tabs'),
        SegmentTabs(
          items: const [
            SegmentItem('Overview', LucideIcons.layoutGrid),
            SegmentItem('Plan', LucideIcons.calendarDays),
            SegmentItem('Insights', LucideIcons.chartColumn),
            SegmentItem('History', LucideIcons.history),
          ],
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SectionHeader('Status chips'),
        const Wrap(spacing: 8, runSpacing: 8, children: [
          StatusChip(ChipStatus.paid),
          StatusChip(ChipStatus.pending),
          StatusChip(ChipStatus.skipped),
          StatusChip(ChipStatus.overdue),
        ]),
        const SectionHeader('Period switch'),
        PeriodSwitch(options: const ['1m', '3m', '6m', '1y'], selected: _period, onChanged: (i) => setState(() => _period = i)),
        const SectionHeader('Account chips'),
        ChoicePills<int>(
          items: const [
            ChoiceItem(0, 'Cash', icon: LucideIcons.banknote, sub: '₹1.2K'),
            ChoiceItem(1, 'HDFC', icon: LucideIcons.landmark, sub: '₹45K'),
            ChoiceItem(2, 'GPay', icon: LucideIcons.smartphone),
            ChoiceItem(3, 'Card', icon: LucideIcons.creditCard, sub: 'due ₹8.2K'),
          ],
          selected: _pill,
          onChanged: (v) => setState(() => _pill = v),
        ),
        const SectionHeader('Days of week'),
        WeekdayPicker(mask: _mask, onChanged: (m) => setState(() => _mask = m)),
      ]),
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        DateStrip(
          days: Dates.range(today.subtract(const Duration(days: 10)), today).toList(),
          selected: _day,
          onChanged: (d) => setState(() => _day = d),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 0,
          child: Offstage(child: AmountKeypad(value: _amount, onChanged: (v) => setState(() => _amount = v))),
        ),
        PillNavBar(
          items: const [
            NavItem(LucideIcons.house, 'Home'),
            NavItem(LucideIcons.calendarCheck, 'Log'),
            NavItem(LucideIcons.listChecks, 'Plan'),
            NavItem(LucideIcons.wallet, 'Accounts'),
          ],
          selected: _nav,
          onChanged: (i) => setState(() => _nav = i),
        ),
      ]),
    );
  }
}
