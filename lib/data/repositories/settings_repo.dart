import '../../core/constants.dart';
import '../db/database.dart';

/// Typed access to the `settings` table (inside the encrypted DB).
class SettingsRepo {
  SettingsRepo(this.db);
  final AppDatabase db;

  Future<String?> get(String key) async =>
      (await (db.select(db.settings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> set(String key, String value) =>
      db.into(db.settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  Future<void> remove(String key) => (db.delete(db.settings)..where((s) => s.key.equals(key))).go();

  Future<int?> getInt(String key) async => int.tryParse(await get(key) ?? '');
  Future<void> setInt(String key, int v) => set(key, '$v');

  Future<bool> getBool(String key, {bool fallback = false}) async {
    final v = await get(key);
    return v == null ? fallback : v == '1';
  }

  Future<void> setBool(String key, bool v) => set(key, v ? '1' : '0');

  Stream<Map<String, String>> watchAll() =>
      db.select(db.settings).watch().map((rows) => {for (final r in rows) r.key: r.value});

  Future<Map<String, String>> all() async => {for (final r in await db.select(db.settings).get()) r.key: r.value};

  Future<int> salaryAmount() async => await getInt(SettingKeys.salaryAmount) ?? 0;
  Future<int> comfortThreshold() async => await getInt(SettingKeys.comfortThresholdPct) ?? 10;
}
