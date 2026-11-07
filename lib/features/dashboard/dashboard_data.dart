import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/repositories/stats_repo.dart';
import '../../domain/projection/projection_engine.dart';
import '../../domain/schedule/schedule_expander.dart';
import '../../data/repositories/month_engine.dart' show specOf;

class TierTotals {
  const TierTotals(this.planned, this.actual);
  final Map<Tier, int> planned;
  final Map<Tier, int> actual;
}

class DashboardData {
  const DashboardData({
    required this.month,
    required this.projection,
    required this.tiers,
    required this.upcoming,
    required this.accounts,
    required this.usualSalaryDay,
    required this.latestSalaryDay,
    required this.salaryAccountId,
  });

  final MonthRow month;
  final Projection projection;
  final TierTotals tiers;
  final List<PlannedRow> upcoming;
  final List<AccountRow> accounts;
  final int? usualSalaryDay;
  final int? latestSalaryDay;
  final int? salaryAccountId;
}

/// Computed once per (month id, version) — never inside build() (spec §10.3).
final dashboardProvider = FutureProvider<DashboardData?>((ref) async {
  final key = ref.watch(monthKeyProvider);
  final s = ref.watch(sessionProvider);
  if (key == null || s == null) return null;
  return buildDashboard(s, Dates.day(DateTime.now()));
});

Future<DashboardData?> buildDashboard(Session s, DateTime today) async {
  final db = s.db;
  final month = await s.engine.latest();
  if (month == null) return null;
  final accounts = await s.queries.accounts(includeArchived: false);
  final categories = {for (final c in await db.select(db.categories).get()) c.id: c};
  final templates = await db.select(db.templates).get();
  final tById = {for (final t in templates) t.id: t};
  final planned = await (db.select(db.plannedItems)..where((p) => p.monthId.equals(month.id))).get();
  final settings = await s.settings.all();
  final stats = await s.stats.all();
  final learned = await s.queries.learnedAverages();

  final first = Dates.firstOfYearMonth(month.yearMonth);
  final last = Dates.lastOfMonth(first);
  final logs = await s.queries.dailyLogs(Dates.iso(first), Dates.iso(last));
  final logged = {for (final l in logs) (l.date, l.templateId)};

  int? intSetting(String k) => int.tryParse(settings[k] ?? '');
  final salaryAccountId = month.salaryAccountId ?? intSetting(SettingKeys.salaryAccountId);

  Tier tierOf(PlannedRow p) =>
      p.cardAccountId != null ? Tier.priority : Tier.of(categories[p.categoryId]?.tier ?? Tier.fixed.value);

  final pending = [
    for (final p in planned.where((p) => p.status == PlannedStatus.pending.code))
      PPlanned(
        name: p.name,
        amount: p.amount,
        tier: tierOf(p),
        dueDate: p.dueDate == null ? null : Dates.parseIso(p.dueDate!),
        payingAccountId: p.cardAccountId != null ? salaryAccountId : tById[p.templateId]?.defaultAccountId,
      ),
  ];

  final daily = [
    for (final t in templates.where((t) => t.frequency == Frequency.daily.code && t.active))
      () {
        final spec = specOf(t);
        final amt = t.variableAmount ? (learned[t.id] ?? t.defaultAmount) : t.defaultAmount;
        return TemplateSpec(
          id: spec.id,
          name: spec.name,
          categoryId: spec.categoryId,
          amount: amt,
          frequency: spec.frequency,
          daysOfWeek: spec.daysOfWeek,
          startMonth: spec.startMonth,
          endMonth: spec.endMonth,
          accountId: spec.accountId,
        );
      }(),
  ];

  final variableSpent = await s.queries.variableSpent(month.id);
  final budget = intSetting(SettingKeys.variableBudget) ?? stats[StatsRepo.medianVariable3m] ?? 0;
  final usual = stats[StatsRepo.salaryDayUsual] ?? intSetting(SettingKeys.salaryUsualDay);
  final latestHist = stats[StatsRepo.salaryDayLatest];
  final latestSet = intSetting(SettingKeys.salaryLatestDay);
  final latest = [latestHist, latestSet, usual].whereType<int>().fold<int?>(null, (a, b) => a == null || b > a ? b : a);

  final onboardedAt = settings[SettingKeys.onboardedAt];
  final input = ProjectionInput(
    today: today,
    yearMonth: month.yearMonth,
    accounts: [
      for (final a in accounts)
        PAccount(
          id: a.id,
          name: a.name,
          type: AccountType.of(a.type),
          balance: a.balance,
          includeInSpendable: a.includeInSpendable,
          creditLimit: a.creditLimit,
          linkedAccountId: a.linkedAccountId,
        ),
    ],
    salaryExpected: month.salaryExpected,
    salaryReceived: month.salaryReceived,
    salaryAccountId: salaryAccountId,
    usualSalaryDay: usual,
    latestSalaryDay: latest,
    pendingPlanned: pending,
    dailyTemplates: daily,
    logged: logged,
    trackingStart: onboardedAt == null ? null : Dates.parseIso(onboardedAt),
    variableBudget: budget,
    variableSpent: variableSpent,
    comfortPct: intSetting(SettingKeys.comfortThresholdPct) ?? 10,
    cardWarnPct: intSetting(SettingKeys.cardWarnPct) ?? 80,
  );
  final projection = ProjectionEngine.compute(input);

  // Projection accuracy: remember the first projection made for each month.
  final snapKey = 'proj_${month.yearMonth}';
  if (!stats.containsKey(snapKey)) {
    await db.into(db.statsCache).insertOnConflictUpdate(StatsCacheCompanion.insert(
        key: snapKey, value: projection.projectedEnd, computedAt: DateTime.now().toIso8601String()));
  }

  // Ring: what this month's money is allocated to, per tier.
  final plannedT = <Tier, int>{for (final t in Tier.values) t: 0};
  final actualT = <Tier, int>{for (final t in Tier.values) t: 0};
  for (final p in planned.where((p) => p.status != PlannedStatus.skipped.code)) {
    plannedT[tierOf(p)] = plannedT[tierOf(p)]! + p.amount;
  }
  for (final t in daily) {
    plannedT[Tier.daily] = plannedT[Tier.daily]! + ScheduleExpander.dailyMonthTotal(t, month.yearMonth);
  }
  plannedT[Tier.variable] = budget > variableSpent ? budget : variableSpent;
  final sums = await (db.select(db.monthSummary)..where((m) => m.monthId.equals(month.id))).get();
  for (final r in sums) {
    final c = categories[r.categoryId];
    if (c == null) continue;
    final t = Tier.of(c.tier);
    actualT[t] = actualT[t]! + r.actual;
  }

  final upcoming = planned.where((p) => p.status == PlannedStatus.pending.code).toList()
    ..sort((a, b) => (a.dueDate ?? '9999').compareTo(b.dueDate ?? '9999'));

  return DashboardData(
    month: month,
    projection: projection,
    tiers: TierTotals(plannedT, actualT),
    upcoming: upcoming,
    accounts: accounts,
    usualSalaryDay: usual,
    latestSalaryDay: latest,
    salaryAccountId: salaryAccountId,
  );
}
