import 'package:drift/drift.dart';

import '../../core/constants.dart';
import '../../core/money.dart';
import '../../domain/report/report_row.dart';
import '../db/database.dart';

class HistoryFilter {
  const HistoryFilter({this.categoryId, this.accountId, this.type, this.search, this.monthId});
  final int? categoryId;
  final int? accountId;
  final TxType? type;
  final String? search;
  final int? monthId;

  bool get isEmpty =>
      categoryId == null && accountId == null && type == null && monthId == null && (search == null || search!.isEmpty);

  HistoryFilter copyWith({int? categoryId, int? accountId, TxType? type, String? search, int? monthId, bool clearCategory = false, bool clearAccount = false, bool clearType = false, bool clearMonth = false}) =>
      HistoryFilter(
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        accountId: clearAccount ? null : (accountId ?? this.accountId),
        type: clearType ? null : (type ?? this.type),
        search: search ?? this.search,
        monthId: clearMonth ? null : (monthId ?? this.monthId),
      );
}

class HistoryCursor {
  const HistoryCursor(this.date, this.id);
  final String date;
  final int id;
}

class PeriodStats {
  PeriodStats({
    required this.months,
    required this.expenseByCategory,
    required this.expenseByAccount,
    required this.expenseByUpi,
    required this.income,
    required this.expense,
    required this.saved,
    required this.days,
    required this.monthlyExpense,
  });

  final List<MonthRow> months;
  final Map<int, int> expenseByCategory;
  final Map<int, int> expenseByAccount;
  final Map<int, int> expenseByUpi;
  final int income;
  final int expense;
  final int saved;
  final int days;
  final Map<String, int> monthlyExpense;

  int get monthCount => months.isEmpty ? 1 : months.length;
  int avgPerMonth(int total) => Money.divRound(total, monthCount);
  int get dailyAverage => Money.divRound(expense, days == 0 ? 1 : days) ~/ 100 * 100; // whole rupees
  int get savingsRatePct => income <= 0 ? 0 : (saved * 100 ~/ income);
}

/// Read side for the UI. Streams are reactive (drift), lists are keyset-paginated.
class Queries {
  Queries(this.db);
  final AppDatabase db;

  Stream<List<AccountRow>> watchAccounts({bool includeArchived = false}) {
    final q = db.select(db.accounts)..orderBy([(a) => OrderingTerm.asc(a.sortOrder), (a) => OrderingTerm.asc(a.id)]);
    if (!includeArchived) q.where((a) => a.archived.equals(false));
    return q.watch();
  }

  Future<List<AccountRow>> accounts({bool includeArchived = true}) {
    final q = db.select(db.accounts)..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]);
    if (!includeArchived) q.where((a) => a.archived.equals(false));
    return q.get();
  }

  Stream<List<CategoryRow>> watchCategories() =>
      (db.select(db.categories)..orderBy([(c) => OrderingTerm.asc(c.tier), (c) => OrderingTerm.asc(c.sortOrder)])).watch();

  Stream<List<TemplateRow>> watchTemplates() =>
      (db.select(db.templates)..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)])).watch();

  Stream<MonthRow?> watchLatestMonth() =>
      (db.select(db.months)..orderBy([(m) => OrderingTerm.desc(m.yearMonth)])..limit(1)).watchSingleOrNull();

  Future<List<MonthRow>> months() => (db.select(db.months)..orderBy([(m) => OrderingTerm.asc(m.yearMonth)])).get();

  Stream<List<PlannedRow>> watchPlanned(int monthId) => (db.select(db.plannedItems)
        ..where((p) => p.monthId.equals(monthId))
        ..orderBy([(p) => OrderingTerm.asc(p.dueDate, nulls: NullsOrder.last), (p) => OrderingTerm.asc(p.id)]))
      .watch();

  /// Unpaid planned items from earlier months (overdue carry-over view).
  Stream<List<PlannedRow>> watchOlderPending(int monthId) => (db.select(db.plannedItems)
        ..where((p) => p.monthId.isSmallerThanValue(monthId) & p.status.equals('pending') & p.cardAccountId.isNotNull()))
      .watch();

  Stream<List<DailyLogRow>> watchDailyLogs(String fromIso, String toIso) =>
      (db.select(db.dailyLogs)..where((l) => l.date.isBetweenValues(fromIso, toIso))).watch();

  Future<List<DailyLogRow>> dailyLogs(String fromIso, String toIso) =>
      (db.select(db.dailyLogs)..where((l) => l.date.isBetweenValues(fromIso, toIso))).get();

  Stream<List<TxRow>> watchRecent({int limit = 6}) => (db.select(db.transactions)
        ..orderBy([(t) => OrderingTerm.desc(t.date), (t) => OrderingTerm.desc(t.id)])
        ..limit(limit))
      .watch();

  Future<TxRow?> tx(int id) => (db.select(db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Rolling average of the last 30 confirmed/edited logs per template (learned amounts).
  Future<Map<int, int>> learnedAverages() async {
    final rows = await db.customSelect(
      'SELECT template_id, amount FROM ('
      '  SELECT template_id, amount, ROW_NUMBER() OVER (PARTITION BY template_id ORDER BY date DESC) AS rn '
      "  FROM daily_logs WHERE state IN ('confirmed','edited') AND amount IS NOT NULL"
      ') WHERE rn <= 30',
      readsFrom: {db.dailyLogs},
    ).get();
    final sums = <int, (int, int)>{};
    for (final r in rows) {
      final id = r.read<int>('template_id');
      final a = r.read<int>('amount');
      final cur = sums[id] ?? (0, 0);
      sums[id] = (cur.$1 + a, cur.$2 + 1);
    }
    return {for (final e in sums.entries) e.key: Money.divRound(e.value.$1, e.value.$2)};
  }

  Future<int> variableSpent(int monthId) async {
    final r = await db.customSelect(
      'SELECT COALESCE(SUM(t.amount),0) AS s FROM transactions t JOIN categories c ON c.id = t.category_id '
      "WHERE t.month_id = ? AND t.type = 'expense' AND c.tier = ?",
      variables: [Variable.withInt(monthId), Variable.withInt(Tier.variable.value)],
      readsFrom: {db.transactions, db.categories},
    ).getSingle();
    return r.read<int>('s');
  }

  /// Money in / out per account in a month (transfers included, adjustments excluded).
  Future<Map<int, (int, int)>> accountFlows(int monthId) async {
    final txs = await (db.select(db.transactions)..where((t) => t.monthId.equals(monthId))).get();
    final out = <int, (int, int)>{};
    void add(int id, int i, int o) {
      final c = out[id] ?? (0, 0);
      out[id] = (c.$1 + i, c.$2 + o);
    }

    for (final t in txs) {
      final type = TxType.of(t.type);
      if (type == TxType.adjustment) continue;
      switch (type) {
        case TxType.expense:
          add(t.accountId, 0, t.amount);
        case TxType.salary:
        case TxType.extraIncome:
          add(t.accountId, t.amount, 0);
        case TxType.transfer:
          add(t.accountId, 0, t.amount);
          if (t.toAccountId != null) add(t.toAccountId!, t.amount, 0);
        case TxType.adjustment:
          break;
      }
    }
    return out;
  }

  (List<String>, List<Variable<Object>>) _filterSql(HistoryFilter filter) {
    final where = <String>[];
    final vars = <Variable<Object>>[];
    if (filter.monthId != null) {
      where.add('t.month_id = ?');
      vars.add(Variable.withInt(filter.monthId!));
    }
    if (filter.categoryId != null) {
      where.add('t.category_id = ?');
      vars.add(Variable.withInt(filter.categoryId!));
    }
    if (filter.accountId != null) {
      where.add('(t.account_id = ? OR t.to_account_id = ? OR t.via_upi_id = ?)');
      vars.addAll(List.filled(3, Variable.withInt(filter.accountId!)));
    }
    if (filter.type != null) {
      where.add('t.type = ?');
      vars.add(Variable.withString(filter.type!.code));
    }
    if (filter.search != null && filter.search!.trim().isNotEmpty) {
      final s = '%${filter.search!.trim().replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
      where.add(r"(t.note LIKE ? ESCAPE '\' OR c.name LIKE ? ESCAPE '\')");
      vars.addAll([Variable.withString(s), Variable.withString(s)]);
    }
    return (where, vars);
  }

  /// Rows for a CSV report, oldest first, with names joined in.
  Future<List<ReportRow>> reportRows(HistoryFilter filter) async {
    final (where, vars) = _filterSql(filter);
    final sql = 'SELECT t.date, m.year_month AS ym, t.type, t.amount, t.note, c.name AS cat, '
        'a.name AS acc, v.name AS via, b.name AS toacc FROM transactions t '
        'JOIN months m ON m.id = t.month_id '
        'LEFT JOIN categories c ON c.id = t.category_id '
        'LEFT JOIN accounts a ON a.id = t.account_id '
        'LEFT JOIN accounts v ON v.id = t.via_upi_id '
        'LEFT JOIN accounts b ON b.id = t.to_account_id '
        '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')} '}'
        'ORDER BY t.date ASC, t.id ASC';
    final rows = await db.customSelect(sql, variables: vars, readsFrom: {db.transactions, db.months, db.categories, db.accounts}).get();
    return [
      for (final r in rows)
        ReportRow(
          date: r.read<String>('date'),
          month: r.read<String>('ym'),
          type: r.read<String>('type'),
          amount: r.read<int>('amount'),
          note: r.readNullable<String>('note'),
          category: r.readNullable<String>('cat'),
          account: r.readNullable<String>('acc'),
          via: r.readNullable<String>('via'),
          toAccount: r.readNullable<String>('toacc'),
        ),
    ];
  }

  /// Keyset-paginated history (`WHERE (date,id) < cursor LIMIT n`), newest first.
  Future<List<TxRow>> historyPage({HistoryCursor? after, HistoryFilter filter = const HistoryFilter(), int limit = 50}) async {
    final (where, vars) = _filterSql(filter);
    if (after != null) {
      where.add('(t.date < ? OR (t.date = ? AND t.id < ?))');
      vars.addAll([Variable.withString(after.date), Variable.withString(after.date), Variable.withInt(after.id)]);
    }
    final sql = 'SELECT t.* FROM transactions t LEFT JOIN categories c ON c.id = t.category_id '
        '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')} '}'
        'ORDER BY t.date DESC, t.id DESC LIMIT $limit';
    final rows = await db.customSelect(sql, variables: vars, readsFrom: {db.transactions, db.categories}).get();
    return [for (final r in rows) await db.transactions.mapFromRow(r)];
  }

  /// Aggregates for Insights over the last [monthCount] months (including the current one).
  Future<PeriodStats> periodStats(int monthCount, {DateTime? today}) async {
    final all = await (db.select(db.months)..orderBy([(m) => OrderingTerm.desc(m.yearMonth)])..limit(monthCount)).get();
    final months = all.reversed.toList();
    if (months.isEmpty) {
      return PeriodStats(
          months: const [], expenseByCategory: const {}, expenseByAccount: const {}, expenseByUpi: const {},
          income: 0, expense: 0, saved: 0, days: 1, monthlyExpense: const {});
    }
    final ids = months.map((m) => m.id).join(',');
    final byCat = <int, int>{};
    for (final r in await db.customSelect(
      "SELECT category_id, SUM(amount) AS s FROM transactions WHERE type = 'expense' AND month_id IN ($ids) "
      'AND category_id IS NOT NULL GROUP BY category_id',
      readsFrom: {db.transactions},
    ).get()) {
      byCat[r.read<int>('category_id')] = r.read<int>('s');
    }
    final byAcc = <int, int>{};
    final byUpi = <int, int>{};
    for (final r in await db.customSelect(
      "SELECT account_id, via_upi_id, SUM(amount) AS s FROM transactions WHERE type = 'expense' AND month_id IN ($ids) "
      'GROUP BY account_id, via_upi_id',
      readsFrom: {db.transactions},
    ).get()) {
      final s = r.read<int>('s');
      final acc = r.read<int>('account_id');
      final via = r.readNullable<int>('via_upi_id');
      byAcc[acc] = (byAcc[acc] ?? 0) + s;
      if (via != null) byUpi[via] = (byUpi[via] ?? 0) + s;
    }
    final totals = await db.customSelect(
      'SELECT '
      "COALESCE(SUM(CASE WHEN t.type IN ('salary','extra_income') THEN t.amount END),0) AS income, "
      "COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount END),0) AS expense, "
      "COALESCE(SUM(CASE WHEN t.type = 'transfer' AND a.type = 'savings' THEN t.amount "
      "                  WHEN t.type = 'transfer' AND f.type = 'savings' THEN -t.amount END),0) AS saved "
      'FROM transactions t LEFT JOIN accounts a ON a.id = t.to_account_id LEFT JOIN accounts f ON f.id = t.account_id '
      'WHERE t.month_id IN ($ids)',
      readsFrom: {db.transactions, db.accounts},
    ).getSingle();
    final monthly = <String, int>{for (final m in months) m.yearMonth: 0};
    final ymById = {for (final m in months) m.id: m.yearMonth};
    for (final r in await db.customSelect(
      "SELECT month_id, SUM(amount) AS s FROM transactions WHERE type = 'expense' AND month_id IN ($ids) GROUP BY month_id",
      readsFrom: {db.transactions},
    ).get()) {
      monthly[ymById[r.read<int>('month_id')]!] = r.read<int>('s');
    }
    // days covered: full closed months + elapsed days of the open month
    final now = today ?? DateTime.now();
    var days = 0;
    for (final m in months) {
      final first = DateTime.parse('${m.yearMonth}-01');
      final dim = DateTime(first.year, first.month + 1, 0).day;
      days += m.status == 'open' && m.yearMonth == '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}'
          ? now.day
          : dim;
    }
    return PeriodStats(
      months: months,
      expenseByCategory: byCat,
      expenseByAccount: byAcc,
      expenseByUpi: byUpi,
      income: totals.read<int>('income'),
      expense: totals.read<int>('expense'),
      saved: totals.read<int>('saved'),
      days: days,
      monthlyExpense: monthly,
    );
  }

  /// Closing spendable total per closed month (for projection accuracy).
  Future<Map<String, int>> closingSpendable() async {
    final rows = await db.customSelect(
      'SELECT m.year_month AS ym, SUM(b.closing) AS s FROM account_month_balances b '
      'JOIN months m ON m.id = b.month_id JOIN accounts a ON a.id = b.account_id '
      "WHERE m.status = 'closed' AND a.include_in_spendable = 1 AND a.type NOT IN ('credit_card','upi') "
      'GROUP BY m.year_month',
      readsFrom: {db.accountMonthBalances, db.months, db.accounts},
    ).get();
    return {for (final r in rows) r.read<String>('ym'): r.readNullable<int>('s') ?? 0};
  }
}
