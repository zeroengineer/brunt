import 'package:brunt/app/providers.dart';
import 'package:brunt/app/session.dart';
import 'package:brunt/app/theme.dart';
import 'package:brunt/core/constants.dart';
import 'package:brunt/core/dates.dart';
import 'package:brunt/data/db/database.dart';
import 'package:brunt/data/repositories/ledger.dart';
import 'package:brunt/design/design.dart';
import 'package:brunt/features/accounts/accounts_screen.dart';
import 'package:brunt/features/add_entry/add_entry_sheet.dart';
import 'package:brunt/features/daily_log/daily_log_screen.dart';
import 'package:brunt/features/dashboard/dashboard_view.dart';
import 'package:brunt/features/gallery/gallery_screen.dart';
import 'package:brunt/features/plan/plan_screen.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Seeds an unlocked session for UI tests.
Future<(Session, Map<String, int>)> seeded() async {
  final s = Session(AppDatabase(NativeDatabase.memory()));
  final today = Dates.day(DateTime.now());
  await s.settings.setInt(SettingKeys.salaryAmount, 5000000);
  await s.settings.setInt(SettingKeys.salaryUsualDay, 1);
  await s.settings.setInt(SettingKeys.salaryLatestDay, 28);
  await s.settings.set(SettingKeys.onboardedAt, Dates.iso(Dates.firstOfYearMonth(Dates.yearMonth(today))));
  await s.engine.createFirstMonth(today);
  final cash = await s.catalog.createAccount(name: 'Cash', type: AccountType.cash, startingBalance: 300000);
  final bank = await s.catalog.createAccount(name: 'HDFC', type: AccountType.bank, startingBalance: 2500000);
  await s.catalog.createAccount(name: 'GPay', type: AccountType.upi, linkedAccountId: bank);
  await s.settings.setInt(SettingKeys.salaryAccountId, bank);
  final cats = {for (final c in await s.db.select(s.db.categories).get()) c.name: c.id};
  await s.catalog.createTemplate(TemplatesCompanion.insert(
    categoryId: cats['Rent']!,
    name: 'Rent',
    defaultAmount: 1500000,
    defaultAccountId: Value(bank),
    dueDay: const Value(28),
  ));
  final bus = await s.catalog.createTemplate(TemplatesCompanion.insert(
    categoryId: cats['Transport']!,
    name: 'Bus fare',
    defaultAmount: 4000,
    defaultAccountId: Value(cash),
    frequency: const Value('daily'),
  ));
  return (s, {'cash': cash, 'bank': bank, 'bus': bus, 'groceries': cats['Groceries']!});
}

Widget host(Session s, Widget child) => ProviderScope(
      overrides: [sessionProvider.overrideWithValue(s)],
      child: MaterialApp(theme: buildTheme(), home: GlowBackground(child: Scaffold(backgroundColor: Colors.transparent, body: child))),
    );

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Manrope');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(rootBundle.load('assets/fonts/Manrope-$w.ttf'));
    }
    await loader.load();
  });

  setUp(() {
    final v = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    // phone width (360dp), very tall so lazy lists build every row
    v.physicalSize = const Size(1080, 9000);
    v.devicePixelRatio = 3;
  });

  testWidgets('component gallery renders', (t) async {
    await t.pumpWidget(MaterialApp(theme: buildTheme(), home: const GalleryScreen()));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Pill buttons'), findsOneWidget);
    expect(find.byType(MoneyRing), findsOneWidget);
    expect(find.byType(PillNavBar), findsOneWidget);
  });

  testWidgets('dashboard shows spendable balance, salary card and status', (t) async {
    final (s, _) = (await t.runAsync(seeded))!;
    await t.pumpWidget(host(s, const DashboardView()));
    await settle(t);
    expect(find.text('Spendable now'), findsWidgets);
    expect(find.text('₹28,000'), findsWidgets);
    expect(find.text('Salary pending'), findsOneWidget);
    expect(find.text('Safe to spend today'), findsOneWidget);
    expect(find.textContaining('Rent'), findsWidgets);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('plan view lists the rent item as pending', (t) async {
    final (s, _) = (await t.runAsync(seeded))!;
    await t.pumpWidget(host(s, const PlanView()));
    await settle(t);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.byType(StatusChip), findsWidgets);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('daily log: As usual deducts cash', (t) async {
    final (s, ids) = (await t.runAsync(seeded))!;
    await t.pumpWidget(host(s, const DailyLogScreen()));
    await settle(t);
    expect(find.text('Bus fare'), findsOneWidget);
    await t.tap(find.text('As usual'));
    await settle(t);
    final cash = (await t.runAsync(() => (s.db.select(s.db.accounts)..where((a) => a.id.equals(ids['cash']!))).getSingle()))!;
    expect(cash.balance, 296000);
    expect(find.text('Undo'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('accounts screen shows summary and cards', (t) async {
    final (s, _) = (await t.runAsync(seeded))!;
    await t.pumpWidget(host(s, const AccountsScreen()));
    await settle(t);
    expect(find.text('Spendable'), findsOneWidget);
    expect(find.text('Net worth'), findsOneWidget);
    expect(find.text('HDFC'), findsOneWidget);
    expect(find.textContaining('via HDFC'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('add entry sheet records an expense via the keypad', (t) async {
    final (s, ids) = (await t.runAsync(seeded))!;
    await t.pumpWidget(host(s, Builder(builder: (ctx) => Center(child: TextButton(onPressed: () => showAddEntrySheet(ctx), child: const Text('open'))))));
    await settle(t);
    await t.tap(find.text('open'));
    await settle(t);
    for (final k in ['2', '5', '0']) {
      await t.tap(find.text(k).last);
      await t.pump();
    }
    expect(find.text('₹250'), findsOneWidget);
    await t.dragUntilVisible(find.text('Groceries'), find.byType(ListView).first, const Offset(-120, 0));
    await t.ensureVisible(find.text('Groceries'));
    await settle(t);
    await t.tap(find.text('Groceries'));
    await settle(t);
    await t.tap(find.text('GPay'));
    await t.pump();
    await t.tap(find.text('Save expense'));
    await settle(t);
    final txs = (await t.runAsync(() => s.db.select(s.db.transactions).get()))!;
    expect(txs.single.amount, 25000);
    expect(txs.single.accountId, ids['bank']);
    expect(txs.single.categoryId, ids['groceries']);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  });

  test('ledger exceptions are user-readable', () {
    expect(const LedgerException('Pick an account').toString(), 'Pick an account');
  });
}
