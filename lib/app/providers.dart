import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../security/lock_controller.dart';
import 'session.dart';

/// Unlocked session (null while locked). Every data provider derives from it, so locking
/// tears the whole cache down.
final sessionProvider = Provider<Session?>((ref) => ref.watch(lockProvider.select((s) => s.session)));

Stream<T> _whenUnlocked<T>(Ref ref, Stream<T> Function(Session s) f) {
  final s = ref.watch(sessionProvider);
  return s == null ? const Stream.empty() : f(s);
}

final accountsProvider = StreamProvider<List<AccountRow>>((ref) => _whenUnlocked(ref, (s) => s.queries.watchAccounts()));

final allAccountsProvider =
    StreamProvider<List<AccountRow>>((ref) => _whenUnlocked(ref, (s) => s.queries.watchAccounts(includeArchived: true)));

final categoriesProvider = StreamProvider<List<CategoryRow>>((ref) => _whenUnlocked(ref, (s) => s.queries.watchCategories()));

final templatesProvider = StreamProvider<List<TemplateRow>>((ref) => _whenUnlocked(ref, (s) => s.queries.watchTemplates()));

final monthProvider = StreamProvider<MonthRow?>((ref) => _whenUnlocked(ref, (s) => s.queries.watchLatestMonth()));

final settingsProvider = StreamProvider<Map<String, String>>((ref) => _whenUnlocked(ref, (s) => s.settings.watchAll()));

/// Cache key for computed month state (spec §10.1 L1): (month id, version).
final monthKeyProvider = Provider<(int, int)?>((ref) {
  final m = ref.watch(monthProvider).value;
  return m == null ? null : (m.id, m.version);
});

final plannedProvider = StreamProvider<List<PlannedRow>>((ref) {
  final id = ref.watch(monthProvider.select((m) => m.value?.id));
  return _whenUnlocked(ref, (s) => id == null ? const Stream.empty() : s.queries.watchPlanned(id));
});

final recentTxProvider = StreamProvider<List<TxRow>>((ref) => _whenUnlocked(ref, (s) => s.queries.watchRecent(limit: 8)));

/// Lookup helpers.
extension AccountLookup on List<AccountRow> {
  AccountRow? byId(int? id) => id == null ? null : where((a) => a.id == id).firstOrNull;
}

extension CategoryLookup on List<CategoryRow> {
  CategoryRow? byId(int? id) => id == null ? null : where((c) => c.id == id).firstOrNull;
}
