import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../schedule/schedule_expander.dart';

/// Account as the projection sees it.
class PAccount {
  const PAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.includeInSpendable = true,
    this.creditLimit,
    this.linkedAccountId,
  });

  final int id;
  final String name;
  final AccountType type;

  /// Balance, or outstanding due for cards.
  final int balance;
  final bool includeInSpendable;
  final int? creditLimit;
  final int? linkedAccountId;
}

/// A pending planned item (priority / savings / fixed / card bill).
class PPlanned {
  const PPlanned({required this.name, required this.amount, required this.tier, this.dueDate, this.payingAccountId});
  final String name;
  final int amount;
  final Tier tier;
  final DateTime? dueDate;
  final int? payingAccountId;
}

class ProjectionInput {
  const ProjectionInput({
    required this.today,
    required this.yearMonth,
    required this.accounts,
    required this.salaryExpected,
    this.salaryReceived,
    this.salaryAccountId,
    this.usualSalaryDay,
    this.latestSalaryDay,
    this.pendingPlanned = const [],
    this.dailyTemplates = const [],
    this.logged = const {},
    this.trackingStart,
    this.variableBudget = 0,
    this.variableSpent = 0,
    this.comfortPct = 10,
    this.cardWarnPct = 80,
  });

  final DateTime today;
  final String yearMonth;
  final List<PAccount> accounts;
  final int salaryExpected;
  final int? salaryReceived;
  final int? salaryAccountId;
  final int? usualSalaryDay;
  final int? latestSalaryDay;
  final List<PPlanned> pendingPlanned;

  /// Daily templates with `amount` already set to the learned average.
  final List<TemplateSpec> dailyTemplates;

  /// (iso date, template id) pairs that are already logged (confirmed, edited or skipped).
  final Set<(String, int)> logged;

  /// Day tracking started (onboarding). Unlogged days before it are ignored.
  final DateTime? trackingStart;
  final int variableBudget;
  final int variableSpent;
  final int comfortPct;
  final int cardWarnPct;
}

enum MonthStatus { comfortable, tight, short }

class GapCheck {
  const GapCheck({
    required this.gapDays,
    required this.need,
    required this.available,
    required this.untilDate,
    this.beyondHistory = false,
  });

  final int gapDays;
  final int need;
  final int available;
  final DateTime untilDate;

  /// Salary is later than the latest day it has ever come.
  final bool beyondHistory;
  bool get ok => available >= need;
  int get shortBy => ok ? 0 : need - available;
}

enum WarningKind { runOut, cardLimit, salaryLate, overdue }

class AccountWarning {
  const AccountWarning({required this.kind, required this.message, this.accountId, this.day, this.amount});
  final WarningKind kind;
  final String message;
  final int? accountId;
  final DateTime? day;
  final int? amount;
}

class Projection {
  const Projection({
    required this.balanceNow,
    required this.pendingSalary,
    required this.committedLeft,
    required this.dailyLeft,
    required this.variableLeft,
    required this.daysLeft,
    required this.projectedEnd,
    required this.safePerDay,
    required this.status,
    required this.threshold,
    this.gap,
    this.warnings = const [],
  });

  final int balanceNow;
  final int pendingSalary;
  final int committedLeft;
  final int dailyLeft;
  final int variableLeft;
  final int daysLeft;
  final int projectedEnd;
  final int safePerDay;
  final MonthStatus status;
  final int threshold;
  final GapCheck? gap;
  final List<AccountWarning> warnings;

  int get shortBy => projectedEnd < 0 ? -projectedEnd : 0;
}

/// Pure projection maths (spec §5). No Flutter, no DB — fully unit tested.
abstract final class ProjectionEngine {
  static Projection compute(ProjectionInput i) {
    final today = Dates.day(i.today);
    final monthStart = Dates.firstOfYearMonth(i.yearMonth);
    final monthEnd = Dates.lastOfMonth(monthStart);
    final byId = {for (final a in i.accounts) a.id: a};

    /// Resolves UPI → bank. Null when unknown.
    PAccount? resolve(int? id) {
      if (id == null) return null;
      final a = byId[id];
      if (a == null) return null;
      if (a.type == AccountType.upi) return byId[a.linkedAccountId];
      return a;
    }

    bool spendable(PAccount a) =>
        a.includeInSpendable && a.type != AccountType.creditCard && a.type != AccountType.upi;

    /// Will money for this item leave the spendable pool this month?
    /// Null account = unknown → assume yes. Card → no (it goes on the card's next bill).
    bool hitsSpendable(int? accountId) {
      if (accountId == null) return true;
      final a = resolve(accountId);
      if (a == null) return true;
      return spendable(a);
    }

    final balanceNow = i.accounts.where(spendable).fold<int>(0, (s, a) => s + a.balance);
    final pendingSalary = i.salaryReceived == null ? i.salaryExpected : 0;

    final committed = i.pendingPlanned.where((p) => p.tier.isCommitted);
    final committedLeft =
        committed.where((p) => hitsSpendable(p.payingAccountId)).fold<int>(0, (s, p) => s + p.amount);

    // ----- daily: every (day, template) occurrence in the month not yet logged
    final from = i.trackingStart == null || i.trackingStart!.isBefore(monthStart) ? monthStart : Dates.day(i.trackingStart!);
    final unlogged = <(DateTime, TemplateSpec)>[];
    for (final t in i.dailyTemplates) {
      for (final d in ScheduleExpander.dailyOccurrences(t, from, monthEnd)) {
        if (!i.logged.contains((Dates.iso(d), t.id))) unlogged.add((d, t));
      }
    }
    final dailyLeft = unlogged.where((e) => hitsSpendable(e.$2.accountId)).fold<int>(0, (s, e) => s + e.$2.amount);

    final variableLeft = i.variableBudget - i.variableSpent > 0 ? i.variableBudget - i.variableSpent : 0;

    // days_left: inclusive of today unless today is fully logged
    var daysLeft = monthEnd.difference(today).inDays + 1;
    final todayItems = i.dailyTemplates.where((t) => ScheduleExpander.dailyOccurrences(t, today, today).isNotEmpty).toList();
    final todayLogged = todayItems.isNotEmpty && todayItems.every((t) => i.logged.contains((Dates.iso(today), t.id)));
    if (todayLogged && daysLeft > 1) daysLeft -= 1;
    if (daysLeft < 1) daysLeft = 1;

    final projectedEnd = balanceNow + pendingSalary - committedLeft - dailyLeft - variableLeft;
    final perDayPool = balanceNow + pendingSalary - committedLeft - variableLeft;
    final safePerDay = perDayPool <= 0 ? 0 : perDayPool ~/ daysLeft;

    final threshold = Money.percent(i.salaryExpected, i.comfortPct);
    final status = projectedEnd < 0
        ? MonthStatus.short
        : (projectedEnd < threshold ? MonthStatus.tight : MonthStatus.comfortable);

    // ----- gap check (before salary arrives)
    GapCheck? gap;
    final warnings = <AccountWarning>[];
    if (i.salaryReceived == null && i.salaryExpected > 0) {
      final latest = i.latestSalaryDay ?? i.usualSalaryDay;
      if (latest != null) {
        final until = Dates.clampDay(monthStart.year, monthStart.month, latest);
        final beyond = !until.isAfter(today);
        final end = beyond ? today.add(const Duration(days: 1)) : until;
        final gapDaily = unlogged
            .where((e) => e.$1.isBefore(end) && hitsSpendable(e.$2.accountId))
            .fold<int>(0, (s, e) => s + e.$2.amount);
        final gapItems = committed
            .where((p) => p.dueDate != null && p.dueDate!.isBefore(end) && hitsSpendable(p.payingAccountId))
            .fold<int>(0, (s, p) => s + p.amount);
        gap = GapCheck(
          gapDays: beyond ? 0 : until.difference(today).inDays,
          need: gapDaily + gapItems,
          available: balanceNow,
          untilDate: until,
          beyondHistory: beyond,
        );
        if (beyond) {
          warnings.add(AccountWarning(
            kind: WarningKind.salaryLate,
            message: 'Salary is later than it has ever come (latest was the ${Dates.ordinal(latest)}).',
          ));
        }
      }
    }

    // ----- overdue items
    final overdue = committed.where((p) => p.dueDate != null && p.dueDate!.isBefore(today)).toList();
    if (overdue.isNotEmpty) {
      final total = overdue.fold<int>(0, (s, p) => s + p.amount);
      warnings.add(AccountWarning(
        kind: WarningKind.overdue,
        amount: total,
        message: overdue.length == 1
            ? '${overdue.first.name} is overdue.'
            : '${overdue.length} bills are overdue (${Money.format(total)}).',
      ));
    }

    // ----- per-account run-out simulation
    int? salaryDay;
    if (pendingSalary > 0) {
      final usual = i.usualSalaryDay;
      final latest = i.latestSalaryDay ?? usual;
      if (usual != null && usual >= today.day) {
        salaryDay = usual;
      } else if (latest != null && latest >= today.day) {
        salaryDay = latest;
      }
    }
    for (final a in i.accounts) {
      if (!a.type.holdsBalance || a.type == AccountType.creditCard || a.type == AccountType.savings) continue;
      var b = a.balance;
      var minB = b;
      DateTime? runOut;
      for (final d in Dates.range(today, monthEnd)) {
        if (salaryDay != null && d.day == salaryDay && resolve(i.salaryAccountId)?.id == a.id) b += pendingSalary;
        for (final e in unlogged) {
          final acc = resolve(e.$2.accountId);
          final onDay = DateUtilsLite.sameDay(e.$1, d) || (DateUtilsLite.sameDay(d, today) && e.$1.isBefore(today));
          if (onDay && acc?.id == a.id) b -= e.$2.amount;
        }
        for (final p in committed) {
          final acc = resolve(p.payingAccountId);
          if (acc?.id != a.id) continue;
          final due = p.dueDate == null || p.dueDate!.isBefore(today) ? today : p.dueDate!;
          if (DateUtilsLite.sameDay(due, d)) b -= p.amount;
        }
        if (b < 0 && runOut == null) runOut = d;
        if (b < minB) minB = b;
      }
      if (runOut != null) {
        final need = -minB;
        final verb = a.type == AccountType.cash ? 'Withdraw' : 'Add';
        warnings.add(AccountWarning(
          kind: WarningKind.runOut,
          accountId: a.id,
          day: runOut,
          amount: need,
          message: DateUtilsLite.sameDay(runOut, today)
              ? '${a.name} is already short at your usual spend. $verb ${Money.format(need)} soon.'
              : '${a.name} runs out around the ${Dates.ordinal(runOut.day)} at your usual spend. '
                  '$verb ${Money.format(need)} before then.',
        ));
      }
    }

    // ----- card limit warnings
    for (final a in i.accounts.where((a) => a.type == AccountType.creditCard)) {
      final limit = a.creditLimit;
      if (limit == null || limit <= 0) continue;
      final pct = a.balance * 100 ~/ limit;
      if (pct >= i.cardWarnPct) {
        warnings.add(AccountWarning(
          kind: WarningKind.cardLimit,
          accountId: a.id,
          amount: a.balance,
          message: '${a.name} is at $pct% of its limit (${Money.format(limit - a.balance)} available).',
        ));
      }
    }

    return Projection(
      balanceNow: balanceNow,
      pendingSalary: pendingSalary,
      committedLeft: committedLeft,
      dailyLeft: dailyLeft,
      variableLeft: variableLeft,
      daysLeft: daysLeft,
      projectedEnd: projectedEnd,
      safePerDay: safePerDay,
      status: status,
      threshold: threshold,
      gap: gap,
      warnings: warnings,
    );
  }
}

abstract final class DateUtilsLite {
  static bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
