import 'dart:ui' show Color;

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/repositories/stats_repo.dart';
import '../../design/tokens.dart';
import '../../domain/ledger/ledger_rules.dart';
import '../../domain/projection/projection_engine.dart';
import '../../domain/schedule/schedule_expander.dart';
import '../../data/repositories/catalog_repo.dart';
import '../../data/repositories/month_engine.dart' show specOf;

class TierTotals {
  const TierTotals(this.planned, this.actual, {this.reservePlanned = 0, this.reserveActual = 0});
  final Map<Tier, int> planned;
  final Map<Tier, int> actual;

  /// Reserve items (Savings tier, Reserve category) shown as their own part of the ring.
  final int reservePlanned;
  final int reserveActual;
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

/// One part of the ring: a tier, or the Reserve (its own part, in the Savings colour).
class RingPart {
  const RingPart(this.label, this.color, this.planned, this.actual, {this.outlined = false});
  final String label;
  final Color color;
  final int planned;
  final int actual;
  final bool outlined;
}

/// Ring order — shared by the dashboard ring and its legend.
List<RingPart> ringParts(DashboardData d) {
  final t = d.tiers;
  RingPart tier(Tier x) => RingPart(x.label, BColors.tier(x), t.planned[x] ?? 0, t.actual[x] ?? 0, outlined: x == Tier.variable);
  return [
    tier(Tier.priority),
    tier(Tier.savings),
    RingPart('Reserve', BColors.tierReserve, t.reservePlanned, t.reserveActual),
    tier(Tier.fixed),
    tier(Tier.daily),
    tier(Tier.variable),
  ];
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

  final first = Dates.firstOfYearMonth(month.yearMonth);
  final last = Dates.lastOfMonth(first);
  final logs = await s.queries.dailyLogs(Dates.iso(first), Dates.iso(last));
  final logged = {for (final l in logs) (l.date, l.templateId)};

  int? intSetting(String k) => int.tryParse(settings[k] ?? '');
  final salaryAccountId = month.salaryAccountId ?? intSetting(SettingKeys.salaryAccountId);

  Tier tierOf(PlannedRow p) =>
      p.cardAccountId != null ? Tier.priority : Tier.of(categories[p.categoryId]?.tier ?? Tier.fixed.value);

  PPlanned toP(PlannedRow p) => PPlanned(
        name: p.name,
        amount: p.amount,
        tier: tierOf(p),
        dueDate: p.dueDate == null ? null : Dates.parseIso(p.dueDate!),
        payingAccountId: p.cardAccountId != null ? salaryAccountId : tById[p.templateId]?.defaultAccountId,
      );
  final pending = [for (final p in planned.where((p) => p.status == PlannedStatus.pending.code)) toP(p)];

  // Daily items are planned at the amount set on the recurring item. Editing one day in the
  // daily log changes only that day — never the forecast for the other days.
  final daily = [
    for (final t in templates.where((t) => t.frequency == Frequency.daily.code && t.active)) specOf(t),
  ];

  final variableSpent = await s.queries.variableSpent(month.id);

  // ----- the month as it stood when today began (for the live "safe to spend today")
  final todayIso = Dates.iso(today);
  final todayTx = await (db.select(db.transactions)..where((t) => t.date.equals(todayIso))).get();
  final accType = {for (final a in accounts) a.id: AccountType.of(a.type)};
  final sodBalance = {for (final a in accounts) a.id: a.balance};
  var variableToday = 0;
  for (final tx in todayTx) {
    final type = TxType.of(tx.type);
    // Income and corrections are part of the day's starting point, not spending.
    if (type.isIncome || type == TxType.adjustment) continue;
    final deltas = balanceDeltas(
      type: type,
      amount: tx.amount,
      accountId: tx.accountId,
      accountIsCard: accType[tx.accountId]?.isLiability ?? false,
      toAccountId: tx.toAccountId,
      toIsCard: accType[tx.toAccountId]?.isLiability ?? false,
    );
    for (final MapEntry(key: id, value: v) in deltas.entries) {
      if (sodBalance.containsKey(id)) sodBalance[id] = sodBalance[id]! - v;
    }
    if (type == TxType.expense && categories[tx.categoryId]?.tier == Tier.variable.value) variableToday += tx.amount;
  }
  final todayTxIds = {for (final tx in todayTx) tx.id};
  final paidToday = planned.where((p) => p.status == PlannedStatus.paid.code && todayTxIds.contains(p.transactionId));
  final budget = intSetting(SettingKeys.variableBudget) ?? stats[StatsRepo.medianVariable3m] ?? 0;
  final usual = stats[StatsRepo.salaryDayUsual] ?? intSetting(SettingKeys.salaryUsualDay);
  final latestHist = stats[StatsRepo.salaryDayLatest];
  final latestSet = intSetting(SettingKeys.salaryLatestDay);
  final latest = [latestHist, latestSet, usual].whereType<int>().fold<int?>(null, (a, b) => a == null || b > a ? b : a);

  final onboardedAt = settings[SettingKeys.onboardedAt];
  List<PAccount> pAccounts(Map<int, int>? balances) => [
        for (final a in accounts)
          PAccount(
            id: a.id,
            name: a.name,
            type: AccountType.of(a.type),
            balance: balances?[a.id] ?? a.balance,
            includeInSpendable: a.includeInSpendable,
            creditLimit: a.creditLimit,
            linkedAccountId: a.linkedAccountId,
          ),
      ];
  ProjectionInput inputOf({
    required List<PAccount> accs,
    required List<PPlanned> pend,
    required Set<(String, int)> log,
    required int varSpent,
    ProjectionInput? startOfDay,
  }) =>
      ProjectionInput(
        today: today,
        yearMonth: month.yearMonth,
        accounts: accs,
        salaryExpected: month.salaryExpected,
        salaryReceived: month.salaryReceived,
        salaryAccountId: salaryAccountId,
        usualSalaryDay: usual,
        latestSalaryDay: latest,
        pendingPlanned: pend,
        dailyTemplates: daily,
        logged: log,
        trackingStart: onboardedAt == null ? null : Dates.parseIso(onboardedAt),
        variableBudget: budget,
        variableSpent: varSpent,
        comfortPct: intSetting(SettingKeys.comfortThresholdPct) ?? 10,
        cardWarnPct: intSetting(SettingKeys.cardWarnPct) ?? 80,
        startOfDay: startOfDay,
      );
  final input = inputOf(
    accs: pAccounts(null),
    pend: pending,
    log: logged,
    varSpent: variableSpent,
    startOfDay: inputOf(
      accs: pAccounts(sodBalance),
      pend: [...pending, for (final p in paidToday) toP(p)],
      log: {for (final l in logged) if (l.$1 != todayIso) l},
      varSpent: variableSpent - variableToday < 0 ? 0 : variableSpent - variableToday,
    ),
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
  final reserveCat = categories.values
      .where((c) => c.name == CatalogRepo.reserveCategoryName && c.tier == Tier.savings.value)
      .firstOrNull
      ?.id;
  var reservePlanned = 0, reserveActual = 0;
  for (final p in planned.where((p) => p.status != PlannedStatus.skipped.code)) {
    if (reserveCat != null && p.categoryId == reserveCat) {
      reservePlanned += p.amount;
      continue;
    }
    plannedT[tierOf(p)] = plannedT[tierOf(p)]! + p.amount;
  }
  // Daily is log-based: spent = what you logged in the Daily log; left = the usual amounts for
  // the days not logged yet (from when tracking started); planned = spent + left.
  final dailySpent = logs
      .where((l) => l.state != DailyLogState.skipped.code)
      .fold<int>(0, (sum, l) => sum + (l.amount ?? 0));
  final trackFrom = onboardedAt == null || Dates.parseIso(onboardedAt).isBefore(first) ? first : Dates.parseIso(onboardedAt);
  var dailyLeft = 0;
  for (final t in daily) {
    for (final d in ScheduleExpander.dailyOccurrences(t, trackFrom, last)) {
      if (!logged.contains((Dates.iso(d), t.id))) dailyLeft += t.amount;
    }
  }
  plannedT[Tier.daily] = dailySpent + dailyLeft;
  // Variable = everything else you spend: every expense that is neither a Daily log entry nor a
  // planned bill payment (Food or Groceries added with +, Misc, Shopping…).
  final otherRow = await db.customSelect(
    'SELECT COALESCE(SUM(t.amount), 0) AS s FROM transactions t '
    "WHERE t.month_id = ? AND t.type = 'expense' AND t.planned_id IS NULL "
    'AND t.id NOT IN (SELECT transaction_id FROM daily_logs WHERE transaction_id IS NOT NULL)',
    variables: [Variable.withInt(month.id)],
    readsFrom: {db.transactions, db.dailyLogs},
  ).getSingle();
  final otherSpent = otherRow.read<int>('s');
  // Variable budget = salary − everything already planned (daily costs, bills, savings, reserve…).
  // "Left" in the ring is this budget minus what you have spent outside the plan.
  final salary = month.salaryReceived ?? month.salaryExpected;
  final alreadyPlanned = plannedT[Tier.priority]! + plannedT[Tier.savings]! + plannedT[Tier.fixed]! +
      plannedT[Tier.daily]! + reservePlanned;
  final variableBudget = salary - alreadyPlanned;
  plannedT[Tier.variable] = variableBudget > 0 ? variableBudget : 0;
  final sums = await (db.select(db.monthSummary)..where((m) => m.monthId.equals(month.id))).get();
  for (final r in sums) {
    final c = categories[r.categoryId];
    if (c == null) continue;
    if (c.id == reserveCat) {
      reserveActual += r.actual;
      continue;
    }
    final t = Tier.of(c.tier);
    actualT[t] = actualT[t]! + r.actual;
  }
  actualT[Tier.daily] = dailySpent;
  actualT[Tier.variable] = otherSpent;

  final upcoming = planned.where((p) => p.status == PlannedStatus.pending.code).toList()
    ..sort((a, b) => (a.dueDate ?? '9999').compareTo(b.dueDate ?? '9999'));

  return DashboardData(
    month: month,
    projection: projection,
    tiers: TierTotals(plannedT, actualT, reservePlanned: reservePlanned, reserveActual: reserveActual),
    upcoming: upcoming,
    accounts: accounts,
    usualSalaryDay: usual,
    latestSalaryDay: latest,
    salaryAccountId: salaryAccountId,
  );
}
