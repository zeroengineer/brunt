import 'package:drift/drift.dart';

import '../../core/constants.dart';
import '../../core/money.dart';
import '../db/database.dart';

/// L3 cache (spec §10.1): historical stats from closed months, rebuilt only at month close
/// or when a closed month is edited.
class StatsRepo {
  StatsRepo(this.db, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _now;

  static const medianVariable3m = 'median_variable_3m';
  static const salaryDayUsual = 'salary_day_usual';
  static const salaryDayLatest = 'salary_day_latest';
  static const closedMonths = 'closed_months';

  Future<int?> get(String key) async =>
      (await (db.select(db.statsCache)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<Map<String, int>> all() async => {for (final r in await db.select(db.statsCache).get()) r.key: r.value};

  Future<void> _put(String key, int v) => db.into(db.statsCache).insertOnConflictUpdate(
      StatsCacheCompanion.insert(key: key, value: v, computedAt: _now().toIso8601String()));

  Future<void> rebuild() => db.transaction(() async {
        final closed = await (db.select(db.months)
              ..where((m) => m.status.equals('closed'))
              ..orderBy([(m) => OrderingTerm.desc(m.yearMonth)]))
            .get();
        await _put(closedMonths, closed.length);

        // Variable-tier spend per closed month (expenses only — transfers never count).
        final last3 = closed.take(3).toList();
        final perMonth = <int>[];
        for (final m in last3) {
          final row = await db.customSelect(
            'SELECT COALESCE(SUM(t.amount), 0) AS s FROM transactions t '
            'JOIN categories c ON c.id = t.category_id '
            'WHERE t.month_id = ? AND t.type = ? AND c.tier = ?',
            variables: [Variable.withInt(m.id), Variable.withString(TxType.expense.code), Variable.withInt(Tier.variable.value)],
            readsFrom: {db.transactions, db.categories},
          ).getSingle();
          perMonth.add(row.read<int>('s'));
        }
        if (perMonth.isNotEmpty) {
          await _put(medianVariable3m, Money.median(perMonth));
        } else {
          await (db.delete(db.statsCache)..where((s) => s.key.equals(medianVariable3m))).go();
        }

        // Salary arrival history over the last 12 months (all months with a received date).
        final withSalary = await (db.select(db.months)
              ..where((m) => m.salaryReceivedDate.isNotNull())
              ..orderBy([(m) => OrderingTerm.desc(m.yearMonth)])
              ..limit(12))
            .get();
        final days = [for (final m in withSalary) int.parse(m.salaryReceivedDate!.substring(8, 10))];
        if (days.isNotEmpty) {
          await _put(salaryDayUsual, _mode(days));
          await _put(salaryDayLatest, days.reduce((a, b) => a > b ? a : b));
        }
      });

  static int _mode(List<int> v) {
    final counts = <int, int>{};
    for (final x in v) {
      counts[x] = (counts[x] ?? 0) + 1;
    }
    var best = v.first;
    var bestN = 0;
    counts.forEach((k, n) {
      if (n > bestN || (n == bestN && k < best)) {
        best = k;
        bestN = n;
      }
    });
    return best;
  }
}
