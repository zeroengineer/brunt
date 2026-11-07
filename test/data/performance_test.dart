import 'package:brunt/core/constants.dart';
import 'package:brunt/core/dates.dart';
import 'package:brunt/data/repositories/ledger.dart';
import 'package:brunt/data/repositories/queries.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

/// Phase 5 done-criterion: insights & history stay fast with 2+ years of data.
void main() {
  test('2 years of seeded data: rollover, insights and history pages are fast', () async {
    final h = Harness(DateTime(2024, 11, 1));
    final a = await h.standard();
    final bus = await h.dailyTemplate('Bus', 4000, a.cash, variable: true);
    await h.monthlyTemplate('Rent', 'Rent', 1200000, a.bank, dueDay: 5);
    final groceries = await h.categoryId('Groceries');

    var d = DateTime(2024, 11, 1);
    final end = DateTime(2026, 11, 30);
    while (!d.isAfter(end)) {
      h.now = d;
      await h.engine.ensureCurrent(d);
      if (d.day == 3) await h.ledger.receiveSalary(amount: 5000000, date: d, accountId: a.bank);
      if (d.day == 4) await h.ledger.add(Entry(type: TxType.transfer, amount: 600000, date: d, accountId: a.bank, toAccountId: a.cash));
      await h.ledger.logDaily(date: d, templateId: bus, state: DailyLogState.edited, amount: 3500 + d.day * 10);
      if (d.weekday == DateTime.saturday) {
        await h.ledger.add(Entry(type: TxType.expense, amount: 150000, date: d, accountId: a.gpay, categoryId: groceries, note: 'Weekly shop'));
      }
      d = DateTime(d.year, d.month, d.day + 1);
    }
    final txCount = (await h.db.select(h.db.transactions).get()).length;
    expect(txCount, greaterThan(800));
    expect((await h.db.select(h.db.months).get()).length, 25);

    final q = Queries(h.db);
    final sw = Stopwatch()..start();
    final stats = await q.periodStats(12, today: h.now);
    final page1 = await q.historyPage();
    final page2 = await q.historyPage(after: HistoryCursor(page1.last.date, page1.last.id));
    final searched = await q.historyPage(filter: const HistoryFilter(search: 'shop'));
    final learned = await q.learnedAverages();
    sw.stop();

    expect(stats.months.length, 12);
    expect(stats.expense, greaterThan(0));
    expect(stats.savingsRatePct, isNonNegative);
    expect(page1.length, 50);
    expect(page2.first.date.compareTo(page1.last.date) <= 0, isTrue);
    expect(searched.every((t) => t.note == 'Weekly shop'), isTrue);
    expect(learned[bus], isNotNull);
    expect(sw.elapsedMilliseconds, lessThan(1500), reason: 'insights + 3 history pages took ${sw.elapsedMilliseconds}ms');

    // stats cache built at month close
    final cache = await h.stats.all();
    expect(cache['salary_day_usual'], 3);
    expect(cache['median_variable_3m'], greaterThan(0));
    expect(await h.engine.verifyBalances(), 0);
    expect(Dates.yearMonth(h.now), '2026-11');
    await h.close();
  }, timeout: const Timeout(Duration(minutes: 3)));
}
