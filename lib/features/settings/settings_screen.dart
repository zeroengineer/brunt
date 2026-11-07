import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../design/design.dart';
import '../../security/device_integrity.dart';
import '../../security/lock_controller.dart';
import '../../security/reauth.dart';
import '../../security/screen_guard.dart';
import '../common/pickers.dart';
import 'backup_flow.dart';
import 'notifications.dart';

final compromisedProvider = FutureProvider<bool>((ref) => DeviceIntegrity.isCompromised());
final wipeAfterProvider = FutureProvider<int>((ref) => ref.read(keyManagerProvider).wipeAfter());

/// Settings (spec §11.5 #9).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const <String, String>{};
    final accounts = ref.watch(accountsProvider).value ?? const <AccountRow>[];
    final lock = ref.watch(lockProvider);
    final compromised = ref.watch(compromisedProvider).value ?? false;
    final wipeAfter = ref.watch(wipeAfterProvider).value ?? 0;
    final s = ref.watch(sessionProvider);

    int? intOf(String k) => int.tryParse(settings[k] ?? '');
    final salary = intOf(SettingKeys.salaryAmount) ?? 0;
    final usual = intOf(SettingKeys.salaryUsualDay);
    final latest = intOf(SettingKeys.salaryLatestDay);
    final salaryAcc = accounts.byId(intOf(SettingKeys.salaryAccountId));
    final budget = intOf(SettingKeys.variableBudget);
    final threshold = intOf(SettingKeys.comfortThresholdPct) ?? 10;
    final cardWarn = intOf(SettingKeys.cardWarnPct) ?? 80;
    final remindersOn = settings[SettingKeys.remindersEnabled] != '0';
    final dueOn = settings[SettingKeys.dueRemindersEnabled] != '0';
    final time = settings[SettingKeys.reminderTime] ?? '21:00';
    final autoLock = settings[SettingKeys.autoLock] ?? 'immediate';
    final blockShots = settings['block_screenshots'] != '0';

    Future<void> setAndSync(String k, String v) async {
      if (s == null) return;
      await s.settings.set(k, v);
      await Reminders.instance.syncFromSession(s);
    }

    return BruntScaffold(
      title: 'Settings',
      showBack: true,
      actions: [
        IconButton(
          tooltip: 'Lock now',
          onPressed: () => ref.read(lockProvider.notifier).lock(),
          icon: const Icon(LucideIcons.lock),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(BSpace.gutter, 0, BSpace.gutter, 60),
        children: [
          if (compromised) ...[
            const InfoBanner(
              icon: LucideIcons.shieldAlert,
              color: BColors.warning,
              title: 'This device looks rooted or jailbroken',
              message: 'BRUNT encrypts your data, but a compromised device can be read by other apps or malware.',
            ),
            const SizedBox(height: 8),
          ],
          const SectionHeader('Salary'),
          _Group(children: [
            _Tile(
              icon: LucideIcons.indianRupee,
              title: 'Monthly salary',
              value: Money.format(salary),
              onTap: () => _editAmount(context, ref, 'Monthly salary', SettingKeys.salaryAmount, salary, alsoMonth: true),
            ),
            _Tile(
              icon: LucideIcons.calendarDays,
              title: 'Arrival day',
              value: usual == null ? '—' : 'Usually ${Dates.ordinal(usual)}${latest != null ? ', latest ${Dates.ordinal(latest)}' : ''}',
              onTap: () => _editDays(context, ref, usual ?? 1, latest ?? usual ?? 1),
            ),
            _Tile(
              icon: LucideIcons.landmark,
              title: 'Salary account',
              value: salaryAcc?.name ?? '—',
              onTap: () => _pickSalaryAccount(context, ref, accounts),
            ),
          ]),
          const SectionHeader('Planning'),
          _Group(children: [
            _Tile(icon: LucideIcons.repeat, title: 'Recurring items & schedules', onTap: () => context.push('/templates')),
            _Tile(icon: LucideIcons.tags, title: 'Categories', onTap: () => context.push('/categories')),
            _Tile(
              icon: LucideIcons.shoppingCart,
              title: 'Variable budget',
              value: budget == null ? 'Auto (3-month median)' : Money.format(budget),
              onTap: () => _editBudget(context, ref, budget),
            ),
            _Tile(
              icon: LucideIcons.gauge,
              title: 'Comfortable above',
              value: '$threshold% of salary',
              onTap: () => _pickPct(context, ref, 'Comfortable when month-end is at least…', SettingKeys.comfortThresholdPct, threshold,
                  const [0, 5, 10, 15, 20, 25, 30]),
            ),
            _Tile(
              icon: LucideIcons.creditCard,
              title: 'Card limit warning',
              value: 'at $cardWarn%',
              onTap: () => _pickPct(context, ref, 'Warn when a card reaches…', SettingKeys.cardWarnPct, cardWarn, const [50, 60, 70, 80, 90]),
            ),
          ]),
          const SectionHeader('Reminders'),
          _Group(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SwitchRow(
                label: 'Daily log reminder',
                sub: 'Never shows amounts on the lock screen',
                value: remindersOn,
                onChanged: (v) async {
                  if (v) await Reminders.instance.requestPermission();
                  await setAndSync(SettingKeys.remindersEnabled, v ? '1' : '0');
                },
              ),
            ),
            if (remindersOn)
              _Tile(
                icon: LucideIcons.clock,
                title: 'Reminder time',
                value: time,
                onTap: () async {
                  final p = time.split(':');
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])),
                  );
                  if (t != null) {
                    await setAndSync(SettingKeys.reminderTime, '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                  }
                },
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SwitchRow(
                label: 'Due-date reminders',
                sub: '9 AM on the day a bill is due',
                value: dueOn,
                onChanged: (v) async {
                  if (v) await Reminders.instance.requestPermission();
                  await setAndSync(SettingKeys.dueRemindersEnabled, v ? '1' : '0');
                },
              ),
            ),
          ]),
          const SectionHeader('Security'),
          _Group(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SwitchRow(
                label: 'Biometric unlock',
                value: lock.biometricEnabled,
                onChanged: (v) async {
                  if (!await reauthenticate(context, ref, reason: v ? 'Confirm to enable biometrics' : 'Confirm to disable biometrics')) return;
                  final c = ref.read(lockProvider.notifier);
                  if (v) {
                    final ok = await c.enableBiometric();
                    if (!ok && context.mounted) toast(context, 'No biometrics available on this phone', error: true);
                  } else {
                    await c.disableBiometric();
                  }
                },
              ),
            ),
            _Tile(
              icon: LucideIcons.keyRound,
              title: 'Change PIN',
              onTap: () async {
                final c = ref.read(lockProvider.notifier);
                final old = await _askCurrentPin(context);
                if (old == null || !context.mounted) return;
                if (!await c.verifyPin(old)) {
                  if (context.mounted) toast(context, 'Wrong PIN', error: true);
                  return;
                }
                if (!context.mounted) return;
                final next = await askNewPin(context);
                if (next == null) return;
                final ok = await c.changePin(old, next);
                if (context.mounted) toast(context, ok ? 'PIN changed' : 'Could not change PIN', error: !ok);
              },
            ),
            _Tile(
              icon: LucideIcons.timer,
              title: 'Auto-lock',
              value: switch (autoLock) { '1m' => 'After 1 minute', '5m' => 'After 5 minutes', _ => 'Immediately' },
              onTap: () async {
                final v = await _choose(context, 'Lock when BRUNT is in the background', {
                  'immediate': 'Immediately',
                  '1m': 'After 1 minute',
                  '5m': 'After 5 minutes',
                }, autoLock);
                if (v == null || s == null) return;
                await s.settings.set(SettingKeys.autoLock, v);
                await ref.read(lockProvider.notifier).reloadAutoLock();
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SwitchRow(
                label: 'Wipe after 15 wrong PINs',
                sub: 'Erases all data permanently',
                value: wipeAfter > 0,
                onChanged: (v) async {
                  if (!await reauthenticate(context, ref, reason: 'Confirm to change wipe protection')) return;
                  await ref.read(keyManagerProvider).setWipeAfter(v ? 15 : 0);
                  ref.invalidate(wipeAfterProvider);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SwitchRow(
                label: 'Block screenshots',
                sub: 'Also hides BRUNT in the app switcher',
                value: blockShots,
                onChanged: (v) async {
                  await s?.settings.set('block_screenshots', v ? '1' : '0');
                  v ? await ScreenGuard.enable() : await ScreenGuard.disable();
                },
              ),
            ),
          ]),
          const SectionHeader('Your data'),
          _Group(children: [
            _Tile(icon: LucideIcons.download, title: 'Export encrypted backup', onTap: () => exportBackup(context, ref)),
            _Tile(icon: LucideIcons.upload, title: 'Restore from backup', onTap: () => restoreBackup(context, ref)),
            _Tile(
              icon: LucideIcons.shieldCheck,
              title: 'Verify balances',
              value: 'Recompute from entries',
              onTap: () async {
                if (s == null) return;
                final fixed = await s.engine.verifyBalances();
                if (context.mounted) {
                  toast(context, fixed == 0 ? 'All balances match their entries' : 'Repaired $fixed account${fixed == 1 ? '' : 's'}');
                }
              },
            ),
            _Tile(
              icon: LucideIcons.trash2,
              title: 'Erase everything',
              danger: true,
              onTap: () async {
                if (!await reauthenticate(context, ref, reason: 'Confirm to erase all data')) return;
                if (!context.mounted) return;
                final ok = await confirmDialog(context,
                    title: 'Erase everything?',
                    message: 'All accounts, entries and keys are destroyed. Export a backup first if you might need it.',
                    confirm: 'Erase',
                    danger: true);
                if (ok) {
                  await Reminders.instance.cancelAll();
                  await ref.read(lockProvider.notifier).wipeEverything();
                }
              },
            ),
          ]),
          const SectionHeader('About'),
          _Group(children: [
            _Tile(icon: LucideIcons.chartColumn, title: 'Insights', onTap: () => context.push('/insights')),
            _Tile(icon: LucideIcons.history, title: 'History', onTap: () => context.push('/history')),
            const _Tile(
              icon: LucideIcons.wifiOff,
              title: 'Privacy',
              value: 'Collects no data',
              sub: 'BRUNT has no internet permission. Everything stays encrypted on this phone.',
            ),
          ]),
          const SizedBox(height: 24),
          const Center(child: Text('BRUNT 1.0 · Your money. Your phone. Nowhere else.', style: BText.caption)),
        ],
      ),
    );
  }

  Future<String?> _askCurrentPin(BuildContext context) => showBruntSheet<String>(context, builder: (ctx) {
        var pin = '';
        return StatefulBuilder(
          builder: (ctx, set) => Column(children: [
            const Text('Current PIN', style: BText.h2),
            const SizedBox(height: 20),
            PinPad(
              length: pin.length,
              onDigit: (d) {
                set(() => pin += d);
                if (pin.length == 6) Navigator.pop(ctx, pin);
              },
              onDelete: () => set(() => pin = pin.isEmpty ? '' : pin.substring(0, pin.length - 1)),
            ),
          ]),
        );
      });

  Future<String?> _choose(BuildContext context, String title, Map<String, String> options, String current) =>
      showBruntSheet<String>(
        context,
        builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: BText.h2),
          const SizedBox(height: 12),
          for (final e in options.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.value, style: BText.body),
              trailing: e.key == current ? const Icon(LucideIcons.check, color: BColors.primaryLight) : null,
              onTap: () => Navigator.pop(ctx, e.key),
            ),
        ]),
      );

  Future<void> _pickPct(BuildContext context, WidgetRef ref, String title, String key, int current, List<int> options) async {
    final v = await _choose(context, title, {for (final o in options) '$o': '$o%'}, '$current');
    if (v != null) await ref.read(sessionProvider)?.settings.set(key, v);
    await ref.read(sessionProvider)?.ledger.touchLatest();
  }

  Future<void> _editAmount(BuildContext context, WidgetRef ref, String title, String key, int current, {bool alsoMonth = false}) async {
    final ctrl = TextEditingController(text: rupeesText(current));
    final ok = await showBruntSheet<bool>(
      context,
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: BText.h2),
        if (alsoMonth) ...[
          const SizedBox(height: 6),
          const Text('Applies to this month (if salary is still pending) and every month after.', style: BText.bodyMuted),
        ],
        const SizedBox(height: 16),
        BField.amount(label: 'Amount', controller: ctrl, autofocus: true),
        const SizedBox(height: 18),
        PillButton(label: 'Save', expand: true, onPressed: () => Navigator.pop(ctx, true)),
      ]),
    );
    final v = Money.parse(ctrl.text);
    ctrl.dispose();
    final s = ref.read(sessionProvider);
    if (ok != true || v == null || s == null) return;
    await s.settings.setInt(key, v);
    if (alsoMonth) {
      final m = await s.engine.latest();
      if (m != null && m.salaryReceived == null) {
        await s.db.customUpdate('UPDATE months SET salary_expected = ?, version = version + 1 WHERE id = ?',
            variables: [Variable.withInt(v), Variable.withInt(m.id)], updates: {s.db.months});
      }
    }
  }

  Future<void> _editBudget(BuildContext context, WidgetRef ref, int? current) async {
    final ctrl = TextEditingController(text: rupeesText(current ?? 0));
    final res = await showBruntSheet<String>(
      context,
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Variable budget', style: BText.h2),
        const SizedBox(height: 6),
        const Text('Groceries, shopping and misc per month. Leave on Auto to use the median of your last 3 months.', style: BText.bodyMuted),
        const SizedBox(height: 16),
        BField.amount(label: 'Monthly budget', controller: ctrl),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: PillButton(label: 'Auto', variant: PillVariant.outline, expand: true, onPressed: () => Navigator.pop(ctx, 'auto'))),
          const SizedBox(width: 10),
          Expanded(child: PillButton(label: 'Save', expand: true, onPressed: () => Navigator.pop(ctx, 'save'))),
        ]),
      ]),
    );
    final v = Money.parse(ctrl.text);
    ctrl.dispose();
    final s = ref.read(sessionProvider);
    if (res == null || s == null) return;
    if (res == 'auto') {
      await s.settings.remove(SettingKeys.variableBudget);
    } else if (v != null) {
      await s.settings.setInt(SettingKeys.variableBudget, v);
    }
    await s.ledger.touchLatest();
  }

  Future<void> _editDays(BuildContext context, WidgetRef ref, int usual, int latest) async {
    var u = usual;
    var l = latest < usual ? usual : latest;
    final ok = await showBruntSheet<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Salary arrival', style: BText.h2),
          const SizedBox(height: 6),
          const Text('Your real history (from marking salary received) takes over once there is some.', style: BText.bodyMuted),
          const SizedBox(height: 12),
          DayStepper(label: 'Usually on the', value: u, max: 28, format: Dates.ordinal, onChanged: (v) => set(() {
                u = v;
                if (l < v) l = v;
              })),
          DayStepper(label: 'Latest it has come', value: l, min: u, format: Dates.ordinal, onChanged: (v) => set(() => l = v)),
          const SizedBox(height: 18),
          PillButton(label: 'Save', expand: true, onPressed: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    final s = ref.read(sessionProvider);
    if (ok != true || s == null) return;
    await s.settings.setInt(SettingKeys.salaryUsualDay, u);
    await s.settings.setInt(SettingKeys.salaryLatestDay, l);
    await s.ledger.touchLatest();
  }

  Future<void> _pickSalaryAccount(BuildContext context, WidgetRef ref, List<AccountRow> accounts) async {
    final list = accounts.where((a) => a.type == 'bank' || a.type == 'cash' || a.type == 'wallet').toList();
    final v = await showBruntSheet<int>(
      context,
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Salary account', style: BText.h2),
        const SizedBox(height: 16),
        ChoicePills<int>(wrap: true, items: accountItems(list), selected: null, onChanged: (v) => Navigator.pop(ctx, v)),
      ]),
    );
    final s = ref.read(sessionProvider);
    if (v == null || s == null) return;
    await s.settings.setInt(SettingKeys.salaryAccountId, v);
    final m = await s.engine.latest();
    if (m != null && m.salaryReceived == null) {
      await s.db.customUpdate('UPDATE months SET salary_account_id = ?, version = version + 1 WHERE id = ?',
          variables: [Variable.withInt(v), Variable.withInt(m.id)], updates: {s.db.months});
    }
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(indent: 14, endIndent: 14),
          children[i],
        ],
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, this.value, this.sub, this.onTap, this.danger = false});
  final IconData icon;
  final String title;
  final String? value;
  final String? sub;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Icon(icon, size: 20, color: danger ? BColors.danger : BColors.primaryLight),
      title: Text(title, style: BText.body.copyWith(color: danger ? BColors.danger : null)),
      subtitle: sub == null ? null : Text(sub!, style: BText.caption),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (value != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(value!, style: BText.caption.copyWith(color: BColors.textMuted), overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
          ),
        if (onTap != null) const Icon(Icons.chevron_right_rounded, color: BColors.textMuted),
      ]),
    );
  }
}
