import 'package:brunt/core/constants.dart';
import 'package:brunt/data/db/database.dart';
import 'package:brunt/data/repositories/catalog_repo.dart';
import 'package:brunt/data/repositories/ledger.dart';
import 'package:brunt/data/repositories/month_engine.dart';
import 'package:brunt/data/repositories/queries.dart';
import 'package:brunt/data/repositories/settings_repo.dart';
import 'package:brunt/data/repositories/stats_repo.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';

/// In-memory BRUNT with a controllable clock.
class Harness {
  Harness(DateTime start) : now = start {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepo(db);
    ledger = Ledger(db, clock: () => now);
    stats = StatsRepo(db, clock: () => now);
    queries = Queries(db);
    engine = MonthEngine(db, ledger, settings, stats);
    catalog = CatalogRepo(db, ledger, engine, clock: () => now);
  }

  DateTime now;
  late final AppDatabase db;
  late final SettingsRepo settings;
  late final Ledger ledger;
  late final StatsRepo stats;
  late final Queries queries;
  late final MonthEngine engine;
  late final CatalogRepo catalog;

  Future<void> close() => db.close();

  Future<int> balance(int accountId) async =>
      (await (db.select(db.accounts)..where((a) => a.id.equals(accountId))).getSingle()).balance;

  Future<int> categoryId(String name) async =>
      (await (db.select(db.categories)..where((c) => c.name.equals(name))).getSingle()).id;

  /// Standard setup: salary ₹50,000, Cash ₹2,000, HDFC ₹20,000, GPay→HDFC, card, RD savings.
  Future<Std> standard({int salary = 5000000}) async {
    await settings.setInt(SettingKeys.salaryAmount, salary);
    await engine.createFirstMonth(now);
    final cash = await catalog.createAccount(name: 'Cash', type: AccountType.cash, startingBalance: 200000);
    final bank = await catalog.createAccount(name: 'HDFC', type: AccountType.bank, startingBalance: 2000000);
    final gpay = await catalog.createAccount(name: 'GPay', type: AccountType.upi, linkedAccountId: bank);
    final card = await catalog.createAccount(
        name: 'ICICI', type: AccountType.creditCard, creditLimit: 10000000, statementDay: 5, dueDay: 25);
    final rd = await catalog.createAccount(name: 'RD', type: AccountType.savings, startingBalance: 1000000);
    await settings.setInt(SettingKeys.salaryAccountId, bank);
    return Std(cash, bank, gpay, card, rd);
  }

  Future<int> dailyTemplate(String name, int amount, int account, {int days = 127, bool variable = false}) async {
    return catalog.createTemplate(TemplatesCompanion.insert(
      categoryId: await categoryId('Transport'),
      name: name,
      defaultAmount: amount,
      defaultAccountId: Value(account),
      frequency: const Value('daily'),
      daysOfWeek: Value(days),
      variableAmount: Value(variable),
    ));
  }

  Future<int> monthlyTemplate(String name, String category, int amount, int account, {int? dueDay, int? toAccount}) async {
    return catalog.createTemplate(TemplatesCompanion.insert(
      categoryId: await categoryId(category),
      name: name,
      defaultAmount: amount,
      defaultAccountId: Value(account),
      toAccountId: Value(toAccount),
      dueDay: Value(dueDay),
    ));
  }
}

class Std {
  Std(this.cash, this.bank, this.gpay, this.card, this.rd);
  final int cash, bank, gpay, card, rd;
}
