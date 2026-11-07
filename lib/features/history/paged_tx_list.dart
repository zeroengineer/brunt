import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/repositories/queries.dart';
import '../../design/design.dart';
import 'tx_tile.dart';

/// Keyset-paginated transaction list (`WHERE (date,id) < cursor LIMIT 50`), reloads when
/// the month version changes.
class PagedTxList extends ConsumerStatefulWidget {
  const PagedTxList({super.key, this.filter = const HistoryFilter(), this.perspective, this.header, this.padding});

  final HistoryFilter filter;
  final int? perspective;
  final Widget? header;
  final EdgeInsetsGeometry? padding;

  @override
  ConsumerState<PagedTxList> createState() => _PagedTxListState();
}

class _PagedTxListState extends ConsumerState<PagedTxList> {
  static const _page = 50;
  final _rows = <TxRow>[];
  bool _loading = false;
  bool _done = false;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  void didUpdateWidget(PagedTxList old) {
    super.didUpdateWidget(old);
    if (old.filter.categoryId != widget.filter.categoryId ||
        old.filter.accountId != widget.filter.accountId ||
        old.filter.type != widget.filter.type ||
        old.filter.search != widget.filter.search) {
      unawaited(_reload());
    }
  }

  Future<void> _reload() async {
    _gen++;
    setState(() {
      _rows.clear();
      _done = false;
      _loading = false;
    });
    await _more();
  }

  Future<void> _more() async {
    if (_loading || _done) return;
    final s = ref.read(sessionProvider);
    if (s == null) return;
    final gen = _gen;
    setState(() => _loading = true);
    final last = _rows.isEmpty ? null : HistoryCursor(_rows.last.date, _rows.last.id);
    final page = await s.queries.historyPage(after: last, filter: widget.filter, limit: _page);
    if (!mounted || gen != _gen) return;
    setState(() {
      _rows.addAll(page);
      _loading = false;
      _done = page.length < _page;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(monthKeyProvider, (_, _) => _reload());
    final accounts = ref.watch(allAccountsProvider).value ?? const <AccountRow>[];
    final cats = ref.watch(categoriesProvider).value ?? const <CategoryRow>[];

    final items = <Object>[];
    String? lastDate;
    for (final r in _rows) {
      if (r.date != lastDate) {
        items.add(r.date);
        lastDate = r.date;
      }
      items.add(r);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 400) _more();
        return false;
      },
      child: ListView.builder(
        padding: widget.padding ?? const EdgeInsets.fromLTRB(BSpace.gutter, 0, BSpace.gutter, 120),
        itemCount: items.length + 2,
        itemBuilder: (context, i) {
          if (i == 0) return widget.header ?? const SizedBox();
          if (i == items.length + 1) {
            if (_loading) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
            if (_rows.isEmpty) {
              return const EmptyState(icon: LucideIcons.receipt, title: 'No entries', message: 'Entries you add show up here.');
            }
            return const SizedBox(height: 24);
          }
          final it = items[i - 1];
          if (it is String) {
            final d = Dates.parseIso(it);
            final today = Dates.day(DateTime.now());
            final label = DateUtils.isSameDay(d, today)
                ? 'Today'
                : DateUtils.isSameDay(d, today.subtract(const Duration(days: 1)))
                    ? 'Yesterday'
                    : '${Dates.weekdayShort[d.weekday - 1]}, ${Dates.short(d)} ${d.year != today.year ? d.year : ''}';
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
              child: Text(label.trim(), style: BText.caption.copyWith(fontWeight: FontWeight.w700)),
            );
          }
          return TxTile(tx: it as TxRow, accounts: accounts, categories: cats, perspective: widget.perspective, showDate: false);
        },
      ),
    );
  }
}
