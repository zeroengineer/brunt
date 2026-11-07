import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../design/design.dart';
import '../common/pickers.dart';

/// Which tiers the form offers (onboarding splits monthly vs daily).
enum TemplateScope { committed, daily, any }

Future<int?> showTemplateForm(
  BuildContext context, {
  TemplateRow? existing,
  TemplateScope scope = TemplateScope.any,
  String? presetName,
  String? presetCategory,
  int? presetAmount,
}) =>
    showBruntSheet<int>(
      context,
      builder: (_) => TemplateForm(
        existing: existing,
        scope: scope,
        presetName: presetName,
        presetCategory: presetCategory,
        presetAmount: presetAmount,
      ),
    );

/// Fully customisable schedule (spec §3).
class TemplateForm extends ConsumerStatefulWidget {
  const TemplateForm({super.key, this.existing, this.scope = TemplateScope.any, this.presetName, this.presetCategory, this.presetAmount});
  final TemplateRow? existing;
  final TemplateScope scope;
  final String? presetName;
  final String? presetCategory;
  final int? presetAmount;

  @override
  ConsumerState<TemplateForm> createState() => _TemplateFormState();
}

class _TemplateFormState extends ConsumerState<TemplateForm> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  int? _category;
  int? _account;
  int? _toAccount;
  late Frequency _freq;
  int _days = WeekMask.all;
  int? _dueDay;
  bool _variable = false;
  bool _active = true;
  String? _start;
  String? _end;
  bool _busy = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name.text = e?.name ?? widget.presetName ?? '';
    _amount.text = rupeesText(e?.defaultAmount ?? widget.presetAmount ?? 0);
    _category = e?.categoryId;
    _account = e?.defaultAccountId;
    _toAccount = e?.toAccountId;
    _freq = e == null ? (widget.scope == TemplateScope.daily ? Frequency.daily : Frequency.monthly) : Frequency.of(e.frequency);
    _days = e?.daysOfWeek ?? WeekMask.all;
    _dueDay = e?.dueDay ?? (e == null && widget.scope == TemplateScope.committed ? 5 : null);
    _variable = e?.variableAmount ?? widget.scope == TemplateScope.daily;
    _active = e?.active ?? true;
    _start = e?.startMonth;
    _end = e?.endMonth;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  List<Tier> get _tiers => switch (widget.scope) {
        TemplateScope.committed => [Tier.priority, Tier.savings, Tier.fixed],
        TemplateScope.daily => [Tier.daily, Tier.variable],
        TemplateScope.any => [Tier.priority, Tier.savings, Tier.fixed, Tier.daily, Tier.variable],
      };

  Future<void> _save(List<CategoryRow> cats) async {
    final s = ref.read(sessionProvider);
    if (s == null) return;
    final name = _name.text.trim();
    final amount = Money.parse(_amount.text) ?? 0;
    if (name.isEmpty) return toast(context, 'Give it a name', error: true);
    if (_category == null) return toast(context, 'Pick a category', error: true);
    if (amount <= 0) return toast(context, 'Enter the usual amount', error: true);
    if (_freq == Frequency.daily && _days == 0) return toast(context, 'Pick at least one day', error: true);
    final start = _freq == Frequency.oneTime ? (_start ?? Dates.yearMonth(DateTime.now())) : _start;
    if (start != null && _end != null && _end!.compareTo(start) < 0) {
      return toast(context, 'End month is before the start month', error: true);
    }
    setState(() => _busy = true);
    final c = TemplatesCompanion(
      categoryId: Value(_category!),
      name: Value(name),
      defaultAmount: Value(amount),
      defaultAccountId: Value(_account),
      toAccountId: Value(_toAccount),
      frequency: Value(_freq.code),
      daysOfWeek: Value(_days),
      dueDay: Value(_freq == Frequency.daily ? null : _dueDay),
      variableAmount: Value(_variable),
      startMonth: Value(start),
      endMonth: Value(_freq == Frequency.oneTime ? start : _end),
      active: Value(_active),
    );
    try {
      final id = _editing ? widget.existing!.id : await s.catalog.createTemplate(c);
      if (_editing) await s.catalog.updateTemplate(id, c);
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = (ref.watch(categoriesProvider).value ?? const <CategoryRow>[])
        .where((c) => !c.archived && _tiers.contains(Tier.of(c.tier)))
        .toList();
    if (_category == null && widget.presetCategory != null) {
      _category = cats.where((c) => c.name == widget.presetCategory).firstOrNull?.id;
    }
    final accounts = ref.watch(accountsProvider).value ?? const <AccountRow>[];
    final selectedTier = Tier.of(cats.where((c) => c.id == _category).firstOrNull?.tier ?? Tier.fixed.value);
    final savingsAccounts = accounts.where((a) => a.type == AccountType.savings.code).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_editing ? 'Edit item' : 'New recurring item', style: BText.h2),
      const SizedBox(height: 16),
      BField(label: 'Name', controller: _name, hint: 'Bus fare, Rent, Netflix…', textInputAction: TextInputAction.next),
      const SizedBox(height: 14),
      BField.amount(label: 'Usual amount', controller: _amount),
      const SizedBox(height: 16),
      const Text('Category', style: BText.caption),
      const SizedBox(height: 8),
      for (final tier in _tiers)
        if (cats.any((c) => c.tier == tier.value)) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4, bottom: 6),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: BColors.tier(tier), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(tier.label, style: BText.caption.copyWith(fontSize: 11)),
            ]),
          ),
          ChoicePills<int>(
            wrap: true,
            items: [for (final c in cats.where((c) => c.tier == tier.value)) ChoiceItem(c.id, c.name, icon: categoryIcon(c))],
            selected: _category,
            onChanged: (v) => setState(() {
              _category = v;
              final t = Tier.of(cats.firstWhere((c) => c.id == v).tier);
              if (!_editing) {
                if (t == Tier.daily && _freq != Frequency.daily) _freq = Frequency.daily;
                if (t != Tier.daily && _freq == Frequency.daily) _freq = Frequency.monthly;
              }
            }),
          ),
          const SizedBox(height: 6),
        ],
      const SizedBox(height: 12),
      const Text('How often', style: BText.caption),
      const SizedBox(height: 8),
      SegmentTabs(
        items: [for (final f in Frequency.values) SegmentItem(f.label)],
        selected: Frequency.values.indexOf(_freq),
        onChanged: (i) => setState(() => _freq = Frequency.values[i]),
      ),
      const SizedBox(height: 14),
      if (_freq == Frequency.daily) ...[
        const Text('On these days', style: BText.caption),
        const SizedBox(height: 8),
        WeekdayPicker(mask: _days, onChanged: (m) => setState(() => _days = m)),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(WeekMask.describe(_days), style: BText.caption),
        ),
        const SizedBox(height: 8),
        SwitchRow(
          label: 'Amount varies',
          sub: 'Learn the real average from your logs',
          value: _variable,
          onChanged: (v) => setState(() => _variable = v),
        ),
      ] else ...[
        SwitchRow(
          label: 'Fixed due day',
          sub: _dueDay == null ? 'Anytime this month' : 'Due on the ${Dates.ordinal(_dueDay!)}',
          value: _dueDay != null,
          onChanged: (v) => setState(() => _dueDay = v ? 5 : null),
        ),
        if (_dueDay != null)
          DayStepper(label: 'Due day', value: _dueDay!, onChanged: (v) => setState(() => _dueDay = v), format: Dates.ordinal),
      ],
      const SizedBox(height: 14),
      Text(selectedTier == Tier.savings ? 'Pay from' : 'Usually paid from', style: BText.caption),
      const SizedBox(height: 8),
      if (accounts.isEmpty)
        const Text('Add an account first', style: BText.bodyMuted)
      else
        ChoicePills<int>(
            items: accountItems(accounts.where((a) => a.type != AccountType.savings.code), showBalance: false),
            selected: _account,
            onChanged: (v) => setState(() => _account = v)),
      if (selectedTier == Tier.savings && savingsAccounts.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Text('Moves money into (recorded as a transfer)', style: BText.caption),
        const SizedBox(height: 8),
        ChoicePills<int>(
          items: [const ChoiceItem(-1, 'None'), ...accountItems(savingsAccounts, showBalance: false)],
          selected: _toAccount ?? -1,
          onChanged: (v) => setState(() => _toAccount = v == -1 ? null : v),
        ),
      ],
      const SizedBox(height: 14),
      if (_freq == Frequency.oneTime)
        _MonthRow(
          label: 'In month',
          value: _start ?? Dates.yearMonth(DateTime.now()),
          onTap: () async {
            final v = await pickYearMonth(context, current: _start, allowNone: false);
            if (v != null && v.isNotEmpty) setState(() => _start = v);
          },
        )
      else ...[
        _MonthRow(
          label: 'Starts',
          value: _start,
          onTap: () async {
            final v = await pickYearMonth(context, current: _start);
            if (v != null) setState(() => _start = v.isEmpty ? null : v);
          },
        ),
        _MonthRow(
          label: 'Ends',
          value: _end,
          hint: 'e.g. an EMI that ends in March 2027',
          onTap: () async {
            final v = await pickYearMonth(context, current: _end);
            if (v != null) setState(() => _end = v.isEmpty ? null : v);
          },
        ),
      ],
      if (_editing)
        SwitchRow(label: 'Active', sub: 'Pause without deleting', value: _active, onChanged: (v) => setState(() => _active = v)),
      const SizedBox(height: 22),
      PillButton(label: _editing ? 'Save changes' : 'Add item', expand: true, busy: _busy, onPressed: () => _save(cats)),
    ]);
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.label, required this.value, required this.onTap, this.hint});
  final String label;
  final String? value;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: BText.body),
              if (hint != null && value == null) Text(hint!, style: BText.caption),
            ]),
          ),
          Text(value == null ? 'No limit' : Dates.monthLabel(value!), style: BText.label.copyWith(color: BColors.primaryLight)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: BColors.textMuted),
        ]),
      ),
    );
  }
}
