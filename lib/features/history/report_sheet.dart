
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/repositories/queries.dart';
import '../../design/design.dart';
import '../../security/reauth.dart';
import '../common/export_file.dart';
import 'pdf_report.dart';

/// Month-wise transaction report (CSV) with the History filters applied.
Future<void> showReportSheet(BuildContext context, {HistoryFilter filter = const HistoryFilter()}) =>
    showBruntSheet<void>(context, builder: (_) => _ReportSheet(filter: filter));

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.filter});
  final HistoryFilter filter;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  List<MonthRow>? _months;
  int? _monthId; // null = all months
  bool _useFilters = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = ref.read(sessionProvider);
    if (s == null) return;
    final months = await s.queries.months();
    if (!mounted) return;
    setState(() {
      _months = months.reversed.toList();
      _monthId = widget.filter.monthId ?? (months.isEmpty ? null : months.last.id);
    });
  }

  Future<void> _export() async {
    final s = ref.read(sessionProvider);
    if (s == null) return;
    if (!await reauthenticate(context, ref, reason: 'Confirm to export a report')) return;
    setState(() => _busy = true);
    try {
      final base = _useFilters ? widget.filter : const HistoryFilter();
      final f = base.copyWith(monthId: _monthId, clearMonth: _monthId == null);
      final rows = await s.queries.reportRows(f);
      final ym = _months?.where((m) => m.id == _monthId).firstOrNull?.yearMonth;
      final filtered = _useFilters && !widget.filter.isEmpty;
      final stem = 'brunt-${ym ?? 'all-months'}${filtered ? '-filtered' : ''}';
      final bytes = await PdfReport.build(
        rows,
        title: ym == null ? 'All months' : Dates.monthLabel(ym),
        subtitle: filtered ? 'Filtered: ${activeFilterLabels().join(' · ')}' : 'Transaction report',
      );
      if (!mounted) return;
      // Ask save / share while this sheet is still open: its context and ref must stay alive
      // until the file is written (popping first silently dropped the export).
      await saveOrShare(context, ref,
          bytes: bytes,
          fileName: '$stem.pdf',
          mimeType: 'application/pdf',
          title: '${rows.length} entries · PDF');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, 'Could not build report: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> activeFilterLabels() {
    final cats = ref.read(categoriesProvider).value ?? const <CategoryRow>[];
    final accounts = ref.read(allAccountsProvider).value ?? const <AccountRow>[];
    final f = widget.filter;
    return [
      if (f.type != null) f.type!.code.replaceAll('_', ' '),
      if (f.accountId != null) accounts.byId(f.accountId)?.name,
      if (f.categoryId != null) cats.byId(f.categoryId)?.name,
      if (f.search != null && f.search!.isNotEmpty) '"${f.search}"',
    ].whereType<String>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeFilters = activeFilterLabels();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Export report', style: BText.h2),
      const SizedBox(height: 4),
      const Text('Month-wise PDF statement of your entries. The file is not encrypted — share it carefully.', style: BText.caption),
      const SizedBox(height: 16),
      const Text('Month', style: BText.caption),
      const SizedBox(height: 8),
      if (_months == null)
        const Center(child: CircularProgressIndicator())
      else
        ChoicePills<int>(
          wrap: true,
          items: [
            const ChoiceItem(-1, 'All months'),
            for (final m in _months!) ChoiceItem(m.id, Dates.monthLabel(m.yearMonth)),
          ],
          selected: _monthId ?? -1,
          onChanged: (v) => setState(() => _monthId = v == -1 ? null : v),
        ),
      if (activeFilters.isNotEmpty) ...[
        const SizedBox(height: 12),
        SwitchRow(
          label: 'Apply current filters',
          sub: activeFilters.join(' · '),
          value: _useFilters,
          onChanged: (v) => setState(() => _useFilters = v),
        ),
      ],
      const SizedBox(height: 20),
      PillButton(label: 'Export PDF', icon: LucideIcons.download, expand: true, busy: _busy, onPressed: _export),
    ]);
  }
}
