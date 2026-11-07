import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../data/db/database.dart';
import '../../design/design.dart';
import '../common/pickers.dart';

/// Categories per tier: create, rename, recolour, reorder, archive (spec §2).
/// Tier order itself is fixed because it drives the projection.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, {CategoryRow? existing, Tier? tier}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    String? icon = existing?.icon;
    Color? color = existing?.color == null ? null : BColors.fromHex(existing!.color);
    var archived = existing?.archived ?? false;
    final t = existing == null ? tier! : Tier.of(existing.tier);
    final ok = await showBruntSheet<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(existing == null ? 'New ${t.label} category' : 'Edit category', style: BText.h2),
          const SizedBox(height: 16),
          BField(label: 'Name', controller: name, autofocus: existing == null),
          const SizedBox(height: 14),
          const Text('Icon', style: BText.caption),
          const SizedBox(height: 8),
          IconPicker(selected: icon, onChanged: (v) => set(() => icon = v), color: color ?? BColors.tier(t)),
          const SizedBox(height: 14),
          const Text('Colour', style: BText.caption),
          const SizedBox(height: 8),
          ColorPicker(selected: color, onChanged: (c) => set(() => color = c)),
          if (existing != null) ...[
            const SizedBox(height: 10),
            SwitchRow(label: 'Archived', sub: 'Hidden from pickers, history kept', value: archived, onChanged: (v) => set(() => archived = v)),
          ],
          const SizedBox(height: 20),
          PillButton(label: 'Save', expand: true, onPressed: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    final n = name.text.trim();
    name.dispose();
    final s = ref.read(sessionProvider);
    if (ok != true || n.isEmpty || s == null) return;
    final hex = color == null ? null : BColors.hex(color!);
    if (existing == null) {
      await s.catalog.createCategory(name: n, tier: t, icon: icon, color: hex);
    } else {
      await s.catalog.updateCategory(existing.id, name: n, icon: icon, color: hex);
      if (archived != existing.archived) await s.catalog.setCategoryArchived(existing.id, archived);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).value ?? const <CategoryRow>[];
    return BruntScaffold(
      title: 'Categories',
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(BSpace.gutter, 0, BSpace.gutter, 60),
        children: [
          for (final tier in Tier.values) ...[
            SectionHeader(
              tier.label,
              trailing: IconButton(
                tooltip: 'Add ${tier.label} category',
                onPressed: () => _edit(context, ref, tier: tier),
                icon: const Icon(LucideIcons.plus, size: 18, color: BColors.primaryLight),
              ),
            ),
            Builder(builder: (_) {
              final list = cats.where((c) => c.tier == tier.value).toList();
              return ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: true,
                proxyDecorator: (child, _, _) => Material(color: Colors.transparent, child: child),
                onReorderItem: (from, to) {
                  final ids = list.map((c) => c.id).toList();
                  ids.insert(to, ids.removeAt(from));
                  ref.read(sessionProvider)?.catalog.reorderCategories(ids);
                },
                children: [
                  for (final c in list)
                    Padding(
                      key: ValueKey(c.id),
                      padding: const EdgeInsets.only(bottom: 6),
                      child: AppCard(
                        radius: 18,
                        onTap: () => _edit(context, ref, existing: c),
                        padding: const EdgeInsets.fromLTRB(12, 8, 40, 8),
                        child: Row(children: [
                          Opacity(opacity: c.archived ? 0.4 : 1, child: IconBadge(icon: categoryIcon(c), color: categoryColor(c), size: 34)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(c.name, style: BText.body.copyWith(color: c.archived ? BColors.textMuted : BColors.text)),
                          ),
                          if (c.archived) const Text('archived', style: BText.caption),
                        ]),
                      ),
                    ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}
