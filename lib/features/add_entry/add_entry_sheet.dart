import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/repositories/ledger.dart';
import '../../design/design.dart';
import '../common/pickers.dart';

/// Floating + sheet (spec §4.6): Expense | Income | Transfer. Pass [existing] to edit.
Future<void> showAddEntrySheet(BuildContext context, {TxRow? existing, int? presetAccount, int? presetTo, TxType? presetType}) =>
    showBruntSheet<void>(context, builder: (_) => AddEntrySheet(existing: existing, presetAccount: presetAccount, presetTo: presetTo, presetType: presetType));

enum _Mode { expense, income, transfer }

/// Transfer shortcuts. [borrowed] and [lent] record money owed with a date.
enum _Preset {
  atm('ATM withdrawal'),
  cardBill('Card bill'),
  savings('Savings deposit'),
  borrowed('Borrowed'),
  lent('Lent');

  const _Preset(this.label);
  final String label;
  bool get isDebt => this == borrowed || this == lent;
}

class AddEntrySheet extends ConsumerStatefulWidget {
  const AddEntrySheet({super.key, this.existing, this.presetAccount, this.presetTo, this.presetType});
  final TxRow? existing;
  final int? presetAccount;
  final int? presetTo;
  final TxType? presetType;

  @override
  ConsumerState<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<AddEntrySheet> {
  _Mode _mode = _Mode.expense;
  String _amount = '';
  int? _category;
  int? _account;
  int? _to;
  DateTime _date = Dates.day(DateTime.now());
  final _note = TextEditingController();
  _Preset? _preset;
  final _person = TextEditingController();
  DateTime _dueBack = Dates.day(DateTime.now()).add(const Duration(days: 30));
  bool _busy = false;
  bool _accountTouched = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      final t = TxType.of(e.type);
      _mode = switch (t) {
        TxType.transfer => _Mode.transfer,
        TxType.salary || TxType.extraIncome => _Mode.income,
        _ => _Mode.expense,
      };
      _amount = rupeesText(e.amount);
      _category = e.categoryId;
      _account = e.viaUpiId ?? e.accountId;
      _to = e.toAccountId;
      _date = Dates.parseIso(e.date);
      _note.text = e.note ?? '';
      _accountTouched = true;
    } else {
      _account = widget.presetAccount;
      _to = widget.presetTo;
      _accountTouched = widget.presetAccount != null;
      if (widget.presetType == TxType.transfer) _mode = _Mode.transfer;
      if (widget.presetType == TxType.extraIncome) _mode = _Mode.income;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    _person.dispose();
    super.dispose();
  }

  /// Applies a transfer shortcut: picks sensible From/To accounts and a note.
  void _applyPreset(_Preset p, List<AccountRow> accounts) {
    int? first(bool Function(AccountRow) f) => accounts.where(f).firstOrNull?.id;
    final bank = first((a) => a.type == AccountType.bank.code) ?? first((a) => a.type == AccountType.wallet.code) ?? first((a) => a.type == AccountType.cash.code);
    setState(() {
      _preset = _preset == p ? null : p;
      if (_preset == null) return;
      switch (p) {
        case _Preset.atm:
          _account = bank;
          _to = first((a) => a.type == AccountType.cash.code);
          _note.text = 'ATM withdrawal';
        case _Preset.cardBill:
          _account = bank;
          _to = first((a) => a.type == AccountType.creditCard.code);
          _note.text = 'Card bill';
        case _Preset.savings:
          _account = bank;
          _to = first((a) => a.type == AccountType.savings.code);
          _note.text = 'Savings deposit';
        case _Preset.borrowed:
          _account = null;
          _to = bank;
          _note.text = '';
        case _Preset.lent:
          _account = bank;
          _to = null;
          _note.text = '';
      }
    });
  }

  /// Borrowed: money in from a person, with a scheduled pay-back.
  /// Lent: money out to a person, parked in 'Lent out' until it comes back.
  Future<void> _saveDebt(int amt) async {
    final s = ref.read(sessionProvider)!;
    final who = _person.text.trim();
    if (who.isEmpty) return toast(context, _preset == _Preset.borrowed ? 'Who lent it to you?' : 'Who did you lend to?', error: true);
    final mine = _preset == _Preset.borrowed ? _to : _account;
    if (mine == null) return toast(context, _preset == _Preset.borrowed ? 'Pick the account it came into' : 'Pick the account it left from', error: true);
    setState(() => _busy = true);
    try {
      if (_preset == _Preset.borrowed) {
        final loan = await s.catalog.ensureSystemAccount(AccountType.loan);
        await s.ledger.add(Entry(
          type: TxType.transfer,
          amount: amt,
          date: _date,
          accountId: loan,
          toAccountId: mine,
          note: 'Borrowed from $who',
        ));
        // Pay-back lands in Plan (Priority) in the month it is due; paying it is a
        // transfer back into 'Borrowed', which clears what you owe.
        final cats = ref.read(categoriesProvider).value ?? const <CategoryRow>[];
        final debt = cats.where((c) => c.tier == Tier.priority.value && c.name == 'Debt').firstOrNull ??
            cats.where((c) => c.tier == Tier.priority.value).firstOrNull;
        if (debt != null) {
          final ym = Dates.yearMonth(_dueBack);
          await s.catalog.createTemplate(TemplatesCompanion.insert(
            categoryId: debt.id,
            name: 'Pay back $who',
            defaultAmount: amt,
            defaultAccountId: Value(mine),
            toAccountId: Value(loan),
            frequency: const Value('one_time'),
            dueDay: Value(_dueBack.day),
            startMonth: Value(ym),
            endMonth: Value(ym),
          ));
        }
      } else {
        final lent = await s.catalog.ensureSystemAccount(AccountType.lent);
        await s.ledger.add(Entry(
          type: TxType.transfer,
          amount: amt,
          date: _date,
          accountId: mine,
          toAccountId: lent,
          note: 'Lent to $who · back by ${Dates.short(_dueBack)}',
        ));
      }
      if (mounted) {
        Navigator.pop(context);
        toast(context, _preset == _Preset.borrowed ? 'Borrowed — pay-back added to Plan for ${Dates.short(_dueBack)}' : 'Lent — shown under Lent out');
      }
    } on LedgerException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickCategory(int id) async {
    setState(() => _category = id);
    if (_accountTouched || _editing) return;
    // remember the last account used per category (groceries → GPay)
    final s = ref.read(sessionProvider);
    final last = await s?.settings.getInt('${SettingKeys.lastAccountForCategory}$id');
    if (last != null && mounted) setState(() => _account = last);
  }

  Future<void> _save() async {
    final s = ref.read(sessionProvider);
    if (s == null) return;
    final amt = Money.parse(_amount) ?? 0;
    if (amt <= 0) return toast(context, 'Enter an amount', error: true);
    if (_mode == _Mode.transfer && (_preset?.isDebt ?? false) && !_editing) return _saveDebt(amt);
    if (_account == null) return toast(context, _mode == _Mode.transfer ? 'Pick where it comes from' : 'Pick an account', error: true);
    if (_mode == _Mode.transfer && _to == null) return toast(context, 'Pick where it goes', error: true);
    if (_mode == _Mode.expense && _category == null) return toast(context, 'Pick a category', error: true);
    final existingType = widget.existing == null ? null : TxType.of(widget.existing!.type);
    final type = switch (_mode) {
      _Mode.expense => TxType.expense,
      _Mode.transfer => TxType.transfer,
      _Mode.income => existingType == TxType.salary ? TxType.salary : TxType.extraIncome,
    };
    int? cat = _category;
    if (_mode == _Mode.income && cat == null) {
      final cats = ref.read(categoriesProvider).value ?? const <CategoryRow>[];
      cat = cats.where((c) => c.tier == Tier.income.value && c.name == 'Extra income').firstOrNull?.id ??
          cats.where((c) => c.tier == Tier.income.value).firstOrNull?.id;
    }
    final entry = Entry(
      type: type,
      amount: amt,
      date: _date,
      accountId: _account!,
      toAccountId: _mode == _Mode.transfer ? _to : null,
      categoryId: _mode == _Mode.transfer ? null : cat,
      templateId: widget.existing?.templateId,
      plannedId: widget.existing?.plannedId,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    setState(() => _busy = true);
    try {
      if (_editing) {
        await s.ledger.update(widget.existing!.id, entry);
      } else {
        await s.ledger.add(entry);
      }
      if (_mode == _Mode.expense && _category != null) {
        await s.settings.setInt('${SettingKeys.lastAccountForCategory}$_category', _account!);
      }
      if (mounted) {
        Navigator.pop(context);
        toast(context, _editing ? 'Updated' : 'Saved');
      }
    } on LedgerException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, title: 'Delete entry?', message: 'Balances will be recalculated.', confirm: 'Delete', danger: true);
    if (!ok) return;
    await ref.read(sessionProvider)?.ledger.delete(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cats = (ref.watch(categoriesProvider).value ?? const <CategoryRow>[]).where((c) => !c.archived).toList();
    final accounts = ref.watch(accountsProvider).value ?? const <AccountRow>[];
    final month = ref.watch(monthProvider).value;
    final today = Dates.day(DateTime.now());
    final shownCats = _mode == _Mode.income
        ? cats.where((c) => c.tier == Tier.income.value).toList()
        : (cats.where((c) => c.tier != Tier.income.value).toList()
          // everyday spending first: daily, variable, then bills
          ..sort((a, b) {
            const order = {4: 0, 5: 1, 3: 2, 1: 3, 2: 4};
            final t = (order[a.tier] ?? 9).compareTo(order[b.tier] ?? 9);
            return t != 0 ? t : a.sortOrder.compareTo(b.sortOrder);
          }));
    final payFrom = _mode == _Mode.income
        ? accounts.where((a) => a.type != AccountType.creditCard.code).toList()
        : accounts.where((a) => a.type != AccountType.savings.code || _mode == _Mode.transfer).toList();
    final amountColor = _mode == _Mode.income ? BColors.success : BColors.text;
    final lockedType = _editing && TxType.of(widget.existing!.type) == TxType.salary;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!lockedType)
        SegmentTabs(
          items: const [SegmentItem('Expense'), SegmentItem('Income'), SegmentItem('Transfer')],
          selected: _mode.index,
          onChanged: (i) => setState(() {
            _mode = _Mode.values[i];
            _category = null;
          }),
        )
      else
        const Text('Salary', style: BText.h2),
      const SizedBox(height: 18),
      Center(
        child: Semantics(
          label: 'Amount',
          value: _amount.isEmpty ? 'zero' : _amount,
          child: Text(
            _amount.isEmpty ? '₹0' : '₹${_amount.contains('.') ? _amount : Money.groupIndian(int.parse(_amount))}',
            style: BText.display.copyWith(color: _amount.isEmpty ? BColors.disabled : amountColor, fontSize: 40),
          ),
        ),
      ),
      const SizedBox(height: 14),
      if (_mode == _Mode.transfer) ...[
        if (!_editing) ...[
          ChoicePills<_Preset>(
            items: [
              for (final p in _Preset.values)
                if (p != _Preset.cardBill || accounts.any((a) => a.type == AccountType.creditCard.code))
                  if (p != _Preset.savings || accounts.any((a) => a.type == AccountType.savings.code))
                    ChoiceItem(p, p.label, icon: switch (p) {
                      _Preset.atm => LucideIcons.banknote,
                      _Preset.cardBill => LucideIcons.creditCard,
                      _Preset.savings => LucideIcons.piggyBank,
                      _Preset.borrowed => LucideIcons.handCoins,
                      _Preset.lent => LucideIcons.handCoins,
                    }),
            ],
            selected: _preset,
            onChanged: (p) => _applyPreset(p, accounts),
          ),
          const SizedBox(height: 12),
        ],
        if (_preset?.isDebt ?? false) ...[
          BField(
            label: _preset == _Preset.borrowed ? 'Borrowed from' : 'Lent to',
            controller: _person,
            hint: 'Name',
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          Text(_preset == _Preset.borrowed ? 'Into' : 'From', style: BText.caption),
          const SizedBox(height: 8),
          ChoicePills<int>(
            items: accountItems(accounts.where((a) => !AccountType.of(a.type).isSystem && !AccountType.of(a.type).isLiability)),
            selected: _preset == _Preset.borrowed ? _to : _account,
            onChanged: (v) => setState(() => _preset == _Preset.borrowed ? _to = v : _account = v),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              final d = await pickDay(context, initial: _dueBack, first: today, last: DateTime(today.year + 3));
              if (d != null) setState(() => _dueBack = d);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                const Icon(LucideIcons.calendarClock, size: 18, color: BColors.primaryLight),
                const SizedBox(width: 10),
                Text('${_preset == _Preset.borrowed ? 'Pay back by' : 'Due back by'} ${Dates.short(_dueBack)} ${_dueBack.year}', style: BText.body),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: BColors.textMuted),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              _preset == _Preset.borrowed
                  ? 'Adds "Pay back" to your Plan as a priority item on that date.'
                  : 'Parked under "Lent out" until you record it coming back.',
              style: BText.caption,
            ),
          ),
        ] else ...[
          const Text('From', style: BText.caption),
          const SizedBox(height: 8),
          ChoicePills<int>(items: accountItems(payFrom), selected: _account, onChanged: (v) => setState(() => _account = v)),
          const SizedBox(height: 12),
          const Text('To', style: BText.caption),
          const SizedBox(height: 8),
          ChoicePills<int>(
            items: accountItems(accounts.where((a) => a.id != _account)),
            selected: _to,
            onChanged: (v) => setState(() => _to = v),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 2),
            child: Text('Moves money between your accounts — not counted as spending.', style: BText.caption),
          ),
        ],
      ] else ...[
        if (!lockedType) ...[
          const Text('Category', style: BText.caption),
          const SizedBox(height: 8),
          ChoicePills<int>(
            items: [for (final c in shownCats) ChoiceItem(c.id, c.name, icon: categoryIcon(c), color: categoryColor(c))],
            selected: _category,
            onChanged: _pickCategory,
          ),
          const SizedBox(height: 12),
        ],
        Text(_mode == _Mode.income ? 'Into' : 'Paid from', style: BText.caption),
        const SizedBox(height: 8),
        ChoicePills<int>(
          items: accountItems(payFrom),
          selected: _account,
          onChanged: (v) => setState(() {
            _account = v;
            _accountTouched = true;
          }),
        ),
      ],
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _note,
            style: BText.body,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Note (optional)',
              hintStyle: BText.bodyMuted,
              prefixIcon: const Icon(LucideIcons.stickyNote, size: 16, color: BColors.textMuted),
              filled: true,
              fillColor: BColors.surfaceRaised,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(BRadius.pill), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PillButton(
          label: DateUtils.isSameDay(_date, today) ? 'Today' : Dates.short(_date),
          icon: LucideIcons.calendar,
          dense: true,
          variant: PillVariant.soft,
          onPressed: () async {
            final first = month == null ? null : Dates.firstOfYearMonth(month.yearMonth);
            final d = await pickDay(context, initial: _date, first: first == null ? null : DateTime(first.year, first.month - 24));
            if (d != null) setState(() => _date = d);
          },
        ),
      ]),
      const SizedBox(height: 14),
      AmountKeypad(value: _amount, onChanged: (v) => setState(() => _amount = v)),
      const SizedBox(height: 14),
      Row(children: [
        if (_editing) ...[
          PillButton(label: 'Delete', variant: PillVariant.outline, danger: true, onPressed: _delete),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: PillButton(
            label: _editing ? 'Save changes' : 'Save ${_mode.name}',
            expand: true,
            busy: _busy,
            onPressed: _save,
          ),
        ),
      ]),
    ]);
  }
}
