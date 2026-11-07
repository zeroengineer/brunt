import 'dart:io';

import 'package:brunt/domain/report/csv_report.dart';
import 'package:brunt/features/history/pdf_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PDF report builds with bundled font and writes a sample', (t) async {
    final rows = [
      const ReportRow(date: '2026-11-03', month: '2026-11', type: 'salary', amount: 4500000, category: 'Salary', account: 'HDFC'),
      const ReportRow(date: '2026-11-05', month: '2026-11', type: 'expense', amount: 1000000, category: 'Rent', note: 'Rent', account: 'HDFC', via: 'GPay'),
      const ReportRow(date: '2026-11-07', month: '2026-11', type: 'expense', amount: 25000, category: 'Food', note: 'Lunch with Priya', account: 'HDFC'),
      const ReportRow(date: '2026-11-07', month: '2026-11', type: 'transfer', amount: 100000, account: 'HDFC', toAccount: 'Cash in hand'),
      for (var d = 8; d <= 30; d++)
        ReportRow(date: '2026-11-${d.toString().padLeft(2, '0')}', month: '2026-11', type: 'expense', amount: 4000 + d * 100, category: 'Transport', note: 'Bus fare', account: 'Cash in hand'),
      const ReportRow(date: '2026-11-20', month: '2026-11', type: 'adjustment', amount: -5000, note: 'Unaccounted', account: 'Cash in hand'),
    ];
    final bytes = await t.runAsync(() => PdfReport.build(rows, title: 'November 2026', subtitle: 'Transaction report'));
    expect(bytes, isNotNull);
    final out = File('build/report_sample.pdf')..createSync(recursive: true);
    out.writeAsBytesSync(bytes!);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(5000));
  });
}
