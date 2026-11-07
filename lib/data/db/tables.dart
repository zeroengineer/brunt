import 'package:drift/drift.dart';

/// Schema from spec §8. All money columns are integer paise.

@DataClassName('MonthRow')
class Months extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get yearMonth => text().unique()(); // '2026-11'
  IntColumn get salaryExpected => integer()();
  IntColumn get salaryAccountId => integer().nullable().references(Accounts, #id)();
  IntColumn get salaryReceived => integer().nullable()();
  TextColumn get salaryReceivedDate => text().nullable()();

  /// Previous month ended without salary — carried as a flag (spec §5 edge cases).
  BoolColumn get salaryPendingCarried => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('open'))(); // open | closed
  IntColumn get version => integer().withDefault(const Constant(0))();
}

@DataClassName('AccountRow')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // cash | bank | upi | wallet | credit_card | savings
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get startingBalance => integer().withDefault(const Constant(0))();

  /// Cached live balance; for cards this is the outstanding due.
  IntColumn get balance => integer().withDefault(const Constant(0))();
  IntColumn get linkedAccountId => integer().nullable().references(Accounts, #id)();
  BoolColumn get includeInSpendable => boolean().withDefault(const Constant(true))();
  IntColumn get creditLimit => integer().nullable()();
  IntColumn get statementDay => integer().nullable()();
  IntColumn get dueDay => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()(); // ISO date the account started being tracked
}

@DataClassName('AccountMonthBalanceRow')
class AccountMonthBalances extends Table {
  IntColumn get monthId => integer().references(Months, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get opening => integer()();
  IntColumn get closing => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {monthId, accountId};
}

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get tier => integer()(); // 0 income, 1 priority … 5 variable
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

@DataClassName('TemplateRow')
class Templates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get name => text()();
  IntColumn get defaultAmount => integer()();
  IntColumn get defaultAccountId => integer().nullable().references(Accounts, #id)();

  /// For savings deposits (RD/SIP): paying moves money Bank → this account as a transfer.
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();
  TextColumn get frequency => text().withDefault(const Constant('monthly'))(); // monthly | daily | one_time
  IntColumn get daysOfWeek => integer().withDefault(const Constant(127))(); // Mon=1 … Sun=64
  IntColumn get dueDay => integer().nullable()();
  BoolColumn get variableAmount => boolean().withDefault(const Constant(false))();
  TextColumn get startMonth => text().nullable()();
  TextColumn get endMonth => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('PlannedRow')
@TableIndex(name: 'idx_planned_month', columns: {#monthId, #status})
class PlannedItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get monthId => integer().references(Months, #id)();

  /// Null for auto-created credit-card bills.
  IntColumn get templateId => integer().nullable().references(Templates, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get name => text()();
  IntColumn get amount => integer()();
  TextColumn get dueDate => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending | paid | skipped

  /// Credit card bill: the card this bill pays, and the statement date it froze.
  IntColumn get cardAccountId => integer().nullable().references(Accounts, #id)();
  TextColumn get statementDate => text().nullable()();
  IntColumn get transactionId => integer().nullable()();
}

@DataClassName('TxRow')
@TableIndex(name: 'idx_tx_month_date', columns: {#monthId, #date})
@TableIndex(name: 'idx_tx_category', columns: {#categoryId, #monthId})
@TableIndex(name: 'idx_tx_account', columns: {#accountId, #date})
@TableIndex(name: 'idx_tx_to_account', columns: {#toAccountId, #date})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get monthId => integer().references(Months, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get templateId => integer().nullable().references(Templates, #id)();
  IntColumn get plannedId => integer().nullable().references(PlannedItems, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();
  IntColumn get viaUpiId => integer().nullable().references(Accounts, #id)();
  TextColumn get type => text()(); // expense | extra_income | salary | transfer | adjustment
  IntColumn get amount => integer()();
  TextColumn get date => text()();
  TextColumn get note => text().nullable()();
  TextColumn get createdAt => text()();
}

@DataClassName('DailyLogRow')
@TableIndex(name: 'idx_dailylog_date', columns: {#date})
class DailyLogs extends Table {
  TextColumn get date => text()();
  IntColumn get templateId => integer().references(Templates, #id)();
  TextColumn get state => text()(); // confirmed | edited | skipped
  IntColumn get amount => integer().nullable()();
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  IntColumn get transactionId => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {date, templateId};
}

/// Precomputed planned vs actual per category per month (DB-level cache, write-through).
@DataClassName('MonthSummaryRow')
class MonthSummary extends Table {
  IntColumn get monthId => integer()();
  IntColumn get categoryId => integer()();
  IntColumn get planned => integer().withDefault(const Constant(0))();
  IntColumn get actual => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'month_summary';

  @override
  Set<Column<Object>> get primaryKey => {monthId, categoryId};
}

/// Historical stats from closed months.
@DataClassName('StatRow')
class StatsCache extends Table {
  TextColumn get key => text()();
  IntColumn get value => integer()();
  TextColumn get computedAt => text()();

  @override
  String get tableName => 'stats_cache';

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
