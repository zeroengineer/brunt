import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../design/design.dart';

Color accountColor(AccountRow a) => BColors.fromHex(a.color, fallback: switch (AccountType.of(a.type)) {
      AccountType.cash => BColors.success,
      AccountType.bank => BColors.primaryLight,
      AccountType.upi => BColors.primarySoft,
      AccountType.wallet => BColors.warning,
      AccountType.creditCard => BColors.danger,
      AccountType.savings => BColors.tierSavings,
      AccountType.loan => BColors.warning,
      AccountType.lent => BColors.primarySoft,
      AccountType.reserve => BColors.tierSavings,
    });

IconData accountIcon(AccountRow a) => BIcons.of(a.icon ?? BIcons.defaultForAccount(AccountType.of(a.type)));

Color categoryColor(CategoryRow c) => BColors.fromHex(c.color, fallback: BColors.tier(Tier.of(c.tier)) == BColors.tierVariable
    ? BColors.textMuted
    : BColors.tier(Tier.of(c.tier)));

IconData categoryIcon(CategoryRow c) => BIcons.of(c.icon, fallback: BIcons.tier(Tier.of(c.tier)));

/// Account pills for every entry sheet. Cards show available limit; others the balance.
List<ChoiceItem<int>> accountItems(Iterable<AccountRow> accounts, {bool showBalance = true}) => [
      for (final a in accounts.where((a) => a.type != AccountType.reserve.code))
        ChoiceItem(
          a.id,
          a.name,
          icon: accountIcon(a),
          color: accountColor(a),
          sub: !showBalance || a.type == AccountType.upi.code
              ? null
              : (AccountType.of(a.type).isLiability ? 'due ${Money.compact(a.balance)}' : Money.compact(a.balance)),
        ),
    ];

String accountSubtitle(AccountRow a, List<AccountRow> all) {
  final t = AccountType.of(a.type);
  if (t == AccountType.upi) {
    final bank = all.where((x) => x.id == a.linkedAccountId).firstOrNull;
    return 'UPI · via ${bank?.name ?? '—'}';
  }
  if (t == AccountType.loan) return 'Borrowed · still to pay back';
  if (t == AccountType.lent) return 'Lent out · owed to you';
  if (t == AccountType.reserve) {
    final bank = all.where((x) => x.id == a.linkedAccountId).firstOrNull;
    return 'Reserve · kept in ${bank?.name ?? '—'}';
  }
  if (t == AccountType.creditCard) {
    final limit = a.creditLimit;
    return limit == null ? 'Credit card' : 'Available ${Money.format(limit - a.balance)} of ${Money.compact(limit)}';
  }
  return '${t.label}${a.includeInSpendable ? '' : ' · protected'}';
}

Future<DateTime?> pickDay(BuildContext context, {required DateTime initial, DateTime? first, DateTime? last}) {
  final today = Dates.day(DateTime.now());
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first ?? DateTime(today.year - 3),
    lastDate: last ?? today,
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.dark(
            primary: BColors.primary, onPrimary: BColors.text, surface: BColors.surface, onSurface: BColors.text),
      ),
      child: child!,
    ),
  );
}

/// Picks a year-month ('2027-03') from the next/previous few years. Returns '' for "none".
Future<String?> pickYearMonth(BuildContext context, {String? current, bool allowNone = true}) {
  final now = DateTime.now();
  final options = [for (var i = -12; i <= 60; i++) Dates.yearMonth(DateTime(now.year, now.month + i))];
  return showBruntSheet<String>(
    context,
    scrollable: false,
    builder: (ctx) => SizedBox(
      height: 420,
      child: ListView(children: [
        if (allowNone)
          ListTile(title: const Text('No limit'), onTap: () => Navigator.pop(ctx, ''), trailing: current == null ? const Icon(Icons.check) : null),
        for (final ym in options)
          ListTile(
            title: Text(Dates.monthLabel(ym), style: BText.body),
            trailing: ym == current ? const Icon(Icons.check, color: BColors.primaryLight) : null,
            onTap: () => Navigator.pop(ctx, ym),
          ),
      ]),
    ),
  );
}

/// Two-row horizontally scrolling strip of icons for accounts/categories.
class IconPicker extends StatelessWidget {
  const IconPicker({super.key, required this.selected, required this.onChanged, required this.color});
  final String? selected;
  final ValueChanged<String> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final keys = BIcons.byKey.keys.toList();
    // keep the selected icon in view
    final i = keys.indexOf(selected ?? '');
    return SizedBox(
      height: 42 * 2 + 8,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        controller: ScrollController(initialScrollOffset: i < 4 ? 0 : (i ~/ 2 - 1) * 50.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1),
        itemCount: keys.length,
        itemBuilder: (_, n) {
          final key = keys[n];
          final sel = key == selected;
          return Semantics(
            label: key,
            selected: sel,
            button: true,
            child: GestureDetector(
              onTap: () => onChanged(key),
              child: Container(
                decoration: BoxDecoration(
                  color: sel ? color.withValues(alpha: 0.25) : BColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? color : BColors.border),
                ),
                child: Icon(BIcons.byKey[key], size: 20, color: sel ? color : BColors.textMuted),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ColorPicker extends StatelessWidget {
  const ColorPicker({super.key, required this.selected, required this.onChanged});
  final Color? selected;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (final c in BColors.palette)
        Semantics(
          label: 'Colour ${BColors.hex(c)}',
          selected: c == selected,
          button: true,
          child: GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: c == selected ? BColors.text : Colors.transparent, width: 2.5),
              ),
            ),
          ),
        ),
    ]);
  }
}

String rupeesText(int paise) {
  if (paise == 0) return '';
  final r = paise ~/ 100;
  final p = paise % 100;
  return p == 0 ? '$r' : '$r.${p.toString().padLeft(2, '0')}';
}

/// Reserve held inside each bank: bank id → total kept aside (system reserve accounts).
Map<int, int> reservesByBank(Iterable<AccountRow> all) {
  final out = <int, int>{};
  for (final a in all) {
    if (a.type != AccountType.reserve.code || a.archived || a.linkedAccountId == null) continue;
    out[a.linkedAccountId!] = (out[a.linkedAccountId!] ?? 0) + a.balance;
  }
  return out;
}
