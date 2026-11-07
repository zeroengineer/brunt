import 'package:brunt/core/constants.dart';
import 'package:brunt/data/repositories/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  late Harness h;
  late Std a;

  setUp(() async {
    h = Harness(DateTime(2026, 11, 7));
    a = await h.standard();
  });
  tearDown(() => h.close());

  test('expense from cash reduces balance', () async {
    await h.ledger.add(Entry(type: TxType.expense, amount: 4000, date: h.now, accountId: a.cash));
    expect(await h.balance(a.cash), 196000);
  });

  test('card spend raises outstanding, not cash', () async {
    await h.ledger.add(Entry(type: TxType.expense, amount: 50000, date: h.now, accountId: a.card));
    expect(await h.balance(a.card), 50000);
    expect(await h.balance(a.bank), 2000000);
  });

  test('UPI expense deducts the linked bank and keeps via label', () async {
    final id = await h.ledger.add(Entry(type: TxType.expense, amount: 12000, date: h.now, accountId: a.gpay));
    expect(await h.balance(a.bank), 1988000);
    final tx = await (h.db.select(h.db.transactions)..where((t) => t.id.equals(id))).getSingle();
    expect(tx.accountId, a.bank);
    expect(tx.viaUpiId, a.gpay);
  });

  test('transfers move money and are not spending (ATM, card payment, RD)', () async {
    await h.ledger.add(Entry(type: TxType.transfer, amount: 100000, date: h.now, accountId: a.bank, toAccountId: a.cash));
    expect(await h.balance(a.bank), 1900000);
    expect(await h.balance(a.cash), 300000);

    await h.ledger.add(Entry(type: TxType.expense, amount: 80000, date: h.now, accountId: a.card));
    await h.ledger.add(Entry(type: TxType.transfer, amount: 80000, date: h.now, accountId: a.bank, toAccountId: a.card));
    expect(await h.balance(a.card), 0);
    expect(await h.balance(a.bank), 1820000);

    await h.ledger.add(Entry(type: TxType.transfer, amount: 500000, date: h.now, accountId: a.bank, toAccountId: a.rd));
    expect(await h.balance(a.rd), 1500000);
  });

  test('transfer to the same account is rejected', () async {
    expect(
      () => h.ledger.add(Entry(type: TxType.transfer, amount: 100, date: h.now, accountId: a.gpay, toAccountId: a.bank)),
      throwsA(isA<LedgerException>()),
    );
  });

  test('income and salary add to the account; salary marks the month', () async {
    await h.ledger.receiveSalary(amount: 5000000, date: DateTime(2026, 11, 3), accountId: a.bank);
    expect(await h.balance(a.bank), 7000000);
    final m = await h.engine.latest();
    expect(m!.salaryReceived, 5000000);
    expect(m.salaryReceivedDate, '2026-11-03');
    expect(() => h.ledger.receiveSalary(amount: 1, date: h.now, accountId: a.bank), throwsA(isA<LedgerException>()));
  });

  test('deleting the salary entry reverts the month', () async {
    final id = await h.ledger.receiveSalary(amount: 5000000, date: h.now, accountId: a.bank);
    await h.ledger.delete(id);
    final m = await h.engine.latest();
    expect(m!.salaryReceived, isNull);
    expect(await h.balance(a.bank), 2000000);
  });

  test('edit reverses old effect and applies new one', () async {
    final id = await h.ledger.add(Entry(type: TxType.expense, amount: 4000, date: h.now, accountId: a.cash));
    await h.ledger.update(id, Entry(type: TxType.expense, amount: 6000, date: h.now, accountId: a.bank));
    expect(await h.balance(a.cash), 200000);
    expect(await h.balance(a.bank), 1994000);
  });

  test('adjust balance records the difference as Unaccounted', () async {
    await h.ledger.adjustBalance(a.cash, 150000);
    expect(await h.balance(a.cash), 150000);
    final tx = await (h.db.select(h.db.transactions)).getSingle();
    expect(tx.type, 'adjustment');
    expect(tx.amount, -50000);
    expect(tx.note, 'Unaccounted');
  });

  test('every write bumps the month version', () async {
    final v0 = (await h.engine.latest())!.version;
    await h.ledger.add(Entry(type: TxType.expense, amount: 100, date: h.now, accountId: a.cash));
    expect((await h.engine.latest())!.version, greaterThan(v0));
  });

  test('month_summary actual is write-through', () async {
    final food = await h.categoryId('Food');
    final id = await h.ledger.add(Entry(type: TxType.expense, amount: 3000, date: h.now, accountId: a.cash, categoryId: food));
    var row = await (h.db.select(h.db.monthSummary)..where((s) => s.categoryId.equals(food))).getSingle();
    expect(row.actual, 3000);
    await h.ledger.delete(id);
    row = await (h.db.select(h.db.monthSummary)..where((s) => s.categoryId.equals(food))).getSingle();
    expect(row.actual, 0);
  });

  test('paying a planned item: expense, editable amount, idempotent', () async {
    await h.monthlyTemplate('Rent', 'Rent', 1200000, a.bank, dueDay: 5);
    final p = await (h.db.select(h.db.plannedItems)).getSingle();
    final tx1 = await h.ledger.payPlanned(p.id, amount: 1210000, accountId: a.gpay, date: h.now);
    final tx2 = await h.ledger.payPlanned(p.id, amount: 1210000, accountId: a.gpay, date: h.now);
    expect(tx1, tx2);
    expect(await h.balance(a.bank), 2000000 - 1210000);
    final paid = await (h.db.select(h.db.plannedItems)).getSingle();
    expect(paid.status, 'paid');
  });

  test('savings template with target account is paid as a transfer', () async {
    await h.monthlyTemplate('RD', 'RD', 500000, a.bank, dueDay: 10, toAccount: a.rd);
    final p = await (h.db.select(h.db.plannedItems)).getSingle();
    final txId = await h.ledger.payPlanned(p.id, amount: 500000, accountId: a.bank, date: h.now);
    final tx = await (h.db.select(h.db.transactions)..where((t) => t.id.equals(txId))).getSingle();
    expect(tx.type, 'transfer');
    expect(await h.balance(a.rd), 1500000);
  });

  test('daily log confirm creates expense; skip removes it', () async {
    final t = await h.dailyTemplate('Bus fare', 4000, a.cash);
    await h.ledger.logDaily(date: h.now, templateId: t, state: DailyLogState.confirmed);
    expect(await h.balance(a.cash), 196000);
    await h.ledger.logDaily(date: h.now, templateId: t, state: DailyLogState.edited, amount: 6000);
    expect(await h.balance(a.cash), 194000);
    await h.ledger.logDaily(date: h.now, templateId: t, state: DailyLogState.skipped);
    expect(await h.balance(a.cash), 200000);
    final log = await (h.db.select(h.db.dailyLogs)).getSingle();
    expect(log.state, 'skipped');
  });

  test('verify balances finds and repairs a corrupted cache', () async {
    await h.ledger.add(Entry(type: TxType.expense, amount: 4000, date: h.now, accountId: a.cash));
    await h.db.customStatement('UPDATE accounts SET balance = 1 WHERE id = ${a.cash}');
    expect(await h.engine.verifyBalances(), 1);
    expect(await h.balance(a.cash), 196000);
    expect(await h.engine.verifyBalances(), 0);
  });

  test('UPI accounts cannot be adjusted', () async {
    expect(() => h.ledger.adjustBalance(a.gpay, 100), throwsA(isA<LedgerException>()));
  });
}
