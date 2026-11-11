import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../design/design.dart';
import '../common/pickers.dart';
import 'template_form.dart';

/// Templates & schedules (spec §3): create, edit, pause, delete.
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider).value ?? const <TemplateRow>[];
    final cats = ref.watch(categoriesProvider).value ?? const <CategoryRow>[];
    final accounts = ref.watch(allAccountsProvider).value ?? const <AccountRow>[];
    Tier tierOf(TemplateRow t) => Tier.of(cats.byId(t.categoryId)?.tier ?? 3);
    bool isReserve(TemplateRow t) => accounts.byId(t.toAccountId)?.type == AccountType.reserve.code;
    // Sections in order; Reserve gets its own group right after Savings.
    final sections = <(String, List<TemplateRow>)>[
      for (final tier in const [Tier.priority, Tier.savings, Tier.fixed, Tier.daily, Tier.variable]) ...[
        (tier.label, templates.where((t) => !isReserve(t) && tierOf(t) == tier).toList()),
        if (tier == Tier.savings) ('Reserve', templates.where(isReserve).toList()),
      ],
    ];

    return BruntScaffold(
      title: 'Recurring items',
      showBack: true,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add recurring item',
        onPressed: () => showTemplateForm(context),
        child: const Icon(LucideIcons.plus),
      ),
      body: templates.isEmpty
          ? const EmptyState(
              icon: LucideIcons.repeat,
              title: 'No recurring items yet',
              message: 'Monthly is the default. Choose Daily for things like bus fare, and pick the days.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(BSpace.gutter, 0, BSpace.gutter, 100),
              children: [
                for (final (label, items) in sections)
                  if (items.isNotEmpty) ...[
                    SectionHeader(label),
                    for (final t in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          radius: 20,
                          onTap: () => showTemplateForm(context, existing: t),
                          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                          child: Row(children: [
                            Builder(builder: (_) {
                              final c = cats.byId(t.categoryId);
                              return Opacity(
                                opacity: t.active ? 1 : 0.4,
                                child: IconBadge(icon: c == null ? LucideIcons.receipt : categoryIcon(c), color: c == null ? BColors.textMuted : categoryColor(c), size: 38),
                              );
                            }),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(t.name, style: BText.body.copyWith(color: t.active ? BColors.text : BColors.textMuted)),
                                Text(
                                  [
                                    if (!t.active) 'Paused',
                                    Frequency.of(t.frequency) == Frequency.daily
                                        ? 'Daily · ${WeekMask.describe(t.daysOfWeek)}'
                                        : '${Frequency.of(t.frequency).label}${t.dueDay != null ? ' · due ${Dates.ordinal(t.dueDay!)}' : ''}',
                                    isReserve(t) ? 'kept in ${accounts.byId(t.defaultAccountId)?.name ?? '—'}' : accounts.byId(t.defaultAccountId)?.name,
                                    if (t.endMonth != null && t.frequency != 'one_time') 'until ${Dates.monthLabel(t.endMonth!)}',
                                  ].whereType<String>().join(' · '),
                                  style: BText.caption,
                                ),
                              ]),
                            ),
                            Text(Money.format(t.defaultAmount), style: BText.amount()),
                            PopupMenuButton<String>(
                              tooltip: 'More',
                              icon: const Icon(LucideIcons.ellipsisVertical, size: 18, color: BColors.textMuted),
                              onSelected: (v) async {
                                final s = ref.read(sessionProvider);
                                if (s == null) return;
                                if (v == 'pause') await s.catalog.setTemplateActive(t.id, !t.active);
                                if (v == 'delete' && context.mounted) {
                                  final ok = await confirmDialog(context,
                                      title: 'Delete ${t.name}?',
                                      message: 'If it has history it will be paused instead, so past entries stay intact.',
                                      confirm: 'Delete',
                                      danger: true);
                                  if (ok) {
                                    final deleted = await s.catalog.deleteTemplate(t.id);
                                    if (context.mounted) toast(context, deleted ? 'Deleted' : 'Has history — paused instead');
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'pause', child: Text(t.active ? 'Pause' : 'Resume')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ]),
                        ),
                      ),
                  ],
              ],
            ),
    );
  }
}
