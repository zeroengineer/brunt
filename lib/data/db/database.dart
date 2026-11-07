import 'package:drift/drift.dart';

import '../../core/constants.dart';
import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Months,
  Accounts,
  AccountMonthBalances,
  Categories,
  Templates,
  PlannedItems,
  Transactions,
  DailyLogs,
  MonthSummary,
  StatsCache,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedDefaultCategories();
        },
        onUpgrade: (m, from, to) async {
          // Future schema migrations go here, one step per version.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Default categories per tier. Users can rename, recolour, reorder and archive them.
  Future<void> seedDefaultCategories() async {
    const seed = <(String, Tier, String)>[
      ('Salary', Tier.income, 'briefcase'),
      ('Extra income', Tier.income, 'trending_up'),
      ('Credit card bill', Tier.priority, 'credit_card'),
      ('Loan EMI', Tier.priority, 'landmark'),
      ('Debt', Tier.priority, 'hand_coins'),
      ('RD', Tier.savings, 'piggy_bank'),
      ('SIP', Tier.savings, 'trending_up'),
      ('Emergency fund', Tier.savings, 'umbrella'),
      ('Rent', Tier.fixed, 'house'),
      ('Phone', Tier.fixed, 'phone'),
      ('Internet', Tier.fixed, 'wifi'),
      ('Electricity', Tier.fixed, 'zap'),
      ('Subscriptions', Tier.fixed, 'tv'),
      ('Transport', Tier.daily, 'bus'),
      ('Food', Tier.daily, 'utensils'),
      ('Tea & snacks', Tier.daily, 'coffee'),
      ('Groceries', Tier.variable, 'cart'),
      ('Shopping', Tier.variable, 'bag'),
      ('Health', Tier.variable, 'heart'),
      ('Entertainment', Tier.variable, 'film'),
      ('Misc', Tier.variable, 'package'),
    ];
    await batch((b) {
      var i = 0;
      for (final (name, tier, icon) in seed) {
        b.insert(categories, CategoriesCompanion.insert(name: name, tier: tier.value, icon: Value(icon), sortOrder: Value(i++)));
      }
    });
  }
}
