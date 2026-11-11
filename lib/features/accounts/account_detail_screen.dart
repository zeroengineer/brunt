import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/repositories/ledger.dart';
import '../../data/repositories/queries.dart';
import '../../design/design.dart';
import '../add_entry/add_entry_sheet.dart';
import '../common/pickers.dart';
import '../history/paged_tx_list.dart';
import 'account_form.dart';

/// Account detail (spec §4.9 #4): history, edit, adjust balance, archive, delete.
class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});
  final int accountId;

  Future<void> _adjust(BuildContext context, WidgetRef ref, AccountRow a) async {
    final ctrl = TextEditingController(text: rupeesText(a.balance));
    final card = AccountType.of(a.type).isLiability;
    final ok = await showBruntSheet<bool>(
      context,
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Adjust balance', style: BText.h2),
        const SizedBox(height: 6),
        Text(
          'Set the real ${card ? 'outstanding' : 'amount'} in ${a.name}. The difference is recorded as an Unaccounted entry so totals stay honest.',
          style: BText.bodyMuted,
        ),
        const SizedBox(height: 18),
        BField.amount(label: card ? 'Real outstanding' : 'Real balance', controller: ctrl, autofocus: true),
        const SizedBox(height: 20),
        PillButton(label: 'Set balance', expand: true, onPressed: () => Navigator.pop(ctx, true)),
      ]),
    );
    final v = Money.parse(ctrl.text);
    ctrl.dispose();
    if (ok != true || v == null) return;
    try {
      await ref.read(sessionProvider)?.ledger.adjustBalance(a.id, v);
      if (context.mounted) toast(context, 'Balance adjusted');
    } on LedgerException catch (e) {
      if (context.mounted) toast(context, e.message, error: true);
    }
  }

  /// Moves money out of a reserve back into its bank (it becomes spendable again).
  Future<void> _release(BuildContext context, WidgetRef ref, AccountRow bank, AccountRow reserve) async {
    final ctrl = TextEditingController(text: rupeesText(reserve.balance));
    final ok = await showBruntSheet<bool>(
      context,
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Release reserve', style: BText.h2),
        const SizedBox(height: 6),
        Text('Moves money from ${reserve.name} back into ${bank.name}, where it counts as spendable again.', style: BText.bodyMuted),
        const SizedBox(height: 18),
        BField.amount(label: 'Amount to release', controller: ctrl, autofocus: true),
        const SizedBox(height: 20),
        PillButton(label: 'Release', expand: true, onPressed: () => Navigator.pop(ctx, true)),
      ]),
    );
    final v = Money.parse(ctrl.text);
    ctrl.dispose();
    if (ok != true || v == null || v <= 0) return;
    if (v > reserve.balance) {
      if (context.mounted) toast(context, 'Only ${Money.format(reserve.balance)} is in reserve', error: true);
      return;
    }
    try {
      await ref.read(sessionProvider)?.ledger.add(Entry(
            type: TxType.transfer,
            amount: v,
            date: Dates.day(DateTime.now()),
            accountId: reserve.id,
            toAccountId: bank.id,
            note: 'Released from reserve',
          ));
      if (context.mounted) toast(context, 'Released ${Money.format(v)}');
    } on LedgerException catch (e) {
      if (context.mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, AccountRow a, String v) async {
    final s = ref.read(sessionProvider);
    if (s == null) return;
    switch (v) {
      case 'edit':
        await showAccountForm(context, existing: a);
      case 'archive':
        await s.catalog.setArchived(a.id, !a.archived);
        if (context.mounted) toast(context, a.archived ? 'Restored' : 'Archived — history kept');
      case 'delete':
        if (await s.catalog.accountHasEntries(a.id)) {
          if (context.mounted) toast(context, 'It has entries — archive it instead', error: true);
          return;
        }
        if (!context.mounted) return;
        final ok = await confirmDialog(context, title: 'Delete ${a.name}?', message: 'This cannot be undone.', confirm: 'Delete', danger: true);
        if (!ok) return;
        await s.catalog.deleteAccount(a.id);
        if (context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allAccountsProvider).value ?? const <AccountRow>[];
    final a = all.byId(accountId);
    if (a == null) return const BruntScaffold(showBack: true, body: Center(child: CircularProgressIndicator()));
    final type = AccountType.of(a.type);
    final card = type == AccountType.creditCard;
    final owed = type.isLiability;
    final upi = type == AccountType.upi;
    final reserves = all.where((r) => r.type == AccountType.reserve.code && r.linkedAccountId == a.id && !r.archived).toList();
    final reserveTotal = reserves.fold<int>(0, (s, r) => s + r.balance);

    final header = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconBadge(icon: accountIcon(a), color: accountColor(a), size: 44),
            const SizedBox(width: 12),
            Expanded(child: Text(accountSubtitle(a, all), style: BText.caption)),
            if (a.archived) const StatusChip(ChipStatus.skipped, label: 'Archived'),
          ]),
          const SizedBox(height: 16),
          if (!upi) ...[
            Text(owed ? (card ? 'Outstanding due' : 'Still to pay back') : (type == AccountType.lent ? 'Owed to you' : 'Balance'), style: BText.caption),
            const SizedBox(height: 4),
            Text(Money.format(a.balance + reserveTotal), style: BText.display.copyWith(fontSize: 34, color: owed && a.balance > 0 ? BColors.danger : BColors.text)),
            if (reserves.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('${Money.format(a.balance)} available · ${Money.format(reserveTotal)} kept in reserve', style: BText.caption),
            ],
          ] else
            Text('Payments via ${a.name} come out of ${all.byId(a.linkedAccountId)?.name ?? 'its bank'}.', style: BText.body),
          if (card && a.creditLimit != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (a.balance / a.creditLimit!).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: BColors.surfaceRaised,
                color: a.balance >= a.creditLimit! * 0.8 ? BColors.warning : BColors.primaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Used ${Money.format(a.balance)} · Available ${Money.format(a.creditLimit! - a.balance)} · '
              'Statement ${Dates.ordinal(a.statementDay ?? 1)}, due ${Dates.ordinal(a.dueDay ?? 1)}',
              style: BText.caption,
            ),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        if (!upi)
          PillButton(label: 'Adjust balance', icon: LucideIcons.scale, dense: true, variant: PillVariant.soft, onPressed: () => _adjust(context, ref, a)),
        PillButton(
          label: card ? 'Pay card' : (type == AccountType.loan ? 'Pay back' : (type == AccountType.lent ? 'Got it back' : 'Transfer')),
          icon: LucideIcons.arrowLeftRight,
          dense: true,
          variant: PillVariant.soft,
          onPressed: () => showAddEntrySheet(context, presetType: TxType.transfer, presetAccount: owed ? null : a.id, presetTo: owed ? a.id : null),
        ),
        PillButton(label: 'Edit', icon: LucideIcons.pencil, dense: true, variant: PillVariant.soft, onPressed: () => showAccountForm(context, existing: a)),
        for (final r in reserves.where((r) => r.balance > 0))
          PillButton(
            label: reserves.length > 1 ? 'Release ${r.name}' : 'Release reserve',
            icon: LucideIcons.shieldOff,
            dense: true,
            variant: PillVariant.soft,
            onPressed: () => _release(context, ref, a, r),
          ),
      ]),
      const SizedBox(height: 8),
      const SectionHeader('History', padding: EdgeInsets.fromLTRB(4, 16, 4, 0)),
    ]);

    return BruntScaffold(
      title: a.name,
      showBack: true,
      actions: [
        PopupMenuButton<String>(
          tooltip: 'More',
          icon: const Icon(LucideIcons.ellipsisVertical),
          onSelected: (v) => _menu(context, ref, a, v),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'archive', child: Text(a.archived ? 'Unarchive' : 'Archive')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ],
      body: PagedTxList(
        filter: HistoryFilter(accountId: a.id),
        perspective: a.id,
        header: header,
        padding: const EdgeInsets.fromLTRB(BSpace.gutter, 8, BSpace.gutter, 40),
      ),
    );
  }
}
