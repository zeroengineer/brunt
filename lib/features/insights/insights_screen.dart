import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/repositories/queries.dart';
import '../../data/repositories/stats_repo.dart';
import '../../design/design.dart';
import '../common/pickers.dart';

class InsightsData {
  const InsightsData({required this.stats, required this.salaryDays, required this.accuracy, required this.cache});
  final PeriodStats stats;
  final List<(String, int)> salaryDays;
  final List<(String, int, int)> accuracy; // ym, predicted, actual
  final Map<String, int> cache;
}

final insightsProvider = FutureProvider.family<InsightsData?, int>((ref, months) async {
  final key = ref.watch(monthKeyProvider);
  final s = ref.watch(sessionProvider);
  if (key == null || s == null) return null;
  final stats = await s.queries.periodStats(months);
  final all = await s.queries.months();
  final salaryDays = [
    for (final m in all.reversed.take(12))
      if (m.salaryReceivedDate != null) (m.yearMonth, int.parse(m.salaryReceivedDate!.substring(8, 10))),
  ];
  final cache = await s.stats.all();
  final closing = await s.queries.closingSpendable();
  final accuracy = [
    for (final m in all.where((m) => m.status == 'closed').toList().reversed.take(6))
      if (cache['proj_${m.yearMonth}'] != null && closing[m.yearMonth] != null)
        (m.yearMonth, cache['proj_${m.yearMonth}']!, closing[m.yearMonth]!),
  ];
  return InsightsData(stats: stats, salaryDays: salaryDays, accuracy: accuracy, cache: cache);
});

/// Insights (spec §4.7).
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key, this.standalone = false});
  final bool standalone;

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  static const _periods = [1, 3, 6, 12];
  int _sel = 1;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(insightsProvider(_periods[_sel]));
    final cats = ref.watch(categoriesProvider).value ?? const <CategoryRow>[];
    final accounts = ref.watch(allAccountsProvider).value ?? const <AccountRow>[];
    final d = async.value;

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(BSpace.gutter, 8, BSpace.gutter, 140),
      children: [
        Row(children: [
          Expanded(child: Text(d == null ? '' : _periodLabel(d.stats), style: BText.caption)),
          PeriodSwitch(
            options: const ['1m', '3m', '6m', '1y'],
            selected: _sel,
            onChanged: (i) => setState(() => _sel = i),
          ),
        ]),
        const SizedBox(height: 14),
        if (d == null)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
        else ...[
          _Summary(s: d.stats),
          if (d.stats.monthlyExpense.length > 1) ...[
            const SectionHeader('Spend per month'),
            AppCard(child: SizedBox(height: 180, child: _MonthBars(d.stats.monthlyExpense))),
          ],
          const SectionHeader('Average per month, by category'),
          _CategoryBars(stats: d.stats, cats: cats),
          const SectionHeader('Spend by account'),
          _Split(values: d.stats.expenseByAccount, accounts: accounts, total: d.stats.expense),
          if (d.stats.expenseByUpi.isNotEmpty) ...[
            const SectionHeader('Through UPI apps'),
            _Split(values: d.stats.expenseByUpi, accounts: accounts, total: d.stats.expense),
          ],
          const SectionHeader('Salary arrival'),
          _SalaryHistory(days: d.salaryDays, cache: d.cache),
          if (d.accuracy.isNotEmpty) ...[
            const SectionHeader('Projection accuracy'),
            _Accuracy(rows: d.accuracy),
          ],
        ],
      ],
    );
    if (!widget.standalone) return body;
    return BruntScaffold(title: 'Insights', showBack: true, body: body);
  }

  String _periodLabel(PeriodStats s) {
    if (s.months.isEmpty) return '';
    final a = s.months.first.yearMonth;
    final b = s.months.last.yearMonth;
    return a == b ? Dates.monthLabel(a) : '${Dates.monthShort[Dates.firstOfYearMonth(a).month - 1]} – ${Dates.monthLabel(b)}';
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.s});
  final PeriodStats s;

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, String value, {Color color = BColors.text, IconData? icon}) => Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(14),
            radius: 20,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (icon != null) ...[Icon(icon, size: 14, color: BColors.textMuted), const SizedBox(width: 6)],
                Flexible(child: Text(label, style: BText.caption, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 6),
              FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: BText.amount(size: 18, weight: FontWeight.w800, color: color))),
            ]),
          ),
        );
    return Column(children: [
      Row(children: [
        tile('Spent', Money.format(s.expense), icon: LucideIcons.arrowUpRight),
        const SizedBox(width: 10),
        tile('Income', Money.format(s.income), color: BColors.success, icon: LucideIcons.arrowDownLeft),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        tile('Daily average', Money.format(s.dailyAverage), icon: LucideIcons.sun),
        const SizedBox(width: 10),
        tile('Savings rate', '${s.savingsRatePct}%', color: BColors.tierSavings, icon: LucideIcons.piggyBank),
      ]),
    ]);
  }
}

class _MonthBars extends StatelessWidget {
  const _MonthBars(this.data);
  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxV = entries.fold<int>(1, (m, e) => e.value > m ? e.value : m);
    return BarChart(
      BarChartData(
        maxY: maxV * 1.15,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => BColors.surfaceRaised,
            getTooltipItem: (g, _, r, _) => BarTooltipItem(Money.format(r.toY.round()), BText.amount(size: 12)),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= entries.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(Dates.monthShort[Dates.firstOfYearMonth(entries[i].key).month - 1], style: BText.caption.copyWith(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < entries.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: entries[i].value.toDouble(),
                width: entries.length > 8 ? 12 : 22,
                color: i == entries.length - 1 ? BColors.primaryLight : BColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
            ]),
        ],
      ),
    );
  }
}

class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.stats, required this.cats});
  final PeriodStats stats;
  final List<CategoryRow> cats;

  @override
  Widget build(BuildContext context) {
    final rows = stats.expenseByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (rows.isEmpty) return const Text('No spending yet in this period.', style: BText.bodyMuted);
    final top = rows.first.value;
    return AppCard(
      child: Column(children: [
        for (final e in rows.take(10))
          Builder(builder: (_) {
            final c = cats.byId(e.key);
            final color = c == null ? BColors.textMuted : (Tier.of(c.tier) == Tier.variable ? BColors.textMuted : categoryColor(c));
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(c == null ? LucideIcons.receipt : categoryIcon(c), size: 15, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(c?.name ?? 'Other', style: BText.body.copyWith(fontSize: 14))),
                  Text(Money.format(stats.avgPerMonth(e.value)), style: BText.amount(size: 14)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: e.value / top,
                    minHeight: 5,
                    backgroundColor: BColors.surfaceRaised,
                    color: color == BColors.textMuted ? BColors.primaryLight : color,
                  ),
                ),
              ]),
            );
          }),
      ]),
    );
  }
}

class _Split extends StatelessWidget {
  const _Split({required this.values, required this.accounts, required this.total});
  final Map<int, int> values;
  final List<AccountRow> accounts;
  final int total;

  @override
  Widget build(BuildContext context) {
    final rows = values.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (rows.isEmpty) return const Text('Nothing yet.', style: BText.bodyMuted);
    return AppCard(
      child: Column(children: [
        for (final e in rows)
          Builder(builder: (_) {
            final a = accounts.byId(e.key);
            final pct = total == 0 ? 0 : e.value * 100 ~/ total;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                IconBadge(icon: a == null ? LucideIcons.wallet : accountIcon(a), color: a == null ? BColors.textMuted : accountColor(a), size: 32),
                const SizedBox(width: 10),
                Expanded(child: Text(a?.name ?? '—', style: BText.body.copyWith(fontSize: 14))),
                Text('$pct%', style: BText.caption),
                const SizedBox(width: 10),
                Text(Money.format(e.value), style: BText.amount(size: 14)),
              ]),
            );
          }),
      ]),
    );
  }
}

class _SalaryHistory extends StatelessWidget {
  const _SalaryHistory({required this.days, required this.cache});
  final List<(String, int)> days;
  final Map<String, int> cache;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const Text('Mark salary received each month to see when it usually lands.', style: BText.bodyMuted);
    final usual = cache[StatsRepo.salaryDayUsual];
    final latest = cache[StatsRepo.salaryDayLatest];
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (usual != null)
          Text(
            'Usually the ${Dates.ordinal(usual)}${latest != null && latest != usual ? ', latest the ${Dates.ordinal(latest)}' : ''}',
            style: BText.body.copyWith(fontWeight: FontWeight.w600),
          ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (ym, day) in days)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: BColors.surfaceRaised, borderRadius: BorderRadius.circular(12)),
              child: Text('${Dates.monthShort[Dates.firstOfYearMonth(ym).month - 1]} · ${Dates.ordinal(day)}', style: BText.caption.copyWith(color: BColors.text)),
            ),
        ]),
      ]),
    );
  }
}

class _Accuracy extends StatelessWidget {
  const _Accuracy({required this.rows});
  final List<(String, int, int)> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(children: [
        for (final (ym, predicted, actual) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(child: Text(Dates.monthLabel(ym), style: BText.body.copyWith(fontSize: 14))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Predicted ${Money.format(predicted)}', style: BText.caption),
                Text('Ended ${Money.format(actual)}', style: BText.amount(size: 13, color: actual >= predicted ? BColors.success : BColors.warning)),
              ]),
            ]),
          ),
      ]),
    );
  }
}
