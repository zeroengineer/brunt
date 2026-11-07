import '../core/constants.dart';
import '../core/dates.dart';
import '../data/db/database.dart';
import '../data/repositories/catalog_repo.dart';
import '../data/repositories/ledger.dart';
import '../data/repositories/month_engine.dart';
import '../data/repositories/queries.dart';
import '../data/repositories/settings_repo.dart';
import '../data/repositories/stats_repo.dart';

/// Everything that needs the unlocked database. Exists only while the app is unlocked.
class Session {
  Session(this.db)
      : settings = SettingsRepo(db),
        ledger = Ledger(db),
        stats = StatsRepo(db),
        queries = Queries(db) {
    engine = MonthEngine(db, ledger, settings, stats);
    catalog = CatalogRepo(db, ledger, engine);
  }

  final AppDatabase db;
  final SettingsRepo settings;
  final Ledger ledger;
  final StatsRepo stats;
  final Queries queries;
  late final MonthEngine engine;
  late final CatalogRepo catalog;

  Future<bool> isOnboarded() async => await settings.get(SettingKeys.onboardedAt) != null;

  /// Runs on unlock and on resume: idempotent month rollover + card bills.
  Future<void> onOpen() => engine.ensureCurrent(Dates.day(DateTime.now()));

  Future<void> close() => db.close();
}
