import 'package:brunt/core/constants.dart';
import 'package:brunt/core/dates.dart';
import 'package:brunt/domain/projection/projection_engine.dart';
import 'package:brunt/domain/schedule/schedule_expander.dart';
import 'package:flutter_test/flutter_test.dart';

const cash = PAccount(id: 1, name: 'Cash', type: AccountType.cash, balance: 300000);
const bank = PAccount(id: 2, name: 'HDFC', type: AccountType.bank, balance: 2000000);
const gpay = PAccount(id: 3, name: 'GPay', type: AccountType.upi, balance: 0, linkedAccountId: 2);
const card = PAccount(id: 4, name: 'ICICI', type: AccountType.creditCard, balance: 0, creditLimit: 10000000);
const rd = PAccount(id: 5, name: 'RD', type: AccountType.savings, balance: 5000000, includeInSpendable: false);

TemplateSpec bus({int mask = WeekMask.all, int amount = 4000, int account = 1}) => TemplateSpec(
    id: 10, name: 'Bus', categoryId: 1, amount: amount, frequency: Frequency.daily, daysOfWeek: mask, accountId: account);

ProjectionInput input({
  DateTime? today,
  List<PAccount> accounts = const [cash, bank, gpay, card, rd],
  int salary = 5000000,
  int? received,
  List<PPlanned> planned = const [],
  List<TemplateSpec> daily = const [],
  Set<(String, int)> logged = const {},
  int budget = 0,
  int spent = 0,
  int? usual,
  int? latest,
}) =>
    ProjectionInput(
      today: today ?? DateTime(2026, 11, 1), // Sunday
      yearMonth: '2026-11',
      accounts: accounts,
      salaryExpected: salary,
      salaryReceived: received,
      salaryAccountId: 2,
      usualSalaryDay: usual,
      latestSalaryDay: latest,
      pendingPlanned: planned,
      dailyTemplates: daily,
      logged: logged,
      variableBudget: budget,
      variableSpent: spent,
    );

void main() {
  test('balance_now counts spendable accounts only (no savings, cards, UPI)', () {
    final p = ProjectionEngine.compute(input());
    expect(p.balanceNow, 2300000);
  });

  test('month-end projection with salary pending, committed, daily and variable', () {
    final p = ProjectionEngine.compute(input(
      planned: [
        PPlanned(name: 'Rent', amount: 1500000, tier: Tier.fixed, dueDate: DateTime(2026, 11, 5), payingAccountId: 3),
        PPlanned(name: 'RD', amount: 500000, tier: Tier.savings, dueDate: DateTime(2026, 11, 10), payingAccountId: 2),
      ],
      daily: [bus()],
      budget: 600000,
      spent: 100000,
    ));
    expect(p.committedLeft, 2000000);
    expect(p.dailyLeft, 30 * 4000); // November has 30 days
    expect(p.variableLeft, 500000);
    expect(p.projectedEnd, 2300000 + 5000000 - 2000000 - 120000 - 500000);
    expect(p.status, MonthStatus.comfortable);
    expect(p.daysLeft, 30);
    expect(p.safePerDay, (2300000 + 5000000 - 2000000 - 500000) ~/ 30);
  });

  test('salary already received is not double counted', () {
    final p = ProjectionEngine.compute(input(received: 5000000));
    expect(p.pendingSalary, 0);
    expect(p.projectedEnd, 2300000);
    expect(p.gap, isNull);
  });

  test('Sunday on/off changes daily_left', () {
    final all = ProjectionEngine.compute(input(daily: [bus()]));
    final noSun = ProjectionEngine.compute(input(daily: [bus(mask: WeekMask.toggle(WeekMask.all, DateTime.sunday))]));
    // November 2026 has 5 Sundays (1, 8, 15, 22, 29)
    expect(all.dailyLeft - noSun.dailyLeft, 5 * 4000);
  });

  test('logged days are not projected again; today logged shrinks days_left', () {
    final today = DateTime(2026, 11, 10);
    final logged = {for (final d in Dates.range(DateTime(2026, 11, 1), today)) (Dates.iso(d), 10)};
    final p = ProjectionEngine.compute(input(today: today, daily: [bus()], logged: logged));
    expect(p.dailyLeft, 20 * 4000);
    expect(p.daysLeft, 20);
  });

  test('unconfirmed past days are assumed at the usual amount', () {
    final p = ProjectionEngine.compute(input(today: DateTime(2026, 11, 10), daily: [bus()]));
    expect(p.dailyLeft, 30 * 4000);
  });

  test('card spends are excluded from cash projection', () {
    final p = ProjectionEngine.compute(input(daily: [bus(account: 4)]));
    expect(p.dailyLeft, 0);
  });

  test('status thresholds: tight and short', () {
    final tight = ProjectionEngine.compute(input(
        accounts: const [PAccount(id: 1, name: 'Cash', type: AccountType.cash, balance: 0)],
        salary: 1000000,
        planned: [const PPlanned(name: 'Rent', amount: 950000, tier: Tier.fixed)]));
    expect(tight.projectedEnd, 50000);
    expect(tight.status, MonthStatus.tight);

    final short = ProjectionEngine.compute(input(
        accounts: const [PAccount(id: 1, name: 'Cash', type: AccountType.cash, balance: 0)],
        salary: 1000000,
        planned: [const PPlanned(name: 'Rent', amount: 1100000, tier: Tier.fixed)]));
    expect(short.status, MonthStatus.short);
    expect(short.shortBy, 100000);
  });

  test('gap check before late salary', () {
    final p = ProjectionEngine.compute(input(
      today: DateTime(2026, 11, 1),
      accounts: const [PAccount(id: 1, name: 'Cash', type: AccountType.cash, balance: 20000)],
      daily: [bus()],
      usual: 3,
      latest: 7,
      planned: [PPlanned(name: 'Phone', amount: 30000, tier: Tier.fixed, dueDate: DateTime(2026, 11, 4), payingAccountId: 1)],
    ));
    expect(p.gap, isNotNull);
    expect(p.gap!.gapDays, 6);
    expect(p.gap!.need, 6 * 4000 + 30000);
    expect(p.gap!.ok, isFalse);
    expect(p.gap!.shortBy, 6 * 4000 + 30000 - 20000);
  });

  test('salary later than ever is flagged', () {
    final p = ProjectionEngine.compute(input(today: DateTime(2026, 11, 9), usual: 3, latest: 7));
    expect(p.gap!.beyondHistory, isTrue);
    expect(p.warnings.any((w) => w.kind == WarningKind.salaryLate), isTrue);
  });

  test('cash run-out warning names the day and the amount', () {
    final p = ProjectionEngine.compute(input(
      received: 5000000,
      accounts: const [PAccount(id: 1, name: 'Cash', type: AccountType.cash, balance: 70000), bank],
      daily: [bus()],
    ));
    final w = p.warnings.firstWhere((w) => w.kind == WarningKind.runOut);
    // ₹700 / ₹40 per day → 17 days covered, runs out on the 18th
    expect(w.day, DateTime(2026, 11, 18));
    expect(w.amount, 30 * 4000 - 70000);
    expect(w.message, contains('18th'));
    expect(w.message, startsWith('Cash runs out'));
  });

  test('card at 80% of limit warns', () {
    final p = ProjectionEngine.compute(input(accounts: const [
      PAccount(id: 4, name: 'ICICI', type: AccountType.creditCard, balance: 8500000, creditLimit: 10000000),
    ]));
    expect(p.warnings.any((w) => w.kind == WarningKind.cardLimit && w.message.contains('85%')), isTrue);
  });

  test('mid-month template change only affects remaining days', () {
    final today = DateTime(2026, 11, 16);
    final logged = {for (final d in Dates.range(DateTime(2026, 11, 1), DateTime(2026, 11, 15))) (Dates.iso(d), 10)};
    final p = ProjectionEngine.compute(input(today: today, daily: [bus(amount: 5000)], logged: logged));
    expect(p.dailyLeft, 15 * 5000);
  });

  test('tracking start ignores days before onboarding', () {
    final p = ProjectionEngine.compute(ProjectionInput(
      today: DateTime(2026, 11, 20),
      yearMonth: '2026-11',
      accounts: const [cash],
      salaryExpected: 0,
      dailyTemplates: [bus()],
      trackingStart: DateTime(2026, 11, 20),
    ));
    expect(p.dailyLeft, 11 * 4000);
  });
}
