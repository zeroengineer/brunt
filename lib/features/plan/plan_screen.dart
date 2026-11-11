import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/repositories/catalog_repo.dart';
import '../../design/design.dart';
import '../common/pickers.dart';
import 'pay_sheet.dart';

/// Bottom-nav Plan tab.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(BSpace.gutter + 4, 10, 8, 4),
          child: Row(children: [
            Expanded(child: Semantics(header: true, child: const Text('Plan', style: BText.h1))),
            TextButton.icon(
              onPressed: () => context.push('/templates'),
              icon: const Icon(LucideIcons.repeat, size: 16),
              label: const Text('Recurring items'),
            ),
          ]),
        ),
        const Expanded(child: PlanView()),
      ]),
    );
  }
}

/// Month's planned items grouped by tier, with Pending · Paid · Skipped · Overdue chips (spec §4.4).
class PlanView extends ConsumerWidget {
  const PlanView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(plannedProvider).value;
    final cats = ref.watch(categoriesProvider).value ?? const <CategoryRow>[];
    if (items == null) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return EmptyState(
        icon: LucideIcons.listChecks,
        title: 'Nothing planned this month',
        message: 'Add rent, EMIs, savings and bills as recurring items. They appear here every month.',
        action: PillButton(label: 'Add recurring item', icon: LucideIcons.plus, onPressed: () => context.push('/templates')),
      );
    }
    Tier tierOf(PlannedRow p) => p.cardAccountId != null ? Tier.priority : Tier.of(cats.byId(p.categoryId)?.tier ?? 3);
    bool isReserve(PlannedRow p) {
      final c = cats.byId(p.categoryId);
      return c != null && c.name == CatalogRepo.reserveCategoryName && c.tier == Tier.savings.value;
    }
    final sections = <(String, Tier, List<PlannedRow>)>[
      for (final tier in const [Tier.priority, Tier.savings, Tier.fixed, Tier.daily, Tier.variable]) ...[
        (tier.label, tier, items.where((p) => !isReserve(p) && tierOf(p) == tier).toList()),
        if (tier == Tier.savings) ('Reserve', Tier.savings, items.where(isReserve).toList()),
      ],
    ];
    final today = Dates.day(DateTime.now());
    final total = items.where((p) => p.status != 'skipped').fold<int>(0, (s, p) => s + p.amount);
    final paid = items.where((p) => p.status == 'paid').fold<int>(0, (s, p) => s + p.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(BSpace.gutter, 8, BSpace.gutter, 120),
      children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Paid so far', style: BText.caption)),
              Text('${Money.format(paid)} of ${Money.format(total)}', style: BText.amount(size: 14)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : paid / total,
                minHeight: 8,
                backgroundColor: BColors.surfaceRaised,
                color: BColors.primaryLight,
              ),
            ),
          ]),
        ),
        for (final (label, tier, list) in sections)
          if (list.isNotEmpty) ...[
            SectionHeader(
              label,
              trailing: Text(
                Money.format(list.where((p) => p.status != 'skipped').fold<int>(0, (s, p) => s + p.amount)),
                style: BText.amount(size: 14, color: BColors.textMuted),
              ),
            ),
            for (final p in list)
              _PlannedTile(item: p, tier: tier, today: today, cat: cats.byId(p.categoryId), color: label == 'Reserve' ? BColors.tierReserve : null),
          ],
      ],
    );
  }
}

class _PlannedTile extends StatelessWidget {
  const _PlannedTile({required this.item, required this.tier, required this.today, this.cat, this.color});
  final PlannedRow item;

  /// Overrides the tier colour (Reserve).
  final Color? color;
  final Tier tier;
  final DateTime today;
  final CategoryRow? cat;

  @override
  Widget build(BuildContext context) {
    final status = PlannedStatus.of(item.status);
    final due = item.dueDate == null ? null : Dates.parseIso(item.dueDate!);
    final overdue = status == PlannedStatus.pending && due != null && due.isBefore(today);
    final chip = overdue
        ? ChipStatus.overdue
        : switch (status) {
            PlannedStatus.paid => ChipStatus.paid,
            PlannedStatus.skipped => ChipStatus.skipped,
            PlannedStatus.pending => ChipStatus.pending,
          };
    final color = this.color ?? (BColors.tier(tier) == BColors.tierVariable ? BColors.textMuted : BColors.tier(tier));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: () => showPaySheet(context, item),
        radius: 20,
        borderColor: overdue ? BColors.danger.withValues(alpha: 0.5) : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          IconBadge(icon: cat == null ? LucideIcons.creditCard : categoryIcon(cat!), color: color, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name,
                  style: BText.body.copyWith(
                    decoration: status == PlannedStatus.skipped ? TextDecoration.lineThrough : null,
                    color: status == PlannedStatus.pending ? BColors.text : BColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis),
              Text(
                [due == null ? 'Anytime' : 'Due ${Dates.short(due)}', if (item.cardAccountId != null) 'card bill'].join(' · '),
                style: BText.caption.copyWith(color: overdue ? BColors.danger : null),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Money.format(item.amount), style: BText.amount()),
            const SizedBox(height: 4),
            StatusChip(chip),
          ]),
        ]),
      ),
    );
  }
}
