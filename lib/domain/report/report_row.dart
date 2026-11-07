/// One transaction as it appears in a report, with names already joined in.
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
