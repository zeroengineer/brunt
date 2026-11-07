/// Transaction report as CSV (pure Dart). Amounts are rupees with two decimals so the
/// file opens cleanly in any spreadsheet; the sign is carried by `direction`.
library;

class ReportRow {
  const ReportRow({
    required this.date,
    required this.month,
    required this.type,
    required this.amount,
    this.category,
    this.note,
    this.account,
    this.via,
    this.toAccount,
  });

  final String date; // yyyy-MM-dd
  final String month; // yyyy-MM
  final String type; // expense | extra_income | salary | transfer | adjustment
  final int amount; // paise, signed for adjustments
  final String? category;
  final String? note;
  final String? account;
  final String? via;
  final String? toAccount;
}

abstract final class CsvReport {
  static const header = ['date', 'month', 'direction', 'type', 'category', 'description', 'account', 'via_upi', 'to_account', 'amount_inr'];

  static String build(Iterable<ReportRow> rows) {
    final b = StringBuffer()..writeln(header.join(','));
    var income = 0, expense = 0;
    for (final r in rows) {
      final direction = switch (r.type) {
        'expense' => 'out',
        'salary' || 'extra_income' => 'in',
        'transfer' => 'transfer',
        _ => r.amount < 0 ? 'out' : 'in',
      };
      if (r.type == 'expense') expense += r.amount;
      if (r.type == 'salary' || r.type == 'extra_income') income += r.amount;
      b.writeln([
        r.date, r.month, direction, r.type, r.category ?? '', r.note ?? '', r.account ?? '', r.via ?? '', r.toAccount ?? '', rupees(r.amount),
      ].map(_cell).join(','));
    }
    b
      ..writeln()
      ..writeln(['total_income_inr', rupees(income)].join(','))
      ..writeln(['total_expense_inr', rupees(expense)].join(','))
      ..writeln(['net_inr', rupees(income - expense)].join(','));
    return b.toString();
  }

  static String rupees(int paise) {
    final neg = paise < 0;
    final a = paise.abs();
    return '${neg ? '-' : ''}${a ~/ 100}.${(a % 100).toString().padLeft(2, '0')}';
  }

  /// RFC 4180 quoting; also neutralises spreadsheet formula injection (=, +, -, @).
  static String _cell(Object? v) {
    var s = v?.toString() ?? '';
    if (s.isNotEmpty && '=+-@'.contains(s[0]) && !RegExp(r'^-?\d+(\.\d+)?$').hasMatch(s)) s = "'$s";
    if (s.contains(',') || s.contains('"') || s.contains('\n')) s = '"${s.replaceAll('"', '""')}"';
    return s;
  }
}
