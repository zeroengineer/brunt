import '../../core/dates.dart';

/// Credit card cycle helpers (spec §4.10).
abstract final class CardCycle {
  /// Most recent statement date on or before [today].
  static DateTime lastStatementDate(DateTime today, int statementDay) {
    final t = Dates.day(today);
    final thisMonth = Dates.clampDay(t.year, t.month, statementDay);
    if (!thisMonth.isAfter(t)) return thisMonth;
    final prev = DateTime(t.year, t.month - 1); // DateTime normalises month 0 → December
    return Dates.clampDay(prev.year, prev.month, statementDay);
  }

  /// Due date for a statement generated on [statement]: the next occurrence of [dueDay]
  /// strictly after the statement date.
  static DateTime dueDateFor(DateTime statement, int dueDay) {
    final same = Dates.clampDay(statement.year, statement.month, dueDay);
    if (same.isAfter(statement)) return same;
    final next = DateTime(statement.year, statement.month + 1);
    return Dates.clampDay(next.year, next.month, dueDay);
  }

  /// Next statement date strictly after [today].
  static DateTime nextStatementDate(DateTime today, int statementDay) {
    final t = Dates.day(today);
    final thisMonth = Dates.clampDay(t.year, t.month, statementDay);
    if (thisMonth.isAfter(t)) return thisMonth;
    final n = DateTime(t.year, t.month + 1);
    return Dates.clampDay(n.year, n.month, statementDay);
  }
}
