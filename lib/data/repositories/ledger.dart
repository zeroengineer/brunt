import 'package:drift/drift.dart';

import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../domain/ledger/ledger_rules.dart';
import '../db/database.dart';

class LedgerException implements Exception {
  const LedgerException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A money entry as the UI describes it. UPI accounts are resolved to their bank here.
class Entry {
  const Entry({
    required this.type,
    required this.amount,
    required this.date,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.templateId,
    this.plannedId,
    this.note,
  });

  final TxType type;
  final int amount;
  final DateTime date;
  final int accountId;
  final int? toAccountId;
  final int? categoryId;
  final int? templateId;
  final int? plannedId;
  final String? note;
}

/// The single write path for money (spec §10.2):
/// `BEGIN → write row → update account balance(s) → update month_summary → months.version++ → COMMIT`.
/// Edits to closed months cascade opening/closing balances forward.
class Ledger {
  Ledger(this.db, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _now;

  // ---------------------------------------------------------------- entries

  Future<int> add(Entry e) => db.transaction(() async {
        final id = await _insert(e);
        return id;
      });

  Future<void> update(int txId, Entry e) => db.transaction(() async {
        final old = await _tx(txId);
        await _effects(old, -1);
        final r = await _resolve(e);
        final month = await monthFor(e.date);
        await (db.update(db.transactions)..where((t) => t.id.equals(txId))).write(TransactionsCompanion(
          monthId: Value(month.id),
          categoryId: Value(e.categoryId),
          accountId: Value(r.accountId),
          toAccountId: Value(r.toAccountId),
          viaUpiId: Value(r.viaUpiId),
          type: Value(e.type.code),
          amount: Value(e.amount),
          date: Value(Dates.iso(e.date)),
          note: Value(e.note),
        ));
        final now = await _tx(txId);
        await _effects(now, 1);
        if (old.type == TxType.salary.code || now.type == TxType.salary.code) {
          await _syncSalaryFields(old.monthId);
          await _syncSalaryFields(now.monthId);
        }
        // keep a linked daily log's amount/account in step
        await (db.update(db.dailyLogs)..where((l) => l.transactionId.equals(txId))).write(DailyLogsCompanion(
          amount: Value(e.amount),
          accountId: Value(e.accountId),
          state: const Value('edited'),
        ));
        await _touch({old.monthId, now.monthId});
      });

  Future<void> delete(int txId) => db.transaction(() async {
        final old = await _tx(txId);
        await _removeTx(old);
        // unlink anything that pointed at it
        await (db.update(db.plannedItems)..where((p) => p.transactionId.equals(txId)))
            .write(const PlannedItemsCompanion(status: Value('pending'), transactionId: Value(null)));
        await (db.delete(db.dailyLogs)..where((l) => l.transactionId.equals(txId))).go();
        if (old.type == TxType.salary.code) await _syncSalaryFields(old.monthId);
        await _touch({old.monthId});
      });

  // ---------------------------------------------------------------- salary

  /// Marks salary received for the month containing [date] (spec §4.3).
  Future<int> receiveSalary({required int amount, required DateTime date, required int accountId}) =>
      db.transaction(() async {
        final month = await monthFor(date);
        final existing = await (db.select(db.transactions)
              ..where((t) => t.monthId.equals(month.id) & t.type.equals(TxType.salary.code)))
            .get();
        if (existing.isNotEmpty) throw const LedgerException('Salary is already marked received for this month');
        final cat = await _categoryByTier(Tier.income, 'Salary');
        final id = await _insert(Entry(
          type: TxType.salary,
          amount: amount,
          date: date,
          accountId: accountId,
          categoryId: cat?.id,
          note: 'Salary',
        ));
        await _syncSalaryFields(month.id);
        return id;
      });

  Future<void> _syncSalaryFields(int monthId) async {
    final rows = await (db.select(db.transactions)
          ..where((t) => t.monthId.equals(monthId) & t.type.equals(TxType.salary.code))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
    if (rows.isEmpty) {
      await (db.update(db.months)..where((m) => m.id.equals(monthId))).write(
          const MonthsCompanion(salaryReceived: Value(null), salaryReceivedDate: Value(null)));
    } else {
      final total = rows.fold<int>(0, (a, r) => a + r.amount);
      await (db.update(db.months)..where((m) => m.id.equals(monthId))).write(MonthsCompanion(
        salaryReceived: Value(total),
        salaryReceivedDate: Value(rows.first.date),
        salaryAccountId: Value(rows.first.accountId),
      ));
    }
  }

  // ---------------------------------------------------------------- planned items

  /// Pays a planned item. Card bills and savings deposits become transfers (spec §4.4).
  Future<int> payPlanned(int plannedId, {required int amount, required int accountId, required DateTime date}) =>
      db.transaction(() async {
        final p = await (db.select(db.plannedItems)..where((x) => x.id.equals(plannedId))).getSingle();
        if (p.status == PlannedStatus.paid.code && p.transactionId != null) {
          return p.transactionId!; // idempotent: double tap on "Paid"
        }
        int? toAccountId;
        if (p.cardAccountId != null) {
          toAccountId = p.cardAccountId;
        } else if (p.templateId != null) {
          final t = await (db.select(db.templates)..where((x) => x.id.equals(p.templateId!))).getSingleOrNull();
          toAccountId = t?.toAccountId;
        }
        if (toAccountId != null && toAccountId == accountId) {
          throw const LedgerException('Pick a different paying account');
        }
        final txId = await _insert(Entry(
          type: toAccountId != null ? TxType.transfer : TxType.expense,
          amount: amount,
          date: date,
          accountId: accountId,
          toAccountId: toAccountId,
          categoryId: p.categoryId,
          templateId: p.templateId,
          plannedId: p.id,
          note: p.name,
        ));
        await (db.update(db.plannedItems)..where((x) => x.id.equals(plannedId)))
            .write(PlannedItemsCompanion(status: const Value('paid'), transactionId: Value(txId)));
        await _touch({p.monthId});
        return txId;
      });

  Future<void> setPlannedStatus(int plannedId, PlannedStatus status) => db.transaction(() async {
        final p = await (db.select(db.plannedItems)..where((x) => x.id.equals(plannedId))).getSingle();
        if (p.transactionId != null) {
          final tx = await (db.select(db.transactions)..where((t) => t.id.equals(p.transactionId!))).getSingleOrNull();
          if (tx != null) await _removeTx(tx);
        }
        await (db.update(db.plannedItems)..where((x) => x.id.equals(plannedId)))
            .write(PlannedItemsCompanion(status: Value(status.code), transactionId: const Value(null)));
        await _touch({p.monthId});
      });

  // ---------------------------------------------------------------- daily log

  /// Confirms / edits / skips a daily item for a date (spec §4.5).
  /// Confirmed and edited logs create an expense so balances stay exact.
  Future<void> logDaily({
    required DateTime date,
    required int templateId,
    required DailyLogState state,
    int? amount,
    int? accountId,
  }) =>
      db.transaction(() async {
        final iso = Dates.iso(date);
        final existing = await (db.select(db.dailyLogs)
              ..where((l) => l.date.equals(iso) & l.templateId.equals(templateId)))
            .getSingleOrNull();
        if (existing?.transactionId != null) {
          final tx = await (db.select(db.transactions)..where((t) => t.id.equals(existing!.transactionId!))).getSingleOrNull();
          if (tx != null) await _removeTx(tx);
        }
        final t = await (db.select(db.templates)..where((x) => x.id.equals(templateId))).getSingle();
        int? txId;
        int? amt;
        int? acc;
        if (state != DailyLogState.skipped) {
          amt = amount ?? t.defaultAmount;
          acc = accountId ?? t.defaultAccountId ?? await _firstSpendableAccountId();
          if (acc == null) throw const LedgerException('Add an account first');
          if (amt > 0) {
            txId = await _insert(Entry(
              type: TxType.expense,
              amount: amt,
              date: date,
              accountId: acc,
              categoryId: t.categoryId,
              templateId: t.id,
              note: t.name,
            ));
          }
        }
        await db.into(db.dailyLogs).insertOnConflictUpdate(DailyLogsCompanion.insert(
              date: iso,
              templateId: templateId,
              state: state.code,
              amount: Value(amt),
              accountId: Value(acc),
              transactionId: Value(txId),
            ));
        final m = await monthForOrNull(date);
        if (m != null) await _touch({m.id});
      });

  /// Removes a daily log (back to "unconfirmed").
  Future<void> clearDaily({required DateTime date, required int templateId}) => db.transaction(() async {
        final iso = Dates.iso(date);
        final existing = await (db.select(db.dailyLogs)
              ..where((l) => l.date.equals(iso) & l.templateId.equals(templateId)))
            .getSingleOrNull();
        if (existing == null) return;
        if (existing.transactionId != null) {
          final tx = await (db.select(db.transactions)..where((t) => t.id.equals(existing.transactionId!))).getSingleOrNull();
          if (tx != null) await _removeTx(tx);
        }
        await (db.delete(db.dailyLogs)..where((l) => l.date.equals(iso) & l.templateId.equals(templateId))).go();
        final m = await monthForOrNull(date);
        if (m != null) await _touch({m.id});
      });

  // ---------------------------------------------------------------- adjustments

  /// "Adjust balance": sets the real amount and books the difference as *Unaccounted*.
  Future<void> adjustBalance(int accountId, int realValue, {DateTime? date}) => db.transaction(() async {
        final acc = await _acc(accountId);
        if (acc.type == AccountType.upi.code) throw const LedgerException('UPI apps hold no balance — adjust the linked bank');
        final diff = realValue - acc.balance;
        if (diff == 0) return;
        await _insert(Entry(
          type: TxType.adjustment,
          amount: diff,
          date: date ?? Dates.day(_now()),
          accountId: accountId,
          note: 'Unaccounted',
        ));
      });

  // ---------------------------------------------------------------- internals

  Future<int> _insert(Entry e) async {
    if (e.type != TxType.adjustment && e.amount <= 0) throw const LedgerException('Amount must be more than zero');
    if (e.type == TxType.transfer && e.toAccountId == null) throw const LedgerException('Pick where the money goes');
    final r = await _resolve(e);
    if (e.type == TxType.transfer && r.toAccountId == r.accountId) {
      throw const LedgerException('From and To must be different accounts');
    }
    final month = await monthFor(e.date);
    final id = await db.into(db.transactions).insert(TransactionsCompanion.insert(
          monthId: month.id,
          categoryId: Value(e.categoryId),
          templateId: Value(e.templateId),
          plannedId: Value(e.plannedId),
          accountId: r.accountId,
          toAccountId: Value(r.toAccountId),
          viaUpiId: Value(r.viaUpiId),
          type: e.type.code,
          amount: e.amount,
          date: Dates.iso(e.date),
          note: Value(e.note),
          createdAt: _now().toIso8601String(),
        ));
    await _effects(await _tx(id), 1);
    await _touch({month.id});
    return id;
  }

  Future<void> _removeTx(TxRow tx) async {
    await _effects(tx, -1);
    await (db.delete(db.transactions)..where((t) => t.id.equals(tx.id))).go();
    await _touch({tx.monthId});
  }

  Future<({int accountId, int? toAccountId, int? viaUpiId})> _resolve(Entry e) async {
    var accountId = e.accountId;
    int? via;
    final acc = await _acc(accountId);
    if (acc.type == AccountType.upi.code) {
      if (acc.linkedAccountId == null) throw LedgerException('${acc.name} is not linked to a bank account');
      via = acc.id;
      accountId = acc.linkedAccountId!;
    }
    int? to = e.toAccountId;
    if (to != null) {
      final toAcc = await _acc(to);
      if (toAcc.type == AccountType.upi.code) {
        if (toAcc.linkedAccountId == null) throw LedgerException('${toAcc.name} is not linked to a bank account');
        to = toAcc.linkedAccountId;
      }
    }
    return (accountId: accountId, toAccountId: to, viaUpiId: via);
  }

  /// Applies (sign = 1) or reverses (sign = −1) a transaction's effects.
  Future<void> _effects(TxRow r, int sign) async {
    final from = await _acc(r.accountId);
    final to = r.toAccountId == null ? null : await _acc(r.toAccountId!);
    final deltas = balanceDeltas(
      type: TxType.of(r.type),
      amount: r.amount,
      accountId: r.accountId,
      accountIsCard: from.type == AccountType.creditCard.code,
      toAccountId: r.toAccountId,
      toIsCard: to?.type == AccountType.creditCard.code,
    );
    for (final MapEntry(key: id, value: v) in deltas.entries) {
      await db.customUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?',
          variables: [Variable.withInt(v * sign), Variable.withInt(id)], updates: {db.accounts});
    }

    if (r.categoryId != null && r.type != TxType.adjustment.code) {
      await db.customUpdate(
        'INSERT INTO month_summary (month_id, category_id, planned, actual) VALUES (?, ?, 0, ?) '
        'ON CONFLICT (month_id, category_id) DO UPDATE SET actual = actual + excluded.actual',
        variables: [Variable.withInt(r.monthId), Variable.withInt(r.categoryId!), Variable.withInt(r.amount * sign)],
        updates: {db.monthSummary},
      );
    }

    final month = await (db.select(db.months)..where((m) => m.id.equals(r.monthId))).getSingle();
    if (month.status == 'closed') {
      // Cascade: this month's closing and every later month's opening/closing shift by the delta.
      for (final MapEntry(key: id, value: v) in deltas.entries) {
        final d = v * sign;
        await db.customUpdate(
          'UPDATE account_month_balances SET closing = closing + ? WHERE account_id = ? AND month_id = ? AND closing IS NOT NULL',
          variables: [Variable.withInt(d), Variable.withInt(id), Variable.withInt(month.id)],
          updates: {db.accountMonthBalances},
        );
        await db.customUpdate(
          'UPDATE account_month_balances SET opening = opening + ?, '
          'closing = CASE WHEN closing IS NULL THEN NULL ELSE closing + ? END '
          'WHERE account_id = ? AND month_id IN (SELECT id FROM months WHERE year_month > ?)',
          variables: [Variable.withInt(d), Variable.withInt(d), Variable.withInt(id), Variable.withString(month.yearMonth)],
          updates: {db.accountMonthBalances},
        );
      }
      await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion.insert(key: 'stats_dirty', value: '1'));
    }
  }

  /// Bumps the version of the affected months and of the latest month (the cache key
  /// every dashboard provider watches).
  Future<void> _touch(Set<int> monthIds) async {
    if (monthIds.isEmpty) return touchLatest();
    final ids = monthIds.join(',');
    await db.customUpdate(
      'UPDATE months SET version = version + 1 WHERE id IN ($ids) OR id = (SELECT id FROM months ORDER BY year_month DESC LIMIT 1)',
      updates: {db.months},
    );
  }

  /// Public so other repositories can bump the version after non-ledger writes.
  Future<void> touchLatest() => db.customUpdate(
        'UPDATE months SET version = version + 1 WHERE id = (SELECT id FROM months ORDER BY year_month DESC LIMIT 1)',
        updates: {db.months},
      );

  Future<TxRow> _tx(int id) => (db.select(db.transactions)..where((t) => t.id.equals(id))).getSingle();

  Future<AccountRow> _acc(int id) async {
    final a = await (db.select(db.accounts)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (a == null) throw const LedgerException('Account not found');
    return a;
  }

  Future<MonthRow> monthFor(DateTime date) async {
    final m = await monthForOrNull(date);
    if (m == null) throw LedgerException('${Dates.monthLabel(Dates.yearMonth(date))} is not tracked in BRUNT');
    return m;
  }

  Future<MonthRow?> monthForOrNull(DateTime date) =>
      (db.select(db.months)..where((m) => m.yearMonth.equals(Dates.yearMonth(date)))).getSingleOrNull();

  Future<CategoryRow?> _categoryByTier(Tier tier, String preferredName) async {
    final rows = await (db.select(db.categories)
          ..where((c) => c.tier.equals(tier.value))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
    if (rows.isEmpty) return null;
    return rows.firstWhere((c) => c.name == preferredName, orElse: () => rows.first);
  }

  Future<int?> _firstSpendableAccountId() async {
    final a = await (db.select(db.accounts)
          ..where((t) => t.archived.equals(false) & t.includeInSpendable.equals(true) & t.type.isNotIn(['upi', 'credit_card']))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])
          ..limit(1))
        .getSingleOrNull();
    return a?.id;
  }
}
