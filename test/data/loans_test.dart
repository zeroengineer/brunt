import 'package:brunt/core/constants.dart';
import 'package:brunt/data/db/database.dart';
import 'package:brunt/data/repositories/ledger.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  test('borrowed: money in, owed shown on the Borrowed account, pay-back planned and paid', () async {
    final h = Harness(DateTime(2026, 11, 7));
    final a = await h.standard();
    final loan = await h.catalog.ensureSystemAccount(AccountType.loan);
    expect(await h.catalog.ensureSystemAccount(AccountType.loan), loan, reason: 'idempotent');
    final acc = await (h.db.select(h.db.accounts)..where((x) => x.id.equals(loan))).getSingle();
    expect(acc.includeInSpendable, isFalse);

    await h.ledger.add(Entry(type: TxType.transfer, amount: 200000, date: h.now, accountId: loan, toAccountId: a.bank, note: 'Borrowed from Ravi'));
    expect(await h.balance(a.bank), 2200000);
    expect(await h.balance(loan), 200000, reason: 'liability: balance is what is owed');

    final debt = await h.categoryId('Debt');
    await h.catalog.createTemplate(TemplatesCompanion.insert(
      categoryId: debt,
      name: 'Pay back Ravi',
      defaultAmount: 200000,
      defaultAccountId: Value(a.bank),
      toAccountId: Value(loan),
      frequency: const Value('one_time'),
      dueDay: const Value(20),
      startMonth: const Value('2026-11'),
      endMonth: const Value('2026-11'),
    ));
    final p = await (h.db.select(h.db.plannedItems)..where((x) => x.name.equals('Pay back Ravi'))).getSingle();
    expect(p.dueDate, '2026-11-20');
    final txId = await h.ledger.payPlanned(p.id, amount: 200000, accountId: a.bank, date: DateTime(2026, 11, 20));
    final tx = await (h.db.select(h.db.transactions)..where((t) => t.id.equals(txId))).getSingle();
    expect(tx.type, 'transfer');
    expect(await h.balance(loan), 0);
    expect(await h.balance(a.bank), 2000000);
    expect(await h.engine.verifyBalances(), 0);
    await h.close();
  });

  test('borrowed with pay-back next month: planned item appears after rollover', () async {
    final h = Harness(DateTime(2026, 11, 7));
    final a = await h.standard();
    final loan = await h.catalog.ensureSystemAccount(AccountType.loan);
    final debt = await h.categoryId('Debt');
    await h.catalog.createTemplate(TemplatesCompanion.insert(
      categoryId: debt, name: 'Pay back Asha', defaultAmount: 50000,
      defaultAccountId: Value(a.bank), toAccountId: Value(loan),
      frequency: const Value('one_time'), dueDay: const Value(5),
      startMonth: const Value('2026-12'), endMonth: const Value('2026-12'),
    ));
    expect(await (h.db.select(h.db.plannedItems)).get(), isEmpty);
    h.now = DateTime(2026, 12, 1);
    await h.engine.ensureCurrent(h.now);
    final p = await (h.db.select(h.db.plannedItems)).getSingle();
    expect(p.dueDate, '2026-12-05');
    h.now = DateTime(2027, 1, 1);
    await h.engine.ensureCurrent(h.now);
    expect((await (h.db.select(h.db.plannedItems)).get()).length, 1, reason: 'one-time: not repeated');
    await h.close();
  });

  test('lent: money leaves spendable into Lent out and comes back', () async {
    final h = Harness(DateTime(2026, 11, 7));
    final a = await h.standard();
    final lent = await h.catalog.ensureSystemAccount(AccountType.lent);
    await h.ledger.add(Entry(type: TxType.transfer, amount: 150000, date: h.now, accountId: a.bank, toAccountId: lent, note: 'Lent to Dev'));
    expect(await h.balance(a.bank), 1850000);
    expect(await h.balance(lent), 150000);
    await h.ledger.add(Entry(type: TxType.transfer, amount: 150000, date: h.now, accountId: lent, toAccountId: a.cash));
    expect(await h.balance(lent), 0);
    expect(await h.balance(a.cash), 350000);
    await h.close();
  });
}
