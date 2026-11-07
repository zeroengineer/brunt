import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../design/design.dart';
import '../../domain/projection/projection_engine.dart';
import '../common/pickers.dart';
import '../plan/pay_sheet.dart';
import 'dashboard_data.dart';
import 'salary_sheet.dart';

/// Dashboard (spec §11.5 #2).
class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);
    final data = async.value;
    if (data == null) {
      return async.hasError
          ? Center(child: Text('Could not compute: ${async.error}', style: BText.bodyMuted))
          : const Center(child: CircularProgressIndicator());
    }
    final p = data.projection;
    return ListView(
      padding: const EdgeInsets.fromLTRB(BSpace.gutter, 8, BSpace.gutter, 120),
      children: [
        Center(child: _StatusPill(p)),
        const SizedBox(height: 18),
        Center(child: _Ring(data: data)),
        const SizedBox(height: 14),
        _Legend(data: data),
        const SizedBox(height: 18),
        _AccountStrip(accounts: data.accounts),
        const SizedBox(height: 14),
        _SafeCard(p: p),
        const SizedBox(height: 12),
        _SalaryCard(data: data),
        for (final w in _banners(context, data)) ...[const SizedBox(height: 12), w],
        if (data.upcoming.isNotEmpty) ...[
          SectionHeader('Upcoming dues',
              trailing: TextButton(onPressed: () => context.go('/plan'), child: const Text('See plan'))),
          for (final item in data.upcoming.take(5)) _DueRow(item: item),
        ],
        const SectionHeader('Where the month stands'),
        _Breakdown(p: p),
      ],
    );
  }

  List<Widget> _banners(BuildContext context, DashboardData d) {
    final p = d.projection;
    final out = <Widget>[];
    if (d.month.salaryPendingCarried) {
      out.add(const InfoBanner(
        icon: LucideIcons.circleAlert,
        color: BColors.warning,
        title: "Last month's salary never arrived",
        message: 'It is still marked pending. If it lands, add it as extra income.',
      ));
    }
    final gap = p.gap;
    if (gap != null && !gap.beyondHistory && gap.need > 0) {
      out.add(InfoBanner(
        icon: gap.ok ? LucideIcons.shieldCheck : LucideIcons.triangleAlert,
        color: gap.ok ? BColors.success : BColors.danger,
        title: gap.ok ? 'Gap covered until salary' : 'Short before salary',
        message: gap.ok
            ? 'Your ${Money.format(gap.available)} covers ${Money.format(gap.need)} of spending until the ${Dates.ordinal(gap.untilDate.day)}, the latest salary has come.'
            : 'You need ${Money.format(gap.need)} until the ${Dates.ordinal(gap.untilDate.day)} but have ${Money.format(gap.available)}. Short by ${Money.format(gap.shortBy)}.',
      ));
    }
    for (final w in p.warnings) {
      out.add(InfoBanner(
        icon: switch (w.kind) {
          WarningKind.runOut => LucideIcons.banknote,
          WarningKind.cardLimit => LucideIcons.creditCard,
          WarningKind.salaryLate => LucideIcons.clock,
          WarningKind.overdue => LucideIcons.calendarX,
        },
        color: w.kind == WarningKind.cardLimit || w.kind == WarningKind.salaryLate ? BColors.warning : BColors.danger,
        message: w.message,
        onTap: w.accountId != null ? () => context.push('/account/${w.accountId}') : null,
      ));
    }
    return out;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.p);
  final Projection p;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (p.status) {
      MonthStatus.comfortable => ('Comfortable', BColors.success),
      MonthStatus.tight => ('Tight', BColors.warning),
      MonthStatus.short => ('Short by ${Money.format(p.shortBy)}', BColors.danger),
    };
    return Semantics(label: 'Month status: $label', child: TonePill(label: label, color: color));
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = data.tiers.planned;
    final w = MediaQuery.sizeOf(context).width;
    final size = (w - 80).clamp(200.0, 290.0);
    return Semantics(
      label: 'Spendable now ${Money.format(data.projection.balanceNow)}',
      child: MoneyRing(
        size: size,
        thickness: size * 0.115,
        segments: [
          for (final tier in const [Tier.priority, Tier.savings, Tier.fixed, Tier.daily, Tier.variable])
            RingSegment(t[tier] ?? 0, BColors.tier(tier), tier.label),
        ],
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Spendable now', style: BText.caption),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(Money.format(data.projection.balanceNow), style: BText.display.copyWith(fontSize: size * 0.13)),
          ),
          const SizedBox(height: 2),
          Text(Dates.monthLabel(data.month.yearMonth), style: BText.caption),
        ]),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = data.tiers.planned;
    return Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 8, children: [
      for (final tier in const [Tier.priority, Tier.savings, Tier.fixed, Tier.daily, Tier.variable])
        if ((t[tier] ?? 0) > 0)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: BColors.tier(tier),
                shape: BoxShape.circle,
                border: tier == Tier.variable ? Border.all(color: BColors.textMuted) : null,
              ),
            ),
            const SizedBox(width: 6),
            Text('${tier.label} ${Money.compact(t[tier]!)}', style: BText.caption),
          ]),
    ]);
  }
}

class _AccountStrip extends StatelessWidget {
  const _AccountStrip({required this.accounts});
  final List<AccountRow> accounts;

  @override
  Widget build(BuildContext context) {
    final shown = accounts.where((a) => a.type != AccountType.upi.code).toList();
    if (shown.isEmpty) return const SizedBox();
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shown.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final a = shown[i];
          final card = a.type == AccountType.creditCard.code;
          return AppCard(
            radius: 20,
            onTap: () => context.push('/account/${a.id}'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              IconBadge(icon: accountIcon(a), color: accountColor(a), size: 34),
              const SizedBox(width: 10),
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(card ? '${a.name} due' : a.name, style: BText.caption),
                const SizedBox(height: 2),
                Text(Money.format(a.balance), style: BText.amount(size: 15, color: card && a.balance > 0 ? BColors.danger : BColors.text)),
              ]),
            ]),
          );
        },
      ),
    );
  }
}

class _SafeCard extends StatelessWidget {
  const _SafeCard({required this.p});
  final Projection p;

  @override
  Widget build(BuildContext context) {
    final endColor = p.projectedEnd < 0 ? BColors.danger : (p.status == MonthStatus.tight ? BColors.warning : BColors.success);
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Safe to spend today', style: BText.caption),
            const SizedBox(height: 6),
            Text(Money.format(p.safePerDay), style: BText.amount(size: 30, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${p.daysLeft} day${p.daysLeft == 1 ? '' : 's'} left · after plan', style: BText.caption),
          ]),
        ),
        Container(width: 1, height: 56, color: BColors.border),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('Month ends with', style: BText.caption),
          const SizedBox(height: 6),
          Text(Money.format(p.projectedEnd), style: BText.amount(size: 18, color: endColor)),
        ]),
      ]),
    );
  }
}

class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final m = data.month;
    if (m.salaryExpected <= 0 && m.salaryReceived == null) return const SizedBox();
    final received = m.salaryReceived != null;
    if (received) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const IconBadge(icon: LucideIcons.circleCheck, color: BColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Salary received', style: BText.body),
              Text('${Dates.short(Dates.parseIso(m.salaryReceivedDate!))} · locked for the month', style: BText.caption),
            ]),
          ),
          Text(Money.format(m.salaryReceived!), style: BText.amount(color: BColors.success)),
        ]),
      );
    }
    final usual = data.usualSalaryDay;
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: BColors.primaryLight.withValues(alpha: 0.3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const IconBadge(icon: LucideIcons.hourglass, color: BColors.primaryLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Salary pending', style: BText.body),
              Text(
                usual == null
                    ? 'Expected this month'
                    : 'Usually the ${Dates.ordinal(usual)}${data.latestSalaryDay != null && data.latestSalaryDay != usual ? ', latest the ${Dates.ordinal(data.latestSalaryDay!)}' : ''}',
                style: BText.caption,
              ),
            ]),
          ),
          Text(Money.format(m.salaryExpected), style: BText.amount()),
        ]),
        const SizedBox(height: 14),
        PillButton(
          label: 'Salary received',
          icon: LucideIcons.check,
          expand: true,
          dense: true,
          onPressed: () => showSalarySheet(context, m, data.salaryAccountId),
        ),
      ]),
    );
  }
}

class _DueRow extends ConsumerWidget {
  const _DueRow({required this.item});
  final PlannedRow item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).value ?? const <CategoryRow>[];
    final c = cats.byId(item.categoryId);
    final due = item.dueDate == null ? null : Dates.parseIso(item.dueDate!);
    final overdue = due != null && due.isBefore(Dates.day(DateTime.now()));
    final tier = item.cardAccountId != null ? Tier.priority : Tier.of(c?.tier ?? 3);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: () => showPaySheet(context, item),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        radius: 20,
        child: Row(children: [
          IconBadge(icon: c == null ? LucideIcons.creditCard : categoryIcon(c), color: BColors.tier(tier) == BColors.tierVariable ? BColors.textMuted : BColors.tier(tier), size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: BText.body, overflow: TextOverflow.ellipsis),
              Text(due == null ? 'Anytime' : 'Due ${Dates.short(due)}', style: BText.caption.copyWith(color: overdue ? BColors.danger : null)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Money.format(item.amount), style: BText.amount()),
            const SizedBox(height: 4),
            StatusChip(overdue ? ChipStatus.overdue : ChipStatus.pending),
          ]),
        ]),
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.p});
  final Projection p;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, int v, {Color? color, String? sign}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Expanded(child: Text(label, style: BText.bodyMuted)),
            Text('${sign ?? ''}${Money.format(v)}', style: BText.amount(color: color ?? BColors.text)),
          ]),
        );
    return AppCard(
      child: Column(children: [
        row('Spendable now', p.balanceNow),
        if (p.pendingSalary > 0) row('Salary to come', p.pendingSalary, sign: '+ ', color: BColors.success),
        row('Bills, debts & savings left', p.committedLeft, sign: '− '),
        row('Daily costs left', p.dailyLeft, sign: '− '),
        row('Variable budget left', p.variableLeft, sign: '− '),
        const Divider(height: 20),
        row('Projected month end', p.projectedEnd,
            color: p.projectedEnd < 0 ? BColors.danger : (p.status == MonthStatus.tight ? BColors.warning : BColors.success)),
      ]),
    );
  }
}
