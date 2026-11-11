import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/repositories/ledger.dart';
import '../../domain/schedule/schedule_expander.dart';
import '../../data/repositories/month_engine.dart' show specOf;
import '../../design/design.dart';
import '../common/pickers.dart';

final dailyLogsProvider = StreamProvider.family<List<DailyLogRow>, (String, String)>((ref, range) {
  final s = ref.watch(sessionProvider);
  return s == null ? const Stream.empty() : s.queries.watchDailyLogs(range.$1, range.$2);
});

/// Daily quick log (spec §4.5): date strip + ✓ As usual · Edit amount · Skip, with account chip.
class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  DateTime _day = Dates.day(DateTime.now());
  final Map<int, int> _accountOverride = {};

  Future<void> _log(TemplateRow t, DailyLogState state, {int? amount, int? account}) async {
    final s = ref.read(sessionProvider);
    if (s == null) return;
    try {
      await s.ledger.logDaily(
        date: _day,
        templateId: t.id,
        state: state,
        amount: amount,
        accountId: account ?? _accountOverride[t.id] ?? t.defaultAccountId,
      );
    } on LedgerException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _edit(TemplateRow t, DailyLogRow? log, List<AccountRow> accounts) async {
    final ctrl = TextEditingController(text: rupeesText(log?.amount ?? t.defaultAmount));
    int? acc = log?.accountId ?? _accountOverride[t.id] ?? t.defaultAccountId;
    final ok = await showBruntSheet<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.name, style: BText.h2),
          Text('Only for ${Dates.short(_day)}. To change every day, edit ${t.name} in Recurring items.', style: BText.caption),
          const SizedBox(height: 18),
          BField.amount(label: 'Amount spent', controller: ctrl, autofocus: true),
          const SizedBox(height: 14),
          const Text('Paid from', style: BText.caption),
          const SizedBox(height: 8),
          ChoicePills<int>(items: accountItems(accounts), selected: acc, onChanged: (v) => set(() => acc = v)),
          const SizedBox(height: 20),
          PillButton(label: 'Save', expand: true, onPressed: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    final amt = Money.parse(ctrl.text);
    ctrl.dispose();
    if (ok == true && amt != null) {
      await _log(t, amt == t.defaultAmount ? DailyLogState.confirmed : DailyLogState.edited, amount: amt, account: acc);
    }
  }

  Future<void> _pickAccount(TemplateRow t, DailyLogRow? log, List<AccountRow> accounts) async {
    final picked = await showBruntSheet<int>(
      context,
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Account for ${t.name}', style: BText.h2),
        const SizedBox(height: 4),
        Text('Only for ${Dates.short(_day)}', style: BText.caption),
        const SizedBox(height: 16),
        ChoicePills<int>(
          wrap: true,
          items: accountItems(accounts),
          selected: log?.accountId ?? _accountOverride[t.id] ?? t.defaultAccountId,
          onChanged: (v) => Navigator.pop(ctx, v),
        ),
      ]),
    );
    if (picked == null) return;
    setState(() => _accountOverride[t.id] = picked);
    if (log != null && log.state != DailyLogState.skipped.code) {
      await _log(t, DailyLogState.of(log.state), amount: log.amount, account: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(monthProvider).value;
    final settings = ref.watch(settingsProvider).value ?? const <String, String>{};
    final templates = (ref.watch(templatesProvider).value ?? const <TemplateRow>[])
        .where((t) => t.frequency == Frequency.daily.code)
        .toList();
    final accounts = (ref.watch(accountsProvider).value ?? const <AccountRow>[])
        .where((a) => a.type != AccountType.savings.code)
        .toList();
    if (month == null) return const Center(child: CircularProgressIndicator());

    final today = Dates.day(DateTime.now());
    final first = Dates.firstOfYearMonth(month.yearMonth);
    final onboarded = settings[SettingKeys.onboardedAt];
    final startDay = onboarded != null && onboarded.isNotEmpty && Dates.parseIso(onboarded).isAfter(first) ? Dates.parseIso(onboarded) : first;
    final days = Dates.range(startDay.isAfter(today) ? today : startDay, today).toList();
    if (!days.any((d) => DateUtils.isSameDay(d, _day))) _day = today;

    final logs = ref.watch(dailyLogsProvider((Dates.iso(first), Dates.iso(today)))).value ?? const <DailyLogRow>[];
    final byKey = {for (final l in logs) (l.date, l.templateId): l};
    List<TemplateRow> activeOn(DateTime d) =>
        templates.where((t) => ScheduleExpander.dailyOccurrences(specOf(t), d, d).isNotEmpty).toList();

    final marks = <DateTime, DayMark>{};
    for (final d in days) {
      final items = activeOn(d);
      if (items.isEmpty) continue;
      final n = items.where((t) => byKey.containsKey((Dates.iso(d), t.id))).length;
      marks[d] = n == items.length ? DayMark.done : (n > 0 ? DayMark.partial : (d.isBefore(today) ? DayMark.missed : DayMark.none));
    }

    final todays = activeOn(_day);
    final iso = Dates.iso(_day);
    final unlogged = todays.where((t) => !byKey.containsKey((iso, t.id))).toList();
    final spent = todays.fold<int>(0, (s, t) {
      final l = byKey[(iso, t.id)];
      return s + (l != null && l.state != DailyLogState.skipped.code ? (l.amount ?? 0) : 0);
    });

    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(BSpace.gutter + 4, 10, BSpace.gutter, 12),
          child: Row(children: [
            Expanded(child: Semantics(header: true, child: const Text('Daily log', style: BText.h1))),
            Text(DateUtils.isSameDay(_day, today) ? 'Today' : Dates.short(_day), style: BText.label.copyWith(color: BColors.primaryLight)),
          ]),
        ),
        DateStrip(days: days, selected: _day, marks: marks, onChanged: (d) => setState(() => _day = d)),
        Expanded(
          child: templates.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.coffee,
                  title: 'No daily items',
                  message: 'Add bus fare, food or tea as a daily recurring item to log it here in two taps.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(BSpace.gutter, 16, BSpace.gutter, 120),
                  children: [
                    if (todays.isEmpty)
                      EmptyState(icon: LucideIcons.sun, title: 'Nothing scheduled', message: 'No daily items run on ${Dates.weekdayShort[_day.weekday - 1]}.')
                    else ...[
                      Row(children: [
                        Expanded(child: Text('Spent ${Money.format(spent)}', style: BText.label.copyWith(color: BColors.textMuted))),
                        if (unlogged.isNotEmpty) ...[
                          PillButton(
                            label: 'Skip day',
                            dense: true,
                            variant: PillVariant.outline,
                            onPressed: () async {
                              for (final t in unlogged) {
                                await _log(t, DailyLogState.skipped);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          PillButton(
                            label: 'All as usual',
                            dense: true,
                            icon: LucideIcons.checkCheck,
                            onPressed: () async {
                              for (final t in unlogged) {
                                await _log(t, DailyLogState.confirmed);
                              }
                            },
                          ),
                        ],
                      ]),
                      const SizedBox(height: 14),
                      for (final t in todays)
                        _DailyTile(
                          template: t,
                          log: byKey[(iso, t.id)],
                          account: accounts.byId(byKey[(iso, t.id)]?.accountId ?? _accountOverride[t.id] ?? t.defaultAccountId),
                          onConfirm: () => _log(t, DailyLogState.confirmed),
                          onEdit: () => _edit(t, byKey[(iso, t.id)], accounts),
                          onSkip: () => _log(t, DailyLogState.skipped),
                          onUndo: () => ref.read(sessionProvider)?.ledger.clearDaily(date: _day, templateId: t.id),
                          onAccount: () => _pickAccount(t, byKey[(iso, t.id)], accounts),
                        ),
                    ],
                  ],
                ),
        ),
      ]),
    );
  }
}

class _DailyTile extends StatelessWidget {
  const _DailyTile({
    required this.template,
    required this.log,
    required this.account,
    required this.onConfirm,
    required this.onEdit,
    required this.onSkip,
    required this.onUndo,
    required this.onAccount,
  });

  final TemplateRow template;
  final DailyLogRow? log;
  final AccountRow? account;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onSkip;
  final VoidCallback onUndo;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    final state = log == null ? null : DailyLogState.of(log!.state);
    final skipped = state == DailyLogState.skipped;
    final amount = log?.amount ?? template.defaultAmount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        borderColor: state == null ? BColors.primaryLight.withValues(alpha: 0.18) : null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(template.name, style: BText.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onAccount,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: BColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(BRadius.pill),
                      border: Border.all(color: BColors.borderStrong),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(account == null ? LucideIcons.wallet : accountIcon(account!), size: 13, color: account == null ? BColors.textMuted : accountColor(account!)),
                      const SizedBox(width: 5),
                      Text(account?.name ?? 'Pick account', style: BText.caption.copyWith(color: BColors.text, fontSize: 11.5)),
                      const SizedBox(width: 2),
                      const Icon(Icons.expand_more_rounded, size: 14, color: BColors.textMuted),
                    ]),
                  ),
                ),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(skipped ? '—' : Money.format(amount),
                  style: BText.amount(size: 17, color: state == null ? BColors.textMuted : BColors.text)),
              const SizedBox(height: 6),
              StatusChip(switch (state) {
                null => ChipStatus.unconfirmed,
                DailyLogState.skipped => ChipStatus.skipped,
                DailyLogState.edited => ChipStatus.confirmed,
                DailyLogState.confirmed => ChipStatus.confirmed,
              }, label: state == DailyLogState.edited ? 'Edited' : null),
            ]),
          ]),
          const SizedBox(height: 12),
          if (state == null)
            Row(children: [
              Expanded(flex: 5, child: PillButton(label: 'As usual', icon: LucideIcons.check, dense: true, expand: true, onPressed: onConfirm)),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: PillButton(label: 'Edit', dense: true, expand: true, variant: PillVariant.outline, onPressed: onEdit)),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: PillButton(label: 'Skip', dense: true, expand: true, variant: PillVariant.soft, onPressed: onSkip)),
            ])
          else
            Row(children: [
              Expanded(child: PillButton(label: 'Change', icon: LucideIcons.pencil, dense: true, expand: true, variant: PillVariant.soft, onPressed: onEdit)),
              const SizedBox(width: 8),
              Expanded(child: PillButton(label: 'Undo', icon: LucideIcons.undo2, dense: true, expand: true, variant: PillVariant.outline, onPressed: onUndo)),
            ]),
        ]),
      ),
    );
  }
}
