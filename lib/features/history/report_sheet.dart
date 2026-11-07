import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/repositories/queries.dart';
import '../../design/design.dart';
import '../../domain/report/csv_report.dart';
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
  bool _pdf = true;
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
    if (!await reauthenticate(context, ref, reason: 'Confirm to export a plain-text report')) return;
    setState(() => _busy = true);
    try {
      final base = _useFilters ? widget.filter : const HistoryFilter();
      final f = base.copyWith(monthId: _monthId, clearMonth: _monthId == null);
      final rows = await s.queries.reportRows(f);
      final ym = _months?.where((m) => m.id == _monthId).firstOrNull?.yearMonth;
      final filtered = _useFilters && !widget.filter.isEmpty;
      final stem = 'brunt-${ym ?? 'all-months'}${filtered ? '-filtered' : ''}';
      final Uint8List bytes;
      if (_pdf) {
        bytes = await PdfReport.build(
          rows,
          title: ym == null ? 'All months' : Dates.monthLabel(ym),
          subtitle: filtered ? 'Filtered: ${activeFilterLabels().join(' · ')}' : 'Transaction report',
        );
      } else {
        // UTF-8 BOM so Excel reads ₹ and non-ASCII names correctly
        bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(CsvReport.build(rows))]);
      }
      if (!mounted) return;
      Navigator.pop(context);
      await saveOrShare(context, ref,
          bytes: bytes,
          fileName: '$stem.${_pdf ? 'pdf' : 'csv'}',
          mimeType: _pdf ? 'application/pdf' : 'text/csv',
          title: '${rows.length} entries · ${_pdf ? 'PDF' : 'CSV'}');
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
      const Text('Month-wise statement of your entries. The file is not encrypted — share it carefully.', style: BText.caption),
      const SizedBox(height: 16),
      SegmentTabs(
        items: const [SegmentItem('PDF'), SegmentItem('CSV (spreadsheet)')],
        selected: _pdf ? 0 : 1,
        onChanged: (i) => setState(() => _pdf = i == 0),
      ),
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
      PillButton(label: _pdf ? 'Export PDF' : 'Export CSV', icon: LucideIcons.download, expand: true, busy: _busy, onPressed: _export),
    ]);
  }
}
