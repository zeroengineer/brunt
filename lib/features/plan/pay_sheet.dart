import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/repositories/ledger.dart';
import '../../design/design.dart';
import '../common/pickers.dart';

/// Mark a planned item paid / skipped (spec §4.4).
Future<void> showPaySheet(BuildContext context, PlannedRow item) =>
    showBruntSheet<void>(context, builder: (_) => _PaySheet(item: item));

class _PaySheet extends ConsumerStatefulWidget {
  const _PaySheet({required this.item});
  final PlannedRow item;

  @override
  ConsumerState<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends ConsumerState<_PaySheet> {
  late final TextEditingController _amount;
  int? _account;
  DateTime _date = Dates.day(DateTime.now());
  bool _busy = false;
  bool _init = false;

  /// Set when this item is a Reserve: the money stays in this bank, only set aside.
  bool _reserve = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: rupeesText(widget.item.amount));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _defaults() async {
    if (_init) return;
    _init = true;
    final s = ref.read(sessionProvider);
    if (s == null) return;
    int? acc;
    if (widget.item.templateId != null) {
      final t = await (s.db.select(s.db.templates)..where((x) => x.id.equals(widget.item.templateId!))).getSingleOrNull();
      acc = t?.defaultAccountId;
      if (t?.toAccountId != null) {
        final to = await (s.db.select(s.db.accounts)..where((x) => x.id.equals(t!.toAccountId!))).getSingleOrNull();
        if (to?.type == AccountType.reserve.code) {
          _reserve = true;
          acc = to!.linkedAccountId ?? acc;
        }
      }
    }
    acc ??= await s.settings.getInt(SettingKeys.salaryAccountId);
    final m = await s.engine.latest();
    if (mounted) {
      setState(() {
        _account = acc;
        // paying an older month's item: default to today; same month: today too
        if (m != null && Dates.yearMonth(_date) != m.yearMonth) _date = Dates.firstOfYearMonth(m.yearMonth);
      });
    }
  }

  Future<void> _pay() async {
    final s = ref.read(sessionProvider);
    final amt = Money.parse(_amount.text) ?? 0;
    if (s == null) return;
    if (amt <= 0) return toast(context, 'Enter the amount paid', error: true);
    if (_account == null) return toast(context, 'Pick the paying account', error: true);
    setState(() => _busy = true);
    try {
      // A reserve is whatever you decide to keep aside this month.
      if (_reserve && amt != widget.item.amount) {
        await s.ledger.setPlannedAmount(widget.item.id, amt);
        await s.engine.recomputePlannedSummary(widget.item.monthId);
      }
      await s.ledger.payPlanned(widget.item.id, amount: amt, accountId: _account!, date: _date);
      if (mounted) Navigator.pop(context);
    } on LedgerException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Changes only this month's planned amount; the recurring item keeps its usual amount.
  Future<void> _changeAmount() async {
    final s = ref.read(sessionProvider);
    final amt = Money.parse(_amount.text);
    if (s == null) return;
    if (amt == null || amt < 0) return toast(context, 'Enter an amount', error: true);
    try {
      await s.ledger.setPlannedAmount(widget.item.id, amt);
      await s.engine.recomputePlannedSummary(widget.item.monthId);
      if (mounted) {
        toast(context, '${_reserve ? 'Reserve' : 'Amount'} for this month set to ${Money.format(amt)}');
        Navigator.pop(context);
      }
    } on LedgerException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _status(PlannedStatus st) async {
    final s = ref.read(sessionProvider);
    if (s == null) return;
    await s.ledger.setPlannedStatus(widget.item.id, st);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    _defaults();
    final item = widget.item;
    final accounts = (ref.watch(accountsProvider).value ?? const <AccountRow>[])
        .where((a) => a.type != AccountType.savings.code && a.id != item.cardAccountId)
        .where((a) => !_reserve || a.id == _account)
        .toList();
    final card = item.cardAccountId != null;
    final status = PlannedStatus.of(item.status);
    final due = item.dueDate == null ? null : Dates.parseIso(item.dueDate!);
    final overdue = status == PlannedStatus.pending && due != null && due.isBefore(Dates.day(DateTime.now()));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(item.name, style: BText.h2)),
        StatusChip(overdue ? ChipStatus.overdue : switch (status) {
          PlannedStatus.paid => ChipStatus.paid,
          PlannedStatus.skipped => ChipStatus.skipped,
          PlannedStatus.pending => ChipStatus.pending,
        }),
      ]),
      const SizedBox(height: 4),
      Text(
        [
          if (due != null) 'Due ${Dates.short(due)}' else 'Anytime this month',
          'Planned ${Money.format(item.amount)}',
          if (card) 'Card bill — recorded as a transfer',
          if (_reserve) 'Reserve — stays in the bank, never spendable',
        ].join(' · '),
        style: BText.caption,
      ),
      const SizedBox(height: 20),
      if (status == PlannedStatus.pending) ...[
        BField.amount(label: _reserve ? 'Amount to set aside' : 'Amount paid', controller: _amount),
        const SizedBox(height: 14),
        Text(_reserve ? 'Kept in' : 'Paid from', style: BText.caption),
        const SizedBox(height: 8),
        ChoicePills<int>(items: accountItems(accounts), selected: _account, onChanged: (v) => setState(() => _account = v)),
        const SizedBox(height: 14),
        InkWell(
          onTap: () async {
            final d = await pickDay(context, initial: _date);
            if (d != null) setState(() => _date = d);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              const Icon(LucideIcons.calendar, size: 18, color: BColors.textMuted),
              const SizedBox(width: 10),
              Text('${_reserve ? 'Set aside' : 'Paid'} on ${Dates.short(_date)}', style: BText.body),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        PillButton(label: _reserve ? 'Set aside' : 'Mark paid', icon: LucideIcons.check, expand: true, busy: _busy, onPressed: _pay),
        const SizedBox(height: 10),
        PillButton(
          label: _reserve ? 'Change this month\'s reserve' : 'Change this month\'s amount',
          icon: LucideIcons.pencil,
          variant: PillVariant.soft,
          expand: true,
          onPressed: _changeAmount,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text('Uses the amount above for ${Dates.monthLabel(Dates.yearMonth(due ?? _date))} only. Next month starts from the usual amount again.',
              style: BText.caption),
        ),
        PillButton(label: 'Skip this month', variant: PillVariant.outline, expand: true, onPressed: () => _status(PlannedStatus.skipped)),
      ] else
        PillButton(
          label: status == PlannedStatus.paid ? (_reserve ? 'Undo set aside' : 'Undo payment') : 'Mark as pending again',
          variant: PillVariant.outline,
          danger: status == PlannedStatus.paid,
          expand: true,
          onPressed: () => _status(PlannedStatus.pending),
        ),
    ]);
  }
}
