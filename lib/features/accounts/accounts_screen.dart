import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../design/design.dart';
import '../common/pickers.dart';
import '../add_entry/add_entry_sheet.dart';
import 'account_form.dart';

/// Month in/out per account, keyed on the month version cache key.
final accountFlowsProvider = FutureProvider<Map<int, (int, int)>>((ref) async {
  final key = ref.watch(monthKeyProvider);
  final s = ref.watch(sessionProvider);
  if (key == null || s == null) return const {};
  return s.queries.accountFlows(key.$1);
});

/// Closing balance per account for recent months (mini trend).
final accountTrendsProvider = FutureProvider<Map<int, List<int>>>((ref) async {
  final key = ref.watch(monthKeyProvider);
  final s = ref.watch(sessionProvider);
  if (key == null || s == null) return const {};
  final months = await s.queries.months();
  final recent = months.length > 6 ? months.sublist(months.length - 6) : months;
  final accounts = await s.queries.accounts();
  final out = <int, List<int>>{};
  for (final m in recent) {
    final rows = await (s.db.select(s.db.accountMonthBalances)..where((b) => b.monthId.equals(m.id))).get();
    for (final r in rows) {
      final live = accounts.where((a) => a.id == r.accountId).firstOrNull?.balance;
      out.putIfAbsent(r.accountId, () => []).add(r.closing ?? live ?? r.opening);
    }
  }
  return out;
});

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allAccountsProvider).value;
    final flows = ref.watch(accountFlowsProvider).value ?? const {};
    final trends = ref.watch(accountTrendsProvider).value ?? const {};
    if (all == null) return const Center(child: CircularProgressIndicator());
    final active = all.where((a) => !a.archived).toList();
    final archived = all.where((a) => a.archived).toList();

    int sum(bool Function(AccountRow) f) => active.where(f).fold(0, (s, a) => s + a.balance);
    final spendable = sum((a) => a.includeInSpendable && a.type != AccountType.creditCard.code && a.type != AccountType.upi.code);
    final savings = sum((a) => a.type == AccountType.savings.code);
    final dues = sum((a) => a.type == AccountType.creditCard.code);
    final assets = sum((a) => a.type != AccountType.creditCard.code && a.type != AccountType.upi.code);

    return SafeArea(
      bottom: false,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(BSpace.gutter + 4, 10, 8, 8),
          child: Row(children: [
            Expanded(child: Semantics(header: true, child: const Text('Accounts', style: BText.h1))),
            IconButton(
              tooltip: 'Transfer between accounts',
              onPressed: () => showAddEntrySheet(context, presetType: TxType.transfer),
              icon: const Icon(LucideIcons.arrowLeftRight),
            ),
            IconButton(
              tooltip: 'Add account',
              onPressed: () => showAccountForm(context),
              icon: const Icon(LucideIcons.plus),
            ),
          ]),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(BSpace.gutter, 0, BSpace.gutter, 120),
            header: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  Row(children: [
                    _Stat('Spendable', spendable, BColors.text),
                    _Stat('Savings', savings, BColors.tierSavings),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    _Stat('Card dues', dues, dues > 0 ? BColors.danger : BColors.text),
                    _Stat('Net worth', assets - dues, BColors.success),
                  ]),
                ]),
              ),
            ),
            footer: archived.isEmpty
                ? null
                : Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text('Archived (${archived.length})', style: BText.label.copyWith(color: BColors.textMuted)),
                      children: [
                        for (final a in archived)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            leading: IconBadge(icon: accountIcon(a), color: BColors.textMuted, size: 36),
                            title: Text(a.name, style: BText.body.copyWith(color: BColors.textMuted)),
                            trailing: Text(Money.format(a.balance), style: BText.amount(color: BColors.textMuted)),
                            onTap: () => context.push('/account/${a.id}'),
                          ),
                      ],
                    ),
                  ),
            itemCount: active.length,
            onReorderItem: (from, to) {
              final ids = active.map((a) => a.id).toList();
              ids.insert(to, ids.removeAt(from));
              ref.read(sessionProvider)?.catalog.reorderAccounts(ids);
            },
            proxyDecorator: (child, _, _) => Material(color: Colors.transparent, child: child),
            itemBuilder: (context, i) {
              final a = active[i];
              final f = flows[a.id];
              return Padding(
                key: ValueKey(a.id),
                padding: const EdgeInsets.only(bottom: 10),
                child: _AccountCard(account: a, all: all, flow: f, trend: trends[a.id] ?? const []),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: BText.caption),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: Text(Money.format(value), style: BText.amount(size: 19, weight: FontWeight.w800, color: color))),
      ]),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.all, required this.flow, required this.trend});
  final AccountRow account;
  final List<AccountRow> all;
  final (int, int)? flow;
  final List<int> trend;

  @override
  Widget build(BuildContext context) {
    final a = account;
    final type = AccountType.of(a.type);
    final card = type == AccountType.creditCard;
    final color = accountColor(a);
    final usedPct = card && (a.creditLimit ?? 0) > 0 ? (a.balance / a.creditLimit!).clamp(0.0, 1.0) : null;
    return AppCard(
      onTap: () => context.push('/account/${a.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconBadge(icon: accountIcon(a), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.name, style: BText.body.copyWith(fontWeight: FontWeight.w600)),
              Text(accountSubtitle(a, all), style: BText.caption, overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (type != AccountType.upi)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(Money.format(a.balance), style: BText.amount(size: 17, color: card && a.balance > 0 ? BColors.danger : BColors.text)),
              if (card) Text('outstanding', style: BText.caption.copyWith(fontSize: 10.5)),
            ]),
        ]),
        if (usedPct != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usedPct,
              minHeight: 6,
              backgroundColor: BColors.surfaceRaised,
              color: usedPct >= 0.8 ? BColors.warning : BColors.primaryLight,
            ),
          ),
        ],
        if (type != AccountType.upi && (flow != null || trend.length > 1)) ...[
          const SizedBox(height: 12),
          Row(children: [
            if (flow != null) ...[
              const Icon(LucideIcons.arrowDownLeft, size: 14, color: BColors.success),
              const SizedBox(width: 3),
              Text(Money.compact(flow!.$1), style: BText.caption),
              const SizedBox(width: 12),
              const Icon(LucideIcons.arrowUpRight, size: 14, color: BColors.danger),
              const SizedBox(width: 3),
              Text(Money.compact(flow!.$2), style: BText.caption),
              const Text('  this month', style: BText.caption),
            ],
            const Spacer(),
            if (trend.length > 1) SizedBox(width: 64, height: 22, child: CustomPaint(painter: _Spark(trend, color))),
          ]),
        ],
      ]),
    );
  }
}

class _Spark extends CustomPainter {
  _Spark(this.values, this.color);
  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final mn = values.reduce((a, b) => a < b ? a : b);
    final mx = values.reduce((a, b) => a > b ? a : b);
    final range = (mx - mn) == 0 ? 1 : (mx - mn);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - size.height * (values[i] - mn) / range;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_Spark old) => old.values != values || old.color != color;
}
