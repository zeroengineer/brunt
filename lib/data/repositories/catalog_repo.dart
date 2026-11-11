import 'package:drift/drift.dart';

import '../../core/constants.dart';
import '../../core/dates.dart';
import '../db/database.dart';
import 'ledger.dart';
import 'month_engine.dart';

/// Accounts, categories and templates CRUD (spec §2, §3, §4.9).
class CatalogRepo {
  CatalogRepo(this.db, this.ledger, this.engine, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final AppDatabase db;
  final Ledger ledger;
  final MonthEngine engine;
  final DateTime Function() _now;

  // ---------------------------------------------------------------- accounts

  Future<int> createAccount({
    required String name,
    required AccountType type,
    String? icon,
    String? color,
    int startingBalance = 0,
    int? linkedAccountId,
    bool? includeInSpendable,
    int? creditLimit,
    int? statementDay,
    int? dueDay,
  }) =>
      db.transaction(() async {
        if (type == AccountType.upi && linkedAccountId == null) {
          throw const LedgerException('Choose the bank account this UPI app uses');
        }
        final maxOrder = await db.customSelect('SELECT COALESCE(MAX(sort_order), -1) AS m FROM accounts').getSingle();
        final start = type.holdsBalance ? startingBalance : 0;
        final id = await db.into(db.accounts).insert(AccountsCompanion.insert(
              name: name.trim(),
              type: type.code,
              icon: Value(icon),
              color: Value(color),
              startingBalance: Value(start),
              balance: Value(start),
              linkedAccountId: Value(type == AccountType.upi || type == AccountType.reserve ? linkedAccountId : null),
              includeInSpendable: Value(type == AccountType.reserve ? false : (includeInSpendable ?? type.defaultSpendable)),
              creditLimit: Value(type.isCard ? creditLimit : null),
              statementDay: Value(type.isCard ? statementDay : null),
              dueDay: Value(type.isCard ? dueDay : null),
              sortOrder: Value(maxOrder.read<int>('m') + 1),
              createdAt: Value(Dates.iso(_now())),
            ));
        final m = await engine.latest();
        if (m != null) {
          await db.into(db.accountMonthBalances).insertOnConflictUpdate(
              AccountMonthBalancesCompanion.insert(monthId: m.id, accountId: id, opening: start));
          await ledger.touchLatest();
        }
        return id;
      });

  /// Finds or creates a BRUNT-managed account (Borrowed / Lent out).
  Future<int> ensureSystemAccount(AccountType type) async {
    final existing = await (db.select(db.accounts)..where((a) => a.type.equals(type.code))).get();
    if (existing.isNotEmpty) {
      final a = existing.first;
      if (a.archived) await setArchived(a.id, false);
      return a.id;
    }
    return createAccount(name: type.label, type: type, includeInSpendable: false);
  }

  /// Finds or creates the reserve kept inside bank [bankId] (system account, never spendable).
  Future<int> ensureReserveAccount(int bankId) async {
    final existing = await (db.select(db.accounts)
          ..where((a) => a.type.equals(AccountType.reserve.code) & a.linkedAccountId.equals(bankId)))
        .get();
    if (existing.isNotEmpty) {
      final a = existing.first;
      if (a.archived) await setArchived(a.id, false);
      return a.id;
    }
    final bank = await (db.select(db.accounts)..where((a) => a.id.equals(bankId))).getSingle();
    return createAccount(
        name: '${bank.name} reserve', type: AccountType.reserve, linkedAccountId: bankId, includeInSpendable: false);
  }

  /// The "Reserve" category (Savings tier), created on first use.
  Future<int> ensureReserveCategory() async {
    final existing = await (db.select(db.categories)
          ..where((c) => c.name.equals(reserveCategoryName) & c.tier.equals(Tier.savings.value)))
        .get();
    if (existing.isNotEmpty) {
      final c = existing.first;
      if (c.archived) await setCategoryArchived(c.id, false);
      return c.id;
    }
    return createCategory(name: reserveCategoryName, tier: Tier.savings, icon: 'shield');
  }

  static const reserveCategoryName = 'Reserve';

  Future<void> updateAccount(
    int id, {
    required String name,
    String? icon,
    String? color,
    int? startingBalance,
    int? linkedAccountId,
    required bool includeInSpendable,
    int? creditLimit,
    int? statementDay,
    int? dueDay,
  }) =>
      db.transaction(() async {
        final a = await (db.select(db.accounts)..where((x) => x.id.equals(id))).getSingle();
        final type = AccountType.of(a.type);
        var balance = a.balance;
        if (startingBalance != null && type.holdsBalance && startingBalance != a.startingBalance) {
          final d = startingBalance - a.startingBalance;
          balance += d;
          // shift the whole opening/closing chain by the same amount
          await db.customUpdate(
            'UPDATE account_month_balances SET opening = opening + ?, '
            'closing = CASE WHEN closing IS NULL THEN NULL ELSE closing + ? END WHERE account_id = ?',
            variables: [Variable.withInt(d), Variable.withInt(d), Variable.withInt(id)],
            updates: {db.accountMonthBalances},
          );
        }
        await (db.update(db.accounts)..where((x) => x.id.equals(id))).write(AccountsCompanion(
          name: Value(name.trim()),
          icon: Value(icon),
          color: Value(color),
          startingBalance: Value(startingBalance ?? a.startingBalance),
          balance: Value(balance),
          linkedAccountId: Value(type == AccountType.upi ? linkedAccountId : (type == AccountType.reserve ? a.linkedAccountId : null)),
          includeInSpendable: Value(type == AccountType.reserve ? false : includeInSpendable),
          creditLimit: Value(type.isCard ? creditLimit : null),
          statementDay: Value(type.isCard ? statementDay : null),
          dueDay: Value(type.isCard ? dueDay : null),
        ));
        await ledger.touchLatest();
      });

  Future<void> reorderAccounts(List<int> orderedIds) => db.transaction(() async {
        for (var i = 0; i < orderedIds.length; i++) {
          await (db.update(db.accounts)..where((a) => a.id.equals(orderedIds[i])))
              .write(AccountsCompanion(sortOrder: Value(i)));
        }
        await ledger.touchLatest();
      });

  Future<void> setArchived(int id, bool archived) async {
    await (db.update(db.accounts)..where((a) => a.id.equals(id))).write(AccountsCompanion(archived: Value(archived)));
    await ledger.touchLatest();
  }

  Future<bool> accountHasEntries(int id) async {
    final r = await db.customSelect(
      'SELECT COUNT(*) AS n FROM transactions WHERE account_id = ?1 OR to_account_id = ?1 OR via_upi_id = ?1',
      variables: [Variable.withInt(id)],
    ).getSingle();
    final linked = await db.customSelect('SELECT COUNT(*) AS n FROM accounts WHERE linked_account_id = ?',
        variables: [Variable.withInt(id)]).getSingle();
    return r.read<int>('n') > 0 || linked.read<int>('n') > 0;
  }

  /// Delete is only allowed when the account has no entries (archive keeps history).
  Future<void> deleteAccount(int id) => db.transaction(() async {
        if (await accountHasEntries(id)) throw const LedgerException('This account has entries — archive it instead');
        await (db.update(db.templates)..where((t) => t.defaultAccountId.equals(id)))
            .write(const TemplatesCompanion(defaultAccountId: Value(null)));
        await (db.update(db.templates)..where((t) => t.toAccountId.equals(id)))
            .write(const TemplatesCompanion(toAccountId: Value(null)));
        await (db.update(db.dailyLogs)..where((t) => t.accountId.equals(id)))
            .write(const DailyLogsCompanion(accountId: Value(null)));
        await (db.update(db.months)..where((t) => t.salaryAccountId.equals(id)))
            .write(const MonthsCompanion(salaryAccountId: Value(null)));
        await (db.delete(db.plannedItems)..where((p) => p.cardAccountId.equals(id))).go();
        await (db.delete(db.accountMonthBalances)..where((b) => b.accountId.equals(id))).go();
        await (db.delete(db.accounts)..where((a) => a.id.equals(id))).go();
        await ledger.touchLatest();
      });

  // ---------------------------------------------------------------- categories

  Future<int> createCategory({required String name, required Tier tier, String? icon, String? color}) async {
    final maxOrder = await db.customSelect('SELECT COALESCE(MAX(sort_order), -1) AS m FROM categories').getSingle();
    final id = await db.into(db.categories).insert(CategoriesCompanion.insert(
          name: name.trim(),
          tier: tier.value,
          icon: Value(icon),
          color: Value(color),
          sortOrder: Value(maxOrder.read<int>('m') + 1),
        ));
    await ledger.touchLatest();
    return id;
  }

  Future<void> updateCategory(int id, {required String name, String? icon, String? color}) async {
    await (db.update(db.categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(name: Value(name.trim()), icon: Value(icon), color: Value(color)));
    await ledger.touchLatest();
  }

  Future<void> setCategoryArchived(int id, bool archived) async {
    await (db.update(db.categories)..where((c) => c.id.equals(id))).write(CategoriesCompanion(archived: Value(archived)));
    await ledger.touchLatest();
  }

  Future<void> reorderCategories(List<int> orderedIds) => db.transaction(() async {
        for (var i = 0; i < orderedIds.length; i++) {
          await (db.update(db.categories)..where((c) => c.id.equals(orderedIds[i])))
              .write(CategoriesCompanion(sortOrder: Value(i)));
        }
        await ledger.touchLatest();
      });

  // ---------------------------------------------------------------- templates

  Future<int> createTemplate(TemplatesCompanion t) async {
    final id = await db.into(db.templates).insert(t);
    await engine.syncTemplate(id);
    return id;
  }

  Future<void> updateTemplate(int id, TemplatesCompanion t) async {
    await (db.update(db.templates)..where((x) => x.id.equals(id))).write(t);
    await engine.syncTemplate(id);
  }

  Future<void> setTemplateActive(int id, bool active) => updateTemplate(id, TemplatesCompanion(active: Value(active)));

  /// Deletes a template when nothing references it; otherwise pauses it (keeps history).
  Future<bool> deleteTemplate(int id) async {
    final used = await db.customSelect(
      'SELECT (SELECT COUNT(*) FROM transactions WHERE template_id = ?1) + '
      '(SELECT COUNT(*) FROM daily_logs WHERE template_id = ?1) + '
      "(SELECT COUNT(*) FROM planned_items WHERE template_id = ?1 AND status != 'pending') AS n",
      variables: [Variable.withInt(id)],
    ).getSingle();
    if (used.read<int>('n') > 0) {
      await setTemplateActive(id, false);
      return false;
    }
    await db.transaction(() async {
      await (db.delete(db.plannedItems)..where((p) => p.templateId.equals(id))).go();
      await (db.delete(db.templates)..where((x) => x.id.equals(id))).go();
    });
    await engine.syncTemplate(id);
    return true;
  }
}
