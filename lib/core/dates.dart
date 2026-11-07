/// Date helpers. Dates are stored as ISO strings 'yyyy-MM-dd'; months as 'yyyy-MM'.
library;

abstract final class Dates {
  static const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  /// Strips the time part.
  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime parseIso(String s) {
    final p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static String yearMonth(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  static DateTime firstOfYearMonth(String ym) {
    final p = ym.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]));
  }

  static String nextYearMonth(String ym) {
    final f = firstOfYearMonth(ym);
    return yearMonth(DateTime(f.year, f.month + 1));
  }

  static String prevYearMonth(String ym) {
    final f = firstOfYearMonth(ym);
    return yearMonth(DateTime(f.year, f.month - 1));
  }

  /// Number of days in the month of [d] — real calendar (28/29/30/31).
  static int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  static DateTime lastOfMonth(DateTime d) => DateTime(d.year, d.month, daysInMonth(d.year, d.month));

  /// Clamp a due day (e.g. 31) to the month's real length.
  static DateTime clampDay(int year, int month, int day) {
    final dim = daysInMonth(year, month);
    return DateTime(year, month, day < 1 ? 1 : (day > dim ? dim : day));
  }

  /// "November 2026"
  static String monthLabel(String ym) {
    final f = firstOfYearMonth(ym);
    return '${monthNames[f.month - 1]} ${f.year}';
  }

  /// "7 Nov"
  static String short(DateTime d) => '${d.day} ${monthShort[d.month - 1]}';

  /// "1st", "2nd", "23rd"
  static String ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    return switch (n % 10) { 1 => '${n}st', 2 => '${n}nd', 3 => '${n}rd', _ => '${n}th' };
  }

  /// Iterates every day from [from] to [to] inclusive.
  static Iterable<DateTime> range(DateTime from, DateTime to) sync* {
    var d = day(from);
    final end = day(to);
    while (!d.isAfter(end)) {
      yield d;
      d = DateTime(d.year, d.month, d.day + 1);
    }
  }
}

/// Days-of-week bitmask: Mon=1, Tue=2, Wed=4, Thu=8, Fri=16, Sat=32, Sun=64. 127 = every day.
abstract final class WeekMask {
  static const all = 127;
  static const weekdays = 31;

  /// Bit for a Dart weekday (DateTime.monday = 1 … DateTime.sunday = 7).
  static int bit(int weekday) => 1 << (weekday - 1);

  static bool has(int mask, int weekday) => mask & bit(weekday) != 0;

  static bool activeOn(int mask, DateTime d) => has(mask, d.weekday);

  static int toggle(int mask, int weekday) => mask ^ bit(weekday);

  static String describe(int mask) {
    if (mask == all) return 'Every day';
    if (mask == weekdays) return 'Mon–Fri';
    if (mask == 0) return 'No days';
    final days = [for (var w = 1; w <= 7; w++) if (has(mask, w)) w];
    // one contiguous run (e.g. Mon–Sat) reads better as a range
    if (days.length >= 3 && days.last - days.first == days.length - 1) {
      return '${Dates.weekdayShort[days.first - 1]}–${Dates.weekdayShort[days.last - 1]}';
    }
    return days.map((w) => Dates.weekdayShort[w - 1]).join(', ');
  }
}
