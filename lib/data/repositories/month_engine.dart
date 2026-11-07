import 'package:drift/drift.dart';

import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../domain/cards/card_cycle.dart';
import '../../domain/ledger/ledger_rules.dart';
import '../../domain/rollover/month_rollover.dart';
import '../../domain/schedule/schedule_expander.dart';
import '../db/database.dart';
import 'ledger.dart';
import 'settings_repo.dart';
import 'stats_repo.dart';

TemplateSpec specOf(TemplateRow t) => TemplateSpec(
      id: t.id,
      name: t.name,
      categoryId: t.categoryId,
      amount: t.defaultAmount,
      frequency: Frequency.of(t.frequency),
      daysOfWeek: t.daysOfWeek,
      dueDay: t.dueDay,
      startMonth: t.startMonth,
      endMonth: t.endMonth,
      active: t.active,
      accountId: t.defaultAccountId,
    );

/// Month lifecycle (spec §4.2): rollover on app open (idempotent), closing balances,
/// planned-item generation, card bills, and "Verify balances".
class MonthEngine {
  MonthEngine(this.db, this.ledger, this.settings, this.stats);

  final AppDatabase db;
  final Ledger ledger;
  final SettingsRepo settings;
  final StatsRepo stats;

  Future<MonthRow?> latest() =>
      (db.select(db.months)..orderBy([(m) => OrderingTerm.desc(m.yearMonth)])..limit(1)).getSingleOrNull();

  Future<MonthRow?> byYm(String ym) => (db.select(db.months)..where((m) => m.yearMonth.equals(ym))).getSingleOrNull();

  /// Creates the very first month (end of onboarding).
  Future<MonthRow> createFirstMonth(DateTime today) => db.transaction(() async {
        final ym = Dates.yearMonth(today);
        final existing = await byYm(ym);
        if (existing != null) return existing;
        return _createMonth(ym, null);
      });

  /// Runs on every app open / resume. Safe to call repeatedly.
  Future<void> ensureCurrent(DateTime today) async {
    final last = await latest();
    if (last == null) return; // not onboarded yet
    final currentYm = Dates.yearMonth(today);
    final toCreate = MonthRollover.monthsToCreate(last.yearMonth, currentYm);
    if (toCreate.isNotEmpty) {
      await db.transaction(() async {
        var prev = last;
        for (final ym in toCreate) {
          if (prev.status != 'closed') await _closeMonth(prev);
          prev = await _createMonth(ym, prev);
        }
      });
    }
    // close any stray open month older than the current one
    final stray = await (db.select(db.months)
          ..where((m) => m.status.equals('open') & m.yearMonth.isSmallerThanValue(currentYm)))
        .get();
    for (final m in stray) {
      await db.transaction(() => _closeMonth(m));
    }
    await ensureCardBills(today);
    if (await settings.get('stats_dirty') == '1' || toCreate.isNotEmpty) {
      await stats.rebuild();
      await settings.remove('stats_dirty');
    }
  }

  Future<MonthRow> _createMonth(String ym, MonthRow? prev) async {
    final salary = await settings.salaryAmount();
    final salaryAcc = await settings.getInt(SettingKeys.salaryAccountId);
    final carried = prev != null && prev.salaryReceived == null && prev.salaryExpected > 0;
    final id = await db.into(db.months).insert(MonthsCompanion.insert(
          yearMonth: ym,
          salaryExpected: salary,
          salaryAccountId: Value(salaryAcc),
          salaryPendingCarried: Value(carried),
        ));
    final prevBalances = prev == null
        ? <int, AccountMonthBalanceRow>{}
        : {
            for (final r in await (db.select(db.accountMonthBalances)..where((b) => b.monthId.equals(prev.id))).get())
              r.accountId: r,
          };
    for (final a in await db.select(db.accounts).get()) {
      final p = prevBalances[a.id];
      await db.into(db.accountMonthBalances).insert(AccountMonthBalancesCompanion.insert(
            monthId: id,
            accountId: a.id,
            opening: p?.closing ?? a.balance,
          ));
    }
    final month = await (db.select(db.months)..where((m) => m.id.equals(id))).getSingle();
    await generatePlanned(month);
    return month;
  }

  Future<void> _closeMonth(MonthRow m) async {
    final deltas = await _monthDeltas(m.id);
    final rows = await (db.select(db.accountMonthBalances)..where((b) => b.monthId.equals(m.id))).get();
    for (final r in rows) {
      final closing = MonthRollover.closing(r.opening, [deltas[r.accountId] ?? 0]);
      await (db.update(db.accountMonthBalances)
            ..where((b) => b.monthId.equals(m.id) & b.accountId.equals(r.accountId)))
          .write(AccountMonthBalancesCompanion(closing: Value(closing)));
    }
    await (db.update(db.months)..where((x) => x.id.equals(m.id))).write(const MonthsCompanion(status: Value('closed')));
  }

  /// Sum of balance deltas per account for every transaction booked in a month.
  Future<Map<int, int>> _monthDeltas(int monthId) async {
    final types = {for (final a in await db.select(db.accounts).get()) a.id: a.type};
    final txs = await (db.select(db.transactions)..where((t) => t.monthId.equals(monthId))).get();
    final out = <int, int>{};
    for (final t in txs) {
      final d = balanceDeltas(
        type: TxType.of(t.type),
        amount: t.amount,
        accountId: t.accountId,
        accountIsCard: types[t.accountId] == AccountType.creditCard.code,
        toAccountId: t.toAccountId,
        toIsCard: types[t.toAccountId] == AccountType.creditCard.code,
      );
      d.forEach((k, v) => out[k] = (out[k] ?? 0) + v);
    }
    return out;
  }

  /// Generates planned items for a month from active monthly/one-time templates.
  /// Idempotent: templates that already have an item this month are skipped.
  Future<void> generatePlanned(MonthRow m) async {
    final templates = await db.select(db.templates).get();
    final existing = {
      for (final p in await (db.select(db.plannedItems)..where((p) => p.monthId.equals(m.id))).get())
        if (p.templateId != null) p.templateId!,
    };
    final specs = ScheduleExpander.plannedForMonth(templates.map(specOf), m.yearMonth);
    for (final s in specs) {
      if (existing.contains(s.templateId)) continue;
      await db.into(db.plannedItems).insert(PlannedItemsCompanion.insert(
            monthId: m.id,
            templateId: Value(s.templateId),
            categoryId: Value(s.categoryId),
            name: s.name,
            amount: s.amount,
            dueDate: Value(s.dueDate == null ? null : Dates.iso(s.dueDate!)),
          ));
    }
    await recomputePlannedSummary(m.id);
  }

  /// After a template is created or edited: keep the open month's *pending* item in step.
  Future<void> syncTemplate(int templateId) => db.transaction(() async {
        final m = await latest();
        if (m == null || m.status != 'open') return;
        final t = await (db.select(db.templates)..where((x) => x.id.equals(templateId))).getSingleOrNull();
        final items = await (db.select(db.plannedItems)
              ..where((p) => p.monthId.equals(m.id) & p.templateId.equals(templateId)))
            .get();
        final spec = t == null ? null : specOf(t);
        final wanted = spec != null && spec.frequency != Frequency.daily && spec.activeIn(m.yearMonth);
        if (!wanted) {
          for (final p in items.where((p) => p.status == PlannedStatus.pending.code)) {
            await (db.delete(db.plannedItems)..where((x) => x.id.equals(p.id))).go();
          }
        } else {
          final first = Dates.firstOfYearMonth(m.yearMonth);
          final due = spec.dueDay == null ? null : Dates.iso(Dates.clampDay(first.year, first.month, spec.dueDay!));
          if (items.isEmpty) {
            await db.into(db.plannedItems).insert(PlannedItemsCompanion.insert(
                  monthId: m.id,
                  templateId: Value(spec.id),
                  categoryId: Value(spec.categoryId),
                  name: spec.name,
                  amount: spec.amount,
                  dueDate: Value(due),
                ));
          } else {
            for (final p in items.where((p) => p.status == PlannedStatus.pending.code)) {
              await (db.update(db.plannedItems)..where((x) => x.id.equals(p.id))).write(PlannedItemsCompanion(
                name: Value(spec.name),
                amount: Value(spec.amount),
                categoryId: Value(spec.categoryId),
                dueDate: Value(due),
              ));
            }
          }
        }
        await recomputePlannedSummary(m.id);
        await ledger.touchLatest();
      });

  /// `month_summary.planned` = planned items + expanded daily templates, per category.
  Future<void> recomputePlannedSummary(int monthId) async {
    final m = await (db.select(db.months)..where((x) => x.id.equals(monthId))).getSingle();
    final planned = <int, int>{};
    for (final p in await (db.select(db.plannedItems)..where((x) => x.monthId.equals(monthId))).get()) {
      if (p.categoryId == null || p.status == PlannedStatus.skipped.code) continue;
      planned[p.categoryId!] = (planned[p.categoryId!] ?? 0) + p.amount;
    }
    for (final t in await (db.select(db.templates)..where((x) => x.frequency.equals('daily'))).get()) {
      final total = ScheduleExpander.dailyMonthTotal(specOf(t), m.yearMonth);
      if (total > 0) planned[t.categoryId] = (planned[t.categoryId] ?? 0) + total;
    }
    await db.customUpdate('UPDATE month_summary SET planned = 0 WHERE month_id = ?',
        variables: [Variable.withInt(monthId)], updates: {db.monthSummary});
    for (final MapEntry(key: cat, value: v) in planned.entries) {
      await db.customUpdate(
        'INSERT INTO month_summary (month_id, category_id, planned, actual) VALUES (?, ?, ?, 0) '
        'ON CONFLICT (month_id, category_id) DO UPDATE SET planned = excluded.planned',
        variables: [Variable.withInt(monthId), Variable.withInt(cat), Variable.withInt(v)],
        updates: {db.monthSummary},
      );
    }
  }

  /// Credit card cycle (spec §4.10): when a statement day passes, the outstanding as of
  /// that day becomes a Priority bill due on the card's due day. Idempotent.
  Future<int> ensureCardBills(DateTime today) async {
    var created = 0;
    final cards = await (db.select(db.accounts)
          ..where((a) => a.type.equals(AccountType.creditCard.code) & a.archived.equals(false)))
        .get();
    for (final c in cards) {
      if (c.statementDay == null || c.dueDay == null) continue;
      final s = CardCycle.lastStatementDate(today, c.statementDay!);
      final due = CardCycle.dueDateFor(s, c.dueDay!);
      if (c.createdAt != null && due.isBefore(Dates.parseIso(c.createdAt!))) continue;
      final month = await byYm(Dates.yearMonth(due));
      if (month == null) continue; // created when that month opens
      final sIso = Dates.iso(s);
      final exists = await (db.select(db.plannedItems)
            ..where((p) => p.cardAccountId.equals(c.id) & p.statementDate.equals(sIso)))
          .getSingleOrNull();
      if (exists != null) continue;
      // outstanding as of the statement date = now − effects booked after it
      final after = await (db.select(db.transactions)
            ..where((t) =>
                (t.accountId.equals(c.id) | t.toAccountId.equals(c.id)) & t.date.isBiggerThanValue(sIso)))
          .get();
      var outstanding = c.balance;
      final types = {for (final a in await db.select(db.accounts).get()) a.id: a.type};
      for (final t in after) {
        final d = balanceDeltas(
          type: TxType.of(t.type),
          amount: t.amount,
          accountId: t.accountId,
          accountIsCard: types[t.accountId] == AccountType.creditCard.code,
          toAccountId: t.toAccountId,
          toIsCard: types[t.toAccountId] == AccountType.creditCard.code,
        );
        outstanding -= d[c.id] ?? 0;
      }
      if (outstanding <= 0) continue;
      final cat = await _cardBillCategory();
      await db.into(db.plannedItems).insert(PlannedItemsCompanion.insert(
            monthId: month.id,
            categoryId: Value(cat),
            name: '${c.name} bill',
            amount: outstanding,
            dueDate: Value(Dates.iso(due)),
            cardAccountId: Value(c.id),
            statementDate: Value(sIso),
          ));
      await recomputePlannedSummary(month.id);
      created++;
    }
    if (created > 0) await ledger.touchLatest();
    return created;
  }

  Future<int?> _cardBillCategory() async {
    final rows = await (db.select(db.categories)
          ..where((c) => c.tier.equals(Tier.priority.value))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
    if (rows.isEmpty) return null;
    return rows.firstWhere((c) => c.name == 'Credit card bill', orElse: () => rows.first).id;
  }

  /// "Verify balances" (spec §10.2): recomputes every account from its entries, rebuilds the
  /// per-month opening/closing chain and month_summary actuals, and repairs mismatches.
  /// Returns the number of accounts whose cached balance was wrong.
  Future<int> verifyBalances() => db.transaction(() async {
        final accounts = await db.select(db.accounts).get();
        final types = {for (final a in accounts) a.id: a.type};
        final txs = await db.select(db.transactions).get();
        final totals = <int, int>{};
        final perMonth = <int, Map<int, int>>{};
        final actual = <(int, int), int>{};
        for (final t in txs) {
          final d = balanceDeltas(
            type: TxType.of(t.type),
            amount: t.amount,
            accountId: t.accountId,
            accountIsCard: types[t.accountId] == AccountType.creditCard.code,
            toAccountId: t.toAccountId,
            toIsCard: types[t.toAccountId] == AccountType.creditCard.code,
          );
          d.forEach((k, v) {
            totals[k] = (totals[k] ?? 0) + v;
            final pm = perMonth.putIfAbsent(t.monthId, () => {});
            pm[k] = (pm[k] ?? 0) + v;
          });
          if (t.categoryId != null && t.type != TxType.adjustment.code) {
            actual[(t.monthId, t.categoryId!)] = (actual[(t.monthId, t.categoryId!)] ?? 0) + t.amount;
          }
        }
        var fixed = 0;
        for (final a in accounts) {
          final expected = a.startingBalance + (totals[a.id] ?? 0);
          if (expected != a.balance) {
            fixed++;
            await (db.update(db.accounts)..where((x) => x.id.equals(a.id))).write(AccountsCompanion(balance: Value(expected)));
          }
        }
        // opening/closing chain
        final months = await (db.select(db.months)..orderBy([(m) => OrderingTerm.asc(m.yearMonth)])).get();
        final running = <int, int>{};
        for (final m in months) {
          final rows = await (db.select(db.accountMonthBalances)..where((b) => b.monthId.equals(m.id))).get();
          for (final r in rows) {
            final acc = accounts.where((a) => a.id == r.accountId).firstOrNull;
            if (acc == null) continue;
            final opening = running[r.accountId] ?? _openingBeforeFirstMonth(acc, perMonth, months, m);
            final closing = opening + (perMonth[m.id]?[r.accountId] ?? 0);
            await (db.update(db.accountMonthBalances)
                  ..where((b) => b.monthId.equals(m.id) & b.accountId.equals(r.accountId)))
                .write(AccountMonthBalancesCompanion(
                    opening: Value(opening), closing: Value(m.status == 'closed' ? closing : null)));
            running[r.accountId] = closing;
          }
        }
        // month_summary actuals
        await db.customUpdate('UPDATE month_summary SET actual = 0', updates: {db.monthSummary});
        for (final MapEntry(key: k, value: v) in actual.entries) {
          await db.customUpdate(
            'INSERT INTO month_summary (month_id, category_id, planned, actual) VALUES (?, ?, 0, ?) '
            'ON CONFLICT (month_id, category_id) DO UPDATE SET actual = excluded.actual',
            variables: [Variable.withInt(k.$1), Variable.withInt(k.$2), Variable.withInt(v)],
            updates: {db.monthSummary},
          );
        }
        await ledger.touchLatest();
        return fixed;
      });

  /// Opening of an account's first tracked month: its starting balance plus anything booked in
  /// earlier months (normally nothing).
  int _openingBeforeFirstMonth(AccountRow a, Map<int, Map<int, int>> perMonth, List<MonthRow> months, MonthRow first) {
    var v = a.startingBalance;
    for (final m in months) {
      if (m.yearMonth.compareTo(first.yearMonth) >= 0) break;
      v += perMonth[m.id]?[a.id] ?? 0;
    }
    return v;
  }
}
