import 'package:brunt/core/constants.dart';
import 'package:brunt/data/repositories/ledger.dart';
import 'package:brunt/data/repositories/queries.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  test('report rows join names and honour month and filters', () async {
    final h = Harness(DateTime(2026, 11, 7));
    final a = await h.standard();
    final food = await h.categoryId('Food');
    await h.ledger.add(Entry(type: TxType.expense, amount: 12000, date: h.now, accountId: a.gpay, categoryId: food, note: 'Lunch'));
    await h.ledger.add(Entry(type: TxType.transfer, amount: 100000, date: h.now, accountId: a.bank, toAccountId: a.cash));
    h.now = DateTime(2026, 12, 2);
    await h.engine.ensureCurrent(h.now);
    await h.ledger.add(Entry(type: TxType.expense, amount: 5000, date: h.now, accountId: a.cash, categoryId: food));
    final months = await h.queries.months();

    final all = await h.queries.reportRows(const HistoryFilter());
    expect(all.length, 3);
    expect(all.first.account, 'HDFC');
    expect(all.first.via, 'GPay');
    expect(all.first.category, 'Food');
    expect(all[1].toAccount, 'Cash');

    final nov = await h.queries.reportRows(HistoryFilter(monthId: months.first.id));
    expect(nov.map((r) => r.month).toSet(), {'2026-11'});
    expect(nov.length, 2);

    final dec = await h.queries.reportRows(HistoryFilter(monthId: months.last.id, categoryId: food));
    expect(dec.single.amount, 5000);
    await h.close();
  });
}
