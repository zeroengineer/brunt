import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/repositories/ledger.dart';
import '../../design/design.dart';
import '../common/pickers.dart';

/// Add / edit account (spec §4.9 #3).
Future<int?> showAccountForm(BuildContext context, {AccountRow? existing, AccountType? presetType, String? presetName}) =>
    showBruntSheet<int>(context, builder: (_) => AccountForm(existing: existing, presetType: presetType, presetName: presetName));

class AccountForm extends ConsumerStatefulWidget {
  const AccountForm({super.key, this.existing, this.presetType, this.presetName});
  final AccountRow? existing;
  final AccountType? presetType;
  final String? presetName;

  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  late AccountType _type;
  final _name = TextEditingController();
  final _balance = TextEditingController();
  final _limit = TextEditingController();
  String? _icon;
  Color? _color;
  int? _linked;
  late bool _spendable;
  int _statement = 5;
  int _due = 25;
  bool _busy = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e == null ? (widget.presetType ?? AccountType.cash) : AccountType.of(e.type);
    _name.text = e?.name ?? widget.presetName ?? '';
    _balance.text = rupeesText(e?.startingBalance ?? 0);
    _limit.text = rupeesText(e?.creditLimit ?? 0);
    _icon = e?.icon;
    _color = e?.color == null ? null : BColors.fromHex(e!.color);
    _linked = e?.linkedAccountId;
    _spendable = e?.includeInSpendable ?? _type.defaultSpendable;
    _statement = e?.statementDay ?? 5;
    _due = e?.dueDay ?? 25;
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(sessionProvider);
    if (s == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) return toast(context, 'Give the account a name', error: true);
    final start = Money.parse(_balance.text) ?? 0;
    final limit = Money.parse(_limit.text);
    if (_type == AccountType.upi && _linked == null) return toast(context, 'Choose the linked bank', error: true);
    setState(() => _busy = true);
    try {
      int id;
      if (_editing) {
        id = widget.existing!.id;
        await s.catalog.updateAccount(
          id,
          name: name,
          icon: _icon,
          color: _color == null ? null : BColors.hex(_color!),
          startingBalance: start,
          linkedAccountId: _linked,
          includeInSpendable: _spendable,
          creditLimit: limit,
          statementDay: _statement,
          dueDay: _due,
        );
      } else {
        id = await s.catalog.createAccount(
          name: name,
          type: _type,
          icon: _icon ?? BIcons.defaultForAccount(_type),
          color: _color == null ? null : BColors.hex(_color!),
          startingBalance: start,
          linkedAccountId: _linked,
          includeInSpendable: _spendable,
          creditLimit: limit,
          statementDay: _statement,
          dueDay: _due,
        );
        if (_type == AccountType.creditCard) await s.engine.ensureCardBills(Dates.day(DateTime.now()));
      }
      if (mounted) Navigator.pop(context, id);
    } on LedgerException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final banks = accounts.where((a) => a.type == AccountType.bank.code).toList();
    final color = _color ?? BColors.primaryLight;
    final balanceLabel = switch (_type) {
      AccountType.creditCard => 'Current outstanding due',
      AccountType.cash => 'Cash in hand right now',
      _ => _editing ? 'Starting balance' : 'Current balance',
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_editing ? 'Edit account' : 'Add account', style: BText.h2),
      const SizedBox(height: 16),
      if (!_editing) ...[
        const Text('Type', style: BText.caption),
        const SizedBox(height: 8),
        ChoicePills<AccountType>(
          wrap: true,
          items: [for (final t in AccountType.values) ChoiceItem(t, t.label, icon: BIcons.of(BIcons.defaultForAccount(t)))],
          selected: _type,
          onChanged: (t) => setState(() {
            _type = t;
            _spendable = t.defaultSpendable;
          }),
        ),
        const SizedBox(height: 16),
      ],
      BField(
        label: 'Name',
        controller: _name,
        hint: switch (_type) {
          AccountType.cash => 'Cash in hand',
          AccountType.bank => 'HDFC Savings',
          AccountType.upi => 'GPay',
          AccountType.wallet => 'Paytm wallet',
          AccountType.creditCard => 'ICICI Amazon Pay card',
          AccountType.savings => 'RD / Emergency fund',
        },
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 14),
      if (_type == AccountType.upi) ...[
        const Text('Linked bank account', style: BText.caption),
        const SizedBox(height: 8),
        if (banks.isEmpty)
          const Text('Add a bank account first — UPI payments come out of it.', style: BText.bodyMuted)
        else
          ChoicePills<int>(items: accountItems(banks, showBalance: false), selected: _linked, onChanged: (v) => setState(() => _linked = v)),
        const SizedBox(height: 14),
      ] else ...[
        BField.amount(label: balanceLabel, controller: _balance),
        const SizedBox(height: 14),
      ],
      if (_type == AccountType.creditCard) ...[
        BField.amount(label: 'Credit limit', controller: _limit),
        const SizedBox(height: 8),
        DayStepper(label: 'Statement day', value: _statement, onChanged: (v) => setState(() => _statement = v), format: Dates.ordinal),
        DayStepper(label: 'Payment due day', value: _due, onChanged: (v) => setState(() => _due = v), format: Dates.ordinal),
        const SizedBox(height: 8),
      ],
      if (_type != AccountType.upi && _type != AccountType.creditCard)
        SwitchRow(
          label: 'Include in spendable balance',
          sub: _type == AccountType.savings ? 'Savings are protected by default' : 'Counts as money available to spend',
          value: _spendable,
          onChanged: (v) => setState(() => _spendable = v),
        ),
      const SizedBox(height: 14),
      const Text('Icon', style: BText.caption),
      const SizedBox(height: 8),
      IconPicker(selected: _icon ?? BIcons.defaultForAccount(_type), onChanged: (v) => setState(() => _icon = v), color: color),
      const SizedBox(height: 14),
      const Text('Colour', style: BText.caption),
      const SizedBox(height: 8),
      ColorPicker(selected: _color, onChanged: (c) => setState(() => _color = c)),
      const SizedBox(height: 24),
      PillButton(label: _editing ? 'Save changes' : 'Add account', expand: true, busy: _busy, onPressed: _save),
    ]);
  }
}
