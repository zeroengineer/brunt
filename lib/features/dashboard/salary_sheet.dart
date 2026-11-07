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

/// "Salary received" (spec §4.3): amount (pre-filled), date (today), account (salary account).
Future<void> showSalarySheet(BuildContext context, MonthRow month, int? defaultAccount) =>
    showBruntSheet<void>(context, builder: (_) => _SalarySheet(month: month, defaultAccount: defaultAccount));

class _SalarySheet extends ConsumerStatefulWidget {
  const _SalarySheet({required this.month, this.defaultAccount});
  final MonthRow month;
  final int? defaultAccount;

  @override
  ConsumerState<_SalarySheet> createState() => _SalarySheetState();
}

class _SalarySheetState extends ConsumerState<_SalarySheet> {
  late final TextEditingController _amount;
  late int? _account;
  late DateTime _date;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: rupeesText(widget.month.salaryExpected));
    _account = widget.defaultAccount;
    final today = Dates.day(DateTime.now());
    final first = Dates.firstOfYearMonth(widget.month.yearMonth);
    _date = Dates.yearMonth(today) == widget.month.yearMonth ? today : first;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final s = ref.read(sessionProvider);
    final amt = Money.parse(_amount.text) ?? 0;
    if (s == null) return;
    if (amt <= 0) return toast(context, 'Enter the amount received', error: true);
    if (_account == null) return toast(context, 'Pick the account it landed in', error: true);
    setState(() => _busy = true);
    try {
      await s.ledger.receiveSalary(amount: amt, date: _date, accountId: _account!);
      if (mounted) {
        Navigator.pop(context);
        toast(context, 'Salary received — projection updated');
      }
    } on LedgerException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = (ref.watch(accountsProvider).value ?? const <AccountRow>[])
        .where((a) => !AccountType.of(a.type).isLiability && a.type != AccountType.upi.code && a.type != AccountType.lent.code)
        .toList();
    final first = Dates.firstOfYearMonth(widget.month.yearMonth);
    final last = Dates.lastOfMonth(first);
    final today = Dates.day(DateTime.now());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Salary received', style: BText.h2),
      const SizedBox(height: 4),
      Text(Dates.monthLabel(widget.month.yearMonth), style: BText.caption),
      const SizedBox(height: 20),
      BField.amount(label: 'Amount', controller: _amount),
      const SizedBox(height: 14),
      const Text('Landed in', style: BText.caption),
      const SizedBox(height: 8),
      ChoicePills<int>(items: accountItems(accounts), selected: _account, onChanged: (v) => setState(() => _account = v)),
      const SizedBox(height: 14),
      InkWell(
        onTap: () async {
          final d = await pickDay(context, initial: _date, first: first, last: last.isAfter(today) ? today : last);
          if (d != null) setState(() => _date = d);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            const Icon(LucideIcons.calendar, size: 18, color: BColors.textMuted),
            const SizedBox(width: 10),
            Text('Received on ${Dates.short(_date)}', style: BText.body),
          ]),
        ),
      ),
      const SizedBox(height: 20),
      PillButton(label: 'Confirm', icon: LucideIcons.check, expand: true, busy: _busy, onPressed: _confirm),
    ]);
  }
}
