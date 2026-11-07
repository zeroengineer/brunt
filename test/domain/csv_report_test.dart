import 'package:brunt/core/constants.dart';
import 'package:brunt/data/repositories/ledger.dart';
import 'package:brunt/data/repositories/queries.dart';
import 'package:brunt/domain/report/csv_report.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  test('CSV: header, quoting, totals and formula neutralisation', () {
    final csv = CsvReport.build([
      const ReportRow(date: '2026-11-07', month: '2026-11', type: 'salary', amount: 4500000, category: 'Salary', account: 'HDFC'),
      const ReportRow(date: '2026-11-08', month: '2026-11', type: 'expense', amount: 25050, category: 'Food', note: 'Lunch, "veg"', account: 'HDFC', via: 'GPay'),
      const ReportRow(date: '2026-11-09', month: '2026-11', type: 'transfer', amount: 100000, account: 'HDFC', toAccount: 'Cash'),
      const ReportRow(date: '2026-11-09', month: '2026-11', type: 'adjustment', amount: -5000, note: '=SUM(A1)'),
    ]);
    final lines = csv.trim().split('\n');
    expect(lines.first, CsvReport.header.join(','));
    expect(lines[1], '2026-11-07,2026-11,in,salary,Salary,,HDFC,,,45000.00');
    expect(lines[2], '2026-11-08,2026-11,out,expense,Food,"Lunch, ""veg""",HDFC,GPay,,250.50');
    expect(lines[3], '2026-11-09,2026-11,transfer,transfer,,,HDFC,,Cash,1000.00');
    expect(lines[4], "2026-11-09,2026-11,out,adjustment,,'=SUM(A1),,,,-50.00");
    expect(lines.last, 'net_inr,44749.50');
    expect(csv, contains('total_expense_inr,250.50'));
  });

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
