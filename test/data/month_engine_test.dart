import 'package:brunt/core/constants.dart';
import 'package:brunt/data/db/database.dart';
import 'package:brunt/data/repositories/ledger.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  test('rollover is idempotent and carries closing → opening', () async {
    final h = Harness(DateTime(2026, 11, 7));
    final a = await h.standard();
    await h.ledger.add(Entry(type: TxType.expense, amount: 50000, date: h.now, accountId: a.cash));
    await h.engine.ensureCurrent(h.now);
    expect((await h.db.select(h.db.months).get()).length, 1);

    h.now = DateTime(2026, 12, 1);
    await h.engine.ensureCurrent(h.now);
    await h.engine.ensureCurrent(h.now);
    final months = await h.db.select(h.db.months).get();
    expect(months.length, 2);
    expect(months.first.status, 'closed');
    final dec = months.last;
    final opening = await (h.db.select(h.db.accountMonthBalances)
          ..where((b) => b.monthId.equals(dec.id) & b.accountId.equals(a.cash)))
        .getSingle();
    expect(opening.opening, 150000);
    final nov = await (h.db.select(h.db.accountMonthBalances)
          ..where((b) => b.monthId.equals(months.first.id) & b.accountId.equals(a.cash)))
        .getSingle();
    expect(nov.closing, 150000);
    await h.close();
  });

  test('rollover across a gap of several months and a year boundary', () async {
    final h = Harness(DateTime(2026, 11, 20));
    await h.standard();
    h.now = DateTime(2027, 3, 2);
    await h.engine.ensureCurrent(h.now);
    final yms = (await h.db.select(h.db.months).get()).map((m) => m.yearMonth).toList();
    expect(yms, ['2026-11', '2026-12', '2027-01', '2027-02', '2027-03']);
    await h.close();
  });

  test('missing salary is carried as a flag into the next month', () async {
    final h = Harness(DateTime(2026, 11, 20));
    await h.standard();
    h.now = DateTime(2026, 12, 1);
    await h.engine.ensureCurrent(h.now);
    expect((await h.engine.latest())!.salaryPendingCarried, isTrue);
    await h.close();
  });

  test('planned items generated with due day clamped to month length (Feb)', () async {
    final h = Harness(DateTime(2027, 1, 10));
    final a = await h.standard();
    await h.monthlyTemplate('Rent', 'Rent', 1200000, a.bank, dueDay: 31);
    var p = await (h.db.select(h.db.plannedItems)).getSingle();
    expect(p.dueDate, '2027-01-31');
    h.now = DateTime(2027, 2, 1);
    await h.engine.ensureCurrent(h.now);
    final feb = await h.engine.latest();
    p = await (h.db.select(h.db.plannedItems)..where((x) => x.monthId.equals(feb!.id))).getSingle();
    expect(p.dueDate, '2027-02-28');
    await h.close();
  });

  test('template end month stops generation', () async {
    final h = Harness(DateTime(2026, 11, 10));
    final a = await h.standard();
    final id = await h.monthlyTemplate('EMI', 'Loan EMI', 500000, a.bank, dueDay: 5);
    await h.catalog.updateTemplate(id, const TemplatesCompanion(endMonth: Value('2026-11')));
    h.now = DateTime(2026, 12, 1);
    await h.engine.ensureCurrent(h.now);
    final dec = await h.engine.latest();
    final items = await (h.db.select(h.db.plannedItems)..where((x) => x.monthId.equals(dec!.id))).get();
    expect(items, isEmpty);
    await h.close();
  });

  test('editing a closed month cascades balances forward', () async {
    final h = Harness(DateTime(2026, 11, 10));
    final a = await h.standard();
    h.now = DateTime(2027, 1, 3);
    await h.engine.ensureCurrent(h.now);
    // late entry in November (closed)
    await h.ledger.add(Entry(type: TxType.expense, amount: 10000, date: DateTime(2026, 11, 28), accountId: a.cash));
    final months = await h.db.select(h.db.months).get();
    Future<(int, int?)> amb(int i) async {
      final r = await (h.db.select(h.db.accountMonthBalances)
            ..where((b) => b.monthId.equals(months[i].id) & b.accountId.equals(a.cash)))
          .getSingle();
      return (r.opening, r.closing);
    }

    expect(await amb(0), (200000, 190000));
    expect(await amb(1), (190000, 190000));
    expect((await amb(2)).$1, 190000);
    expect(await h.engine.verifyBalances(), 0);
    expect(await amb(1), (190000, 190000));
    await h.close();
  });

  test('card bill is created after the statement day, once', () async {
    final h = Harness(DateTime(2026, 11, 2));
    final a = await h.standard(); // statement 5th, due 25th
    await h.ledger.add(Entry(type: TxType.expense, amount: 300000, date: h.now, accountId: a.card));
    expect(await h.engine.ensureCardBills(h.now), 0); // statement not reached
    h.now = DateTime(2026, 11, 6);
    await h.ledger.add(Entry(type: TxType.expense, amount: 50000, date: h.now, accountId: a.card)); // after statement
    expect(await h.engine.ensureCardBills(h.now), 1);
    expect(await h.engine.ensureCardBills(h.now), 0);
    final bill = await (h.db.select(h.db.plannedItems)..where((p) => p.cardAccountId.equals(a.card))).getSingle();
    expect(bill.amount, 300000); // spends after statement go to next bill
    expect(bill.dueDate, '2026-11-25');
    await h.ledger.payPlanned(bill.id, amount: bill.amount, accountId: a.bank, date: h.now);
    expect(await h.balance(a.card), 50000);
    await h.close();
  });
}
