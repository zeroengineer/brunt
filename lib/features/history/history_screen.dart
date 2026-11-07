import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../data/db/database.dart';
import '../../data/repositories/queries.dart';
import '../../design/design.dart';
import '../common/pickers.dart';
import 'paged_tx_list.dart';

/// History (spec §11.5 #8): paginated, search + filter by category, account and type.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.standalone = false});
  final bool standalone;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();
  HistoryFilter _filter = const HistoryFilter();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final accounts = ref.read(allAccountsProvider).value ?? const <AccountRow>[];
    final cats = ref.read(categoriesProvider).value ?? const <CategoryRow>[];
    var f = _filter;
    final applied = await showBruntSheet<HistoryFilter>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Filter', style: BText.h2),
          const SizedBox(height: 16),
          const Text('Type', style: BText.caption),
          const SizedBox(height: 8),
          ChoicePills<String>(
            wrap: true,
            items: const [
              ChoiceItem('', 'All'),
              ChoiceItem('expense', 'Expenses'),
              ChoiceItem('extra_income', 'Extra income'),
              ChoiceItem('salary', 'Salary'),
              ChoiceItem('transfer', 'Transfers'),
              ChoiceItem('adjustment', 'Adjustments'),
            ],
            selected: f.type?.code ?? '',
            onChanged: (v) => set(() => f = HistoryFilter(
                categoryId: f.categoryId, accountId: f.accountId, search: f.search, type: v.isEmpty ? null : TxType.of(v))),
          ),
          const SizedBox(height: 16),
          const Text('Account', style: BText.caption),
          const SizedBox(height: 8),
          ChoicePills<int>(
            wrap: true,
            items: [const ChoiceItem(-1, 'All'), ...accountItems(accounts, showBalance: false)],
            selected: f.accountId ?? -1,
            onChanged: (v) => set(() => f = HistoryFilter(
                categoryId: f.categoryId, type: f.type, search: f.search, accountId: v == -1 ? null : v)),
          ),
          const SizedBox(height: 16),
          const Text('Category', style: BText.caption),
          const SizedBox(height: 8),
          ChoicePills<int>(
            wrap: true,
            items: [const ChoiceItem(-1, 'All'), for (final c in cats) ChoiceItem(c.id, c.name, icon: categoryIcon(c))],
            selected: f.categoryId ?? -1,
            onChanged: (v) => set(() => f = HistoryFilter(
                accountId: f.accountId, type: f.type, search: f.search, categoryId: v == -1 ? null : v)),
          ),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
              child: PillButton(
                label: 'Clear',
                variant: PillVariant.outline,
                expand: true,
                onPressed: () => Navigator.pop(ctx, HistoryFilter(search: f.search)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: PillButton(label: 'Apply', expand: true, onPressed: () => Navigator.pop(ctx, f))),
          ]),
        ]),
      ),
    );
    if (applied != null) setState(() => _filter = applied);
  }

  @override
  Widget build(BuildContext context) {
    final active = _filter.categoryId != null || _filter.accountId != null || _filter.type != null;
    final body = Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(BSpace.gutter, 4, BSpace.gutter, 4),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _search,
              style: BText.body,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => setState(() => _filter = HistoryFilter(
                  categoryId: _filter.categoryId, accountId: _filter.accountId, type: _filter.type, search: v)),
              onChanged: (v) {
                if (v.isEmpty) {
                  setState(() => _filter = HistoryFilter(categoryId: _filter.categoryId, accountId: _filter.accountId, type: _filter.type));
                }
              },
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search notes or categories',
                hintStyle: BText.bodyMuted,
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: BColors.textMuted),
                filled: true,
                fillColor: BColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(BRadius.pill), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Filters',
            style: IconButton.styleFrom(backgroundColor: active ? BColors.primary : BColors.surface),
            onPressed: _openFilters,
            icon: const Icon(LucideIcons.slidersHorizontal, size: 18, color: BColors.text),
          ),
        ]),
      ),
      Expanded(child: PagedTxList(filter: _filter)),
    ]);
    if (!widget.standalone) return body;
    return BruntScaffold(title: 'History', showBack: true, body: body);
  }
}
