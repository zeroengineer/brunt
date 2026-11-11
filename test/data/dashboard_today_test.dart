import 'package:brunt/app/session.dart';
import 'package:brunt/core/constants.dart';
import 'package:brunt/data/db/database.dart';
import 'package:brunt/data/repositories/ledger.dart';
import 'package:brunt/features/dashboard/dashboard_data.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  final day = DateTime(2026, 11, 10);

  test('safe to spend today: as-usual logs keep it, overage lowers it, edits do not change other days', () async {
    final h = Harness(day);
    final a = await h.standard();
    final bus = await h.dailyTemplate('Bus', 4000, a.cash, variable: true);
    final s = Session(h.db);

    final d0 = (await buildDashboard(s, day))!.projection;
    expect(d0.safeToday, d0.dayAllowance);

    await h.ledger.logDaily(date: day, templateId: bus, state: DailyLogState.confirmed);
    final d1 = (await buildDashboard(s, day))!.projection;
    expect(d1.dayAllowance, d0.dayAllowance);
    expect(d1.safeToday, d0.dayAllowance);

    // Edited to ₹100 → ₹60 over the usual. Only today changes: the remaining days stay at ₹40.
    await h.ledger.logDaily(date: day, templateId: bus, state: DailyLogState.edited, amount: 10000);
    final d2 = (await buildDashboard(s, day))!.projection;
    expect(d2.safeToday, d0.dayAllowance - 6000);
    expect(d2.dailyLeft, d1.dailyLeft, reason: 'one day edit must not change the forecast for other days');

    // Next day: the overspend is now part of the starting point, today's figure resets.
    final next = day.add(const Duration(days: 1));
    final d3 = (await buildDashboard(s, next))!.projection;
    expect(d3.safeToday, d3.dayAllowance);
    await h.close();
  });

  test('reserve: counted as committed, set aside into a non-spendable account, shown with the bank', () async {
    final h = Harness(day);
    final a = await h.standard();
    final s = Session(h.db);
    final before = (await buildDashboard(s, day))!.projection;

    final reserve = await h.catalog.ensureReserveAccount(a.bank);
    expect(await h.catalog.ensureReserveAccount(a.bank), reserve, reason: 'idempotent');
    final acc = await (h.db.select(h.db.accounts)..where((x) => x.id.equals(reserve))).getSingle();
    expect(acc.type, AccountType.reserve.code);
    expect(acc.linkedAccountId, a.bank);
    expect(acc.includeInSpendable, isFalse);

    await h.catalog.createTemplate(TemplatesCompanion.insert(
      categoryId: await h.catalog.ensureReserveCategory(),
      name: 'Reserve',
      defaultAmount: 500000,
      defaultAccountId: Value(a.bank),
      toAccountId: Value(reserve),
      dueDay: const Value(12),
    ));
    final pending = (await buildDashboard(s, day))!.projection;
    expect(pending.projectedEnd, before.projectedEnd - 500000);

    final p = await (h.db.select(h.db.plannedItems)..where((x) => x.name.equals('Reserve'))).getSingle();
    await h.ledger.payPlanned(p.id, amount: 500000, accountId: a.bank, date: day);
    expect(await h.balance(a.bank), 1500000);
    expect(await h.balance(reserve), 500000);

    final paid = (await buildDashboard(s, day))!;
    expect(paid.projection.balanceNow, before.balanceNow - 500000, reason: 'reserve is not spendable');
    expect(paid.projection.projectedEnd, pending.projectedEnd);
    expect(paid.projection.safeToday, paid.projection.dayAllowance, reason: 'setting aside is planned, not spending');
    expect(await h.engine.verifyBalances(), 0);
    await h.close();
  });

  test('reserve has its own part of the ring, and this month amount can change', () async {
    final h = Harness(day);
    final a = await h.standard();
    final s = Session(h.db);
    final reserve = await h.catalog.ensureReserveAccount(a.bank);
    await h.catalog.createTemplate(TemplatesCompanion.insert(
      categoryId: await h.catalog.ensureReserveCategory(),
      name: 'Reserve',
      defaultAmount: 500000,
      defaultAccountId: Value(a.bank),
      toAccountId: Value(reserve),
      dueDay: const Value(12),
    ));
    var d = (await buildDashboard(s, day))!;
    expect(d.tiers.reservePlanned, 500000);
    expect(d.tiers.planned[Tier.savings], 0, reason: 'reserve is not counted inside Savings');
    final before = d.projection.projectedEnd;

    final p = await (h.db.select(h.db.plannedItems)..where((x) => x.name.equals('Reserve'))).getSingle();
    await h.ledger.setPlannedAmount(p.id, 200000);
    d = (await buildDashboard(s, day))!;
    expect(d.tiers.reservePlanned, 200000);
    expect(d.projection.projectedEnd, before + 300000);
    final t = await (h.db.select(h.db.templates)..where((x) => x.name.equals('Reserve'))).getSingle();
    expect(t.defaultAmount, 500000, reason: 'the usual amount is untouched');

    await h.ledger.payPlanned(p.id, amount: 200000, accountId: a.bank, date: day);
    d = (await buildDashboard(s, day))!;
    expect(d.tiers.reserveActual, 200000);
    await h.close();
  });

  test('ring Daily is log-based: spent = daily log, left = days still to come', () async {
    final h = Harness(day);
    final a = await h.standard();
    await h.settings.set(SettingKeys.onboardedAt, '2026-11-01');
    final bus = await h.dailyTemplate('Bus', 4000, a.cash); // ₹40 every day, 30 days
    final s = Session(h.db);
    await h.ledger.logDaily(date: DateTime(2026, 11, 9), templateId: bus, state: DailyLogState.edited, amount: 6000);
    await h.ledger.logDaily(date: day, templateId: bus, state: DailyLogState.confirmed);
    await h.ledger.logDaily(date: DateTime(2026, 11, 8), templateId: bus, state: DailyLogState.skipped);
    // An extra Food expense outside the Daily log does not count as Daily.
    await h.ledger.add(Entry(type: TxType.expense, amount: 50000, date: day, accountId: a.cash, categoryId: await h.categoryId('Food')));

    final d = (await buildDashboard(s, day))!;
    expect(d.tiers.actual[Tier.daily], 10000); // ₹60 + ₹40
    expect(d.tiers.planned[Tier.daily], 10000 + 27 * 4000); // + 27 days not logged yet
    await h.close();
  });

  test('ring Variable = every expense except Daily log entries and planned bills', () async {
    final h = Harness(day);
    final a = await h.standard();
    final bus = await h.dailyTemplate('Bus', 4000, a.cash);
    final s = Session(h.db);
    await h.ledger.logDaily(date: day, templateId: bus, state: DailyLogState.confirmed); // daily log: not variable
    await h.ledger.add(Entry(type: TxType.expense, amount: 50000, date: day, accountId: a.cash, categoryId: await h.categoryId('Food')));
    await h.ledger.add(Entry(type: TxType.expense, amount: 10000, date: day, accountId: a.cash, categoryId: await h.categoryId('Misc')));
    await h.monthlyTemplate('Rent', 'Rent', 100000, a.bank, dueDay: 5);
    final rent = await (h.db.select(h.db.plannedItems)..where((x) => x.name.equals('Rent'))).getSingle();
    await h.ledger.payPlanned(rent.id, amount: 100000, accountId: a.bank, date: day); // planned: not variable

    final d = (await buildDashboard(s, day))!;
    expect(d.tiers.actual[Tier.variable], 60000);
    // budget = salary ₹50,000 − (rent ₹1,000 + bus ₹40 × 30 days)
    expect(d.tiers.planned[Tier.variable], 5000000 - 100000 - 30 * 4000);
    await h.close();
  });
}
