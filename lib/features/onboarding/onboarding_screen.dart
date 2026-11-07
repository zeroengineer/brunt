import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../design/design.dart';
import '../../security/lock_controller.dart';
import '../accounts/account_form.dart';
import '../common/pickers.dart';
import '../lock/brand.dart';
import '../plan/template_form.dart';

enum _Step { welcome, pin, biometrics, salary, salaryDay, accounts, salaryAccount, committed, daily, done }

/// First launch (spec §4.1): Welcome → PIN → biometrics → salary → salary day →
/// accounts → salary account → priority/savings/fixed → daily items → dashboard.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late _Step _step;
  String _pin = '';
  String? _firstPin;
  String? _pinError;
  final _salary = TextEditingController();
  int _usualDay = 1;
  int _latestDay = 5;
  int? _salaryAccount;
  bool _busy = false;
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    final unlocked = ref.read(lockProvider).phase == LockPhase.unlocked;
    _step = unlocked ? _Step.salary : _Step.welcome;
    if (unlocked) _restore();
  }

  /// Resume an interrupted onboarding with what's already saved.
  Future<void> _restore() async {
    final s = ref.read(sessionProvider);
    if (s == null) return;
    final salary = await s.settings.salaryAmount();
    final usual = await s.settings.getInt(SettingKeys.salaryUsualDay);
    final latest = await s.settings.getInt(SettingKeys.salaryLatestDay);
    final acc = await s.settings.getInt(SettingKeys.salaryAccountId);
    if (!mounted) return;
    setState(() {
      if (salary > 0) _salary.text = rupeesText(salary);
      _usualDay = usual ?? 1;
      _latestDay = latest ?? 5;
      _salaryAccount = acc;
    });
  }

  @override
  void dispose() {
    _salary.dispose();
    super.dispose();
  }

  Session? get _s => ref.read(sessionProvider);

  void _go(_Step s) => setState(() => _step = s);

  void _back() {
    const order = _Step.values;
    var i = order.indexOf(_step) - 1;
    final unlocked = ref.read(lockProvider).phase == LockPhase.unlocked;
    // can't go back into PIN creation once the vault exists
    if (unlocked && i <= _Step.biometrics.index) return;
    if (i < 0) i = 0;
    _go(order[i]);
  }

  // ---------------------------------------------------------------- PIN

  Future<void> _pinDigit(String d) async {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += d;
      _pinError = null;
    });
    if (_pin.length < 6) return;
    if (_firstPin == null) {
      if (RegExp(r'^(\d)\1{5}$').hasMatch(_pin) || _pin == '123456' || _pin == '654321') {
        setState(() {
          _pinError = 'Too easy to guess — try another';
          _pin = '';
        });
        return;
      }
      setState(() {
        _firstPin = _pin;
        _pin = '';
      });
      return;
    }
    if (_pin != _firstPin) {
      setState(() {
        _pinError = "PINs didn't match — start again";
        _pin = '';
        _firstPin = null;
      });
      return;
    }
    setState(() => _busy = true);
    await ref.read(lockProvider.notifier).createPin(_pin);
    final ok = ref.read(lockProvider).phase == LockPhase.unlocked;
    _bioAvailable = ok && await ref.read(lockProvider.notifier).biometricAvailable();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pin = '';
      _firstPin = null;
      if (!ok) _pinError = ref.read(lockProvider).error ?? 'Something went wrong';
    });
    if (ok) _go(_Step.biometrics);
  }

  Future<void> _enableBio() async {
    setState(() => _busy = true);
    final ok = await ref.read(lockProvider.notifier).enableBiometric();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      toast(context, 'Biometric unlock is on');
      _go(_Step.salary);
    } else {
      toast(context, 'Biometrics could not be enabled', error: true);
    }
  }

  // ---------------------------------------------------------------- salary

  Future<void> _saveSalary() async {
    final v = Money.parse(_salary.text) ?? 0;
    if (v <= 0) return toast(context, 'Enter your monthly salary', error: true);
    final s = _s!;
    await s.settings.setInt(SettingKeys.salaryAmount, v);
    final m = await s.engine.latest();
    if (m != null) {
      await (s.db.update(s.db.months)..where((x) => x.id.equals(m.id))).write(MonthsCompanion(salaryExpected: Value(v)));
    }
    _go(_Step.salaryDay);
  }

  Future<void> _saveSalaryDays() async {
    final s = _s!;
    await s.settings.setInt(SettingKeys.salaryUsualDay, _usualDay);
    await s.settings.setInt(SettingKeys.salaryLatestDay, _latestDay < _usualDay ? _usualDay : _latestDay);
    // the month must exist before accounts and templates are added
    await s.engine.createFirstMonth(Dates.day(DateTime.now()));
    _go(_Step.accounts);
  }

  Future<void> _saveSalaryAccount() async {
    if (_salaryAccount == null) return toast(context, 'Choose where salary arrives', error: true);
    final s = _s!;
    await s.settings.setInt(SettingKeys.salaryAccountId, _salaryAccount!);
    final m = await s.engine.latest();
    if (m != null) {
      await (s.db.update(s.db.months)..where((x) => x.id.equals(m.id)))
          .write(MonthsCompanion(salaryAccountId: Value(_salaryAccount)));
    }
    _go(_Step.committed);
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    final s = _s!;
    final today = Dates.day(DateTime.now());
    await s.settings.set(SettingKeys.onboardedAt, Dates.iso(today));
    await s.settings.set(SettingKeys.reminderTime, '21:00');
    await s.settings.setBool(SettingKeys.remindersEnabled, true);
    await s.settings.setBool(SettingKeys.dueRemindersEnabled, true);
    await s.settings.setInt(SettingKeys.comfortThresholdPct, 10);
    await s.settings.set(SettingKeys.autoLock, 'immediate');
    await s.onOpen();
    ref.read(lockProvider.notifier).markOnboarded();
  }

  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final steps = _Step.values.length - 1;
    final showBack = _step.index > _Step.welcome.index && _step != _Step.pin && _step != _Step.biometrics && _step != _Step.salary;
    return GlowBackground(
      centerGlow: _step == _Step.welcome || _step == _Step.pin,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(children: [
            if (_step != _Step.welcome)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(children: [
                  if (showBack)
                    IconButton(tooltip: 'Back', onPressed: _back, icon: const Icon(LucideIcons.chevronLeft))
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _step.index / steps,
                        minHeight: 4,
                        backgroundColor: BColors.surfaceRaised,
                        color: BColors.primaryLight,
                      ),
                    ),
                  ),
                ]),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(key: ValueKey(_step), child: _body()),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _page({required String title, String? sub, required List<Widget> children, Widget? bottom}) {
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 24), children: [
          Text(title, style: BText.h1),
          if (sub != null) ...[const SizedBox(height: 8), Text(sub, style: BText.bodyMuted)],
          const SizedBox(height: 24),
          ...children,
        ]),
      ),
      if (bottom != null) Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: bottom),
    ]);
  }

  Widget _body() {
    switch (_step) {
      case _Step.welcome:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            const BruntMark(size: 84),
            const SizedBox(height: 20),
            const Text('Will this month make it?', style: BText.h2, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text(
              'BRUNT takes the brunt of your month — bills, debts, daily costs — so you always know what is truly left to spend.',
              style: BText.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            const _Promise(icon: LucideIcons.wifiOff, text: 'Fully offline. No account, no cloud, no analytics.'),
            const _Promise(icon: LucideIcons.lock, text: 'Encrypted on this phone with your PIN and biometrics.'),
            const _Promise(icon: LucideIcons.indianRupee, text: 'Plans in rupees, down to the paisa.'),
            const SizedBox(height: 24),
            PillButton(label: 'Get started', expand: true, onPressed: () => _go(_Step.pin)),
          ]),
        );

      case _Step.pin:
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(children: [
            Text(_firstPin == null ? 'Create a 6-digit PIN' : 'Confirm your PIN', style: BText.h1),
            const SizedBox(height: 8),
            Text(
              _pinError ?? 'It encrypts everything in BRUNT. There is no way to recover it.',
              style: BText.bodyMuted.copyWith(color: _pinError != null ? BColors.danger : null),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_busy)
              const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())
            else
              PinPad(
                length: _pin.length,
                error: _pinError != null,
                onDigit: _pinDigit,
                onDelete: () => setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1)),
              ),
          ]),
        );

      case _Step.biometrics:
        return _page(
          title: 'Unlock with biometrics',
          sub: _bioAvailable
              ? 'Use your fingerprint or face to open BRUNT. Your PIN always works as a fallback.'
              : 'No fingerprint or face unlock is set up on this phone. You can turn it on later in Settings.',
          children: [
            const Center(child: IconBadge(icon: LucideIcons.fingerprint, color: BColors.primaryLight, size: 96)),
          ],
          bottom: Column(children: [
            if (_bioAvailable) PillButton(label: 'Enable biometrics', expand: true, busy: _busy, onPressed: _enableBio),
            const SizedBox(height: 10),
            PillButton(label: _bioAvailable ? 'Not now' : 'Continue', variant: PillVariant.outline, expand: true, onPressed: () => _go(_Step.salary)),
          ]),
        );

      case _Step.salary:
        return _page(
          title: 'Monthly salary',
          sub: 'The fixed amount you expect each month. You will mark it "received" on whatever day it arrives.',
          children: [BField.amount(label: 'Salary per month', controller: _salary, autofocus: true)],
          bottom: PillButton(label: 'Continue', expand: true, onPressed: _saveSalary),
        );

      case _Step.salaryDay:
        return _page(
          title: 'When does it arrive?',
          sub: 'Until salary lands, BRUNT checks that your money can bridge the gap.',
          children: [
            AppCard(
              child: Column(children: [
                DayStepper(label: 'Usually on the', value: _usualDay, onChanged: (v) => setState(() {
                      _usualDay = v;
                      if (_latestDay < v) _latestDay = v;
                    }), max: 28, format: Dates.ordinal),
                const Divider(height: 20),
                DayStepper(label: 'Latest it has come', value: _latestDay, min: _usualDay, onChanged: (v) => setState(() => _latestDay = v), max: 31, format: Dates.ordinal),
              ]),
            ),
          ],
          bottom: PillButton(label: 'Continue', expand: true, onPressed: _saveSalaryDays),
        );

      case _Step.accounts:
        return _AccountsStep(onNext: () => _go(_Step.salaryAccount));

      case _Step.salaryAccount:
        final accounts = (ref.watch(accountsProvider).value ?? const <AccountRow>[])
            .where((a) => a.type == AccountType.bank.code || a.type == AccountType.cash.code || a.type == AccountType.wallet.code)
            .toList();
        return _page(
          title: 'Where does salary land?',
          sub: 'Marking salary received adds it to this account. You can change it each month.',
          children: [
            if (accounts.isEmpty)
              const Text('Add a bank or cash account first.', style: BText.bodyMuted)
            else
              ChoicePills<int>(wrap: true, items: accountItems(accounts), selected: _salaryAccount, onChanged: (v) => setState(() => _salaryAccount = v)),
          ],
          bottom: PillButton(label: 'Continue', expand: true, onPressed: _saveSalaryAccount),
        );

      case _Step.committed:
        return _TemplatesStep(
          title: 'Bills, debts & savings',
          sub: 'Monthly commitments, paid in this order: priority → savings → fixed bills. Card bills are added automatically from your cards.',
          scope: TemplateScope.committed,
          suggestions: const [
            ('Rent', 'Rent', 1000000),
            ('Phone', 'Phone', 30000),
            ('Internet', 'Internet', 60000),
            ('Electricity', 'Electricity', 150000),
            ('Loan EMI', 'Loan EMI', 500000),
            ('RD', 'RD', 200000),
            ('SIP', 'SIP', 200000),
            ('Netflix', 'Subscriptions', 19900),
          ],
          onNext: () => _go(_Step.daily),
        );

      case _Step.daily:
        return _TemplatesStep(
          title: 'Daily costs',
          sub: 'Things you spend on most days. Every day is ticked by default — untick any (like Sunday) whenever you want.',
          scope: TemplateScope.daily,
          suggestions: const [
            ('Bus fare', 'Transport', 4000),
            ('Lunch', 'Food', 10000),
            ('Tea', 'Tea & snacks', 2000),
            ('Metro', 'Transport', 6000),
          ],
          nextLabel: 'Finish',
          busy: _busy,
          onNext: _finish,
        );

      case _Step.done:
        return const SizedBox();
    }
  }
}

class _Promise extends StatelessWidget {
  const _Promise({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: BColors.primaryLight),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: BText.body.copyWith(fontSize: 14))),
      ]),
    );
  }
}

class _AccountsStep extends ConsumerWidget {
  const _AccountsStep({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? const <AccountRow>[];
    final quick = <(String, AccountType)>[
      ('Cash in hand', AccountType.cash),
      ('Bank account', AccountType.bank),
      ('GPay', AccountType.upi),
      ('PhonePe', AccountType.upi),
      ('Credit card', AccountType.creditCard),
      ('Savings / RD', AccountType.savings),
      ('Wallet', AccountType.wallet),
    ];
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 24), children: [
          const Text('Where your money lives', style: BText.h1),
          const SizedBox(height: 8),
          const Text('Add cash, bank accounts (and the UPI apps that use them), cards and savings, with what is in them today.',
              style: BText.bodyMuted),
          const SizedBox(height: 20),
          for (final a in accounts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => showAccountForm(context, existing: a),
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  IconBadge(icon: accountIcon(a), color: accountColor(a)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.name, style: BText.body),
                      Text(accountSubtitle(a, accounts), style: BText.caption),
                    ]),
                  ),
                  if (a.type != AccountType.upi.code)
                    Text(Money.format(a.balance), style: BText.amount(color: a.type == AccountType.creditCard.code ? BColors.danger : BColors.text)),
                ]),
              ),
            ),
          const SizedBox(height: 8),
          const Text('Quick add', style: BText.caption),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (name, type) in quick)
              PillButton(
                label: name,
                dense: true,
                variant: PillVariant.soft,
                icon: LucideIcons.plus,
                onPressed: () => showAccountForm(context, presetType: type, presetName: type == AccountType.bank || type == AccountType.creditCard || type == AccountType.savings || type == AccountType.wallet ? null : name),
              ),
          ]),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: PillButton(
          label: 'Continue',
          expand: true,
          onPressed: accounts.any((a) => a.type != AccountType.upi.code && a.type != AccountType.creditCard.code)
              ? onNext
              : null,
        ),
      ),
    ]);
  }
}

class _TemplatesStep extends ConsumerWidget {
  const _TemplatesStep({
    required this.title,
    required this.sub,
    required this.scope,
    required this.suggestions,
    required this.onNext,
    this.nextLabel = 'Continue',
    this.busy = false,
  });

  final String title;
  final String sub;
  final TemplateScope scope;
  final List<(String, String, int)> suggestions;
  final VoidCallback onNext;
  final String nextLabel;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).value ?? const <CategoryRow>[];
    final accounts = ref.watch(accountsProvider).value ?? const <AccountRow>[];
    final daily = scope == TemplateScope.daily;
    final items = (ref.watch(templatesProvider).value ?? const <TemplateRow>[])
        .where((t) => (t.frequency == Frequency.daily.code) == daily)
        .toList();
    final existingNames = items.map((t) => t.name.toLowerCase()).toSet();
    final planned = ref.watch(plannedProvider).value ?? const <PlannedRow>[];
    final today = Dates.day(DateTime.now());
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 24), children: [
          Text(title, style: BText.h1),
          const SizedBox(height: 8),
          Text(sub, style: BText.bodyMuted),
          const SizedBox(height: 20),
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => showTemplateForm(context, existing: t, scope: scope),
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Builder(builder: (_) {
                    final c = cats.byId(t.categoryId);
                    return IconBadge(
                      icon: c == null ? LucideIcons.receipt : categoryIcon(c),
                      color: BColors.tier(Tier.of(c?.tier ?? 3)) == BColors.tierVariable ? BColors.textMuted : BColors.tier(Tier.of(c?.tier ?? 3)),
                    );
                  }),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.name, style: BText.body),
                      Text(
                        [
                          daily ? WeekMask.describe(t.daysOfWeek) : (t.dueDay == null ? 'Anytime' : 'Due ${Dates.ordinal(t.dueDay!)}'),
                          accounts.byId(t.defaultAccountId)?.name,
                        ].whereType<String>().join(' · '),
                        style: BText.caption,
                      ),
                    ]),
                  ),
                  Text(Money.format(t.defaultAmount), style: BText.amount()),
                ]),
              ),
            ),
          // Due day already passed this month? Let the user say it was paid before BRUNT,
          // instead of showing it as overdue on day one.
          for (final t in items)
            if (!daily && t.dueDay != null && t.dueDay! < today.day)
              Builder(builder: (_) {
                final p = planned.where((p) => p.templateId == t.id).firstOrNull;
                if (p == null) return const SizedBox();
                final done = p.status != PlannedStatus.pending.code;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        done
                            ? '${t.name}: marked as paid before BRUNT this month'
                            : '${t.name} was due on the ${Dates.ordinal(t.dueDay!)} — already paid this month?',
                        style: BText.caption,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PillButton(
                      label: done ? 'Undo' : 'Yes, paid',
                      dense: true,
                      variant: done ? PillVariant.soft : PillVariant.outline,
                      onPressed: () => ref
                          .read(sessionProvider)
                          ?.ledger
                          .setPlannedStatus(p.id, done ? PlannedStatus.pending : PlannedStatus.skipped),
                    ),
                  ]),
                );
              }),
          const SizedBox(height: 8),
          const Text('Suggestions', style: BText.caption),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (name, cat, amount) in suggestions)
              if (!existingNames.contains(name.toLowerCase()))
                PillButton(
                  label: name,
                  dense: true,
                  variant: PillVariant.soft,
                  icon: LucideIcons.plus,
                  onPressed: () => showTemplateForm(context, scope: scope, presetName: name, presetCategory: cat, presetAmount: amount),
                ),
            PillButton(
              label: 'Custom',
              dense: true,
              variant: PillVariant.outline,
              icon: LucideIcons.plus,
              onPressed: () => showTemplateForm(context, scope: scope),
            ),
          ]),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: PillButton(label: items.isEmpty ? 'Skip for now' : nextLabel, expand: true, busy: busy, onPressed: onNext,
            variant: items.isEmpty ? PillVariant.outline : PillVariant.primary),
      ),
    ]);
  }
}
