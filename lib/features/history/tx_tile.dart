import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../design/design.dart';
import '../add_entry/add_entry_sheet.dart';
import '../common/pickers.dart';

/// One transaction row. [perspective] = account whose point of view signs the amount.
class TxTile extends StatelessWidget {
  const TxTile({super.key, required this.tx, required this.accounts, required this.categories, this.perspective, this.showDate = true});

  final TxRow tx;
  final List<AccountRow> accounts;
  final List<CategoryRow> categories;
  final int? perspective;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final type = TxType.of(tx.type);
    final cat = categories.byId(tx.categoryId);
    final acc = accounts.byId(tx.accountId);
    final to = accounts.byId(tx.toAccountId);
    final via = accounts.byId(tx.viaUpiId);
    final cardSpend = acc?.type == AccountType.creditCard.code && type == TxType.expense;

    final title = tx.note?.isNotEmpty == true ? tx.note! : (cat?.name ?? (type == TxType.transfer ? 'Transfer' : 'Entry'));
    final where = switch (type) {
      TxType.transfer => '${acc?.name ?? '?'} → ${to?.name ?? '?'}',
      _ => via != null ? '${acc?.name ?? '?'} via ${via.name}' : (acc?.name ?? '?'),
    };
    final sub = [
      if (showDate) Dates.short(Dates.parseIso(tx.date)),
      if (cat != null && tx.note?.isNotEmpty == true) cat.name,
      where,
    ].join(' · ');

    // sign from the perspective account, else from "my money" perspective
    int signed;
    Color color;
    if (type == TxType.adjustment) {
      signed = tx.amount;
      color = BColors.warning;
    } else if (type == TxType.transfer) {
      signed = perspective == null ? tx.amount : (tx.toAccountId == perspective ? tx.amount : -tx.amount);
      color = BColors.textMuted;
    } else if (type.isIncome) {
      signed = tx.amount;
      color = BColors.success;
    } else {
      signed = -tx.amount;
      color = BColors.text;
    }
    final amountText = type == TxType.transfer && perspective == null
        ? '⇄ ${Money.format(tx.amount)}'
        : Money.format(signed, signed: true);

    final IconData icon = switch (type) {
      TxType.transfer => LucideIcons.arrowLeftRight,
      TxType.adjustment => LucideIcons.scale,
      _ => cat == null ? LucideIcons.receipt : categoryIcon(cat),
    };
    final iconColor = switch (type) {
      TxType.transfer => BColors.primaryLight,
      TxType.adjustment => BColors.warning,
      TxType.salary || TxType.extraIncome => BColors.success,
      _ => cat == null ? BColors.textMuted : categoryColor(cat),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: type == TxType.adjustment ? null : () => showAddEntrySheet(context, existing: tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(children: [
          IconBadge(icon: icon, color: iconColor, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: BText.body, overflow: TextOverflow.ellipsis),
              Text(sub, style: BText.caption, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(amountText, style: BText.amount(color: color)),
            if (cardSpend) Text('on card', style: BText.caption.copyWith(fontSize: 10.5)),
          ]),
        ]),
      ),
    );
  }
}
