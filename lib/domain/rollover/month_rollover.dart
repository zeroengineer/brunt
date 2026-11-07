import '../../core/dates.dart';

/// Pure month-rollover planning. The data layer executes it idempotently on app open.
abstract final class MonthRollover {
  /// Months that must be created to reach [currentYm], in order, given the latest existing
  /// month (null when there are none). Handles gaps (app not opened for months) and
  /// returns an empty list if [latestYm] is already current (idempotent).
  static List<String> monthsToCreate(String? latestYm, String currentYm) {
    if (latestYm == null) return [currentYm];
    final out = <String>[];
    var ym = latestYm;
    while (ym.compareTo(currentYm) < 0) {
      ym = Dates.nextYearMonth(ym);
      out.add(ym);
    }
    return out;
  }

  /// Closing balance of an account = opening + every balance delta booked in the month.
  static int closing(int opening, Iterable<int> deltas) => deltas.fold(opening, (a, b) => a + b);
}
