import '../../core/constants.dart';
import '../../core/dates.dart';

/// Minimal template view for the expander (decoupled from drift rows).
class TemplateSpec {
  const TemplateSpec({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.amount,
    required this.frequency,
    this.daysOfWeek = WeekMask.all,
    this.dueDay,
    this.startMonth,
    this.endMonth,
    this.active = true,
    this.accountId,
  });

  final int id;
  final String name;
  final int categoryId;
  final int amount;
  final Frequency frequency;
  final int daysOfWeek;
  final int? dueDay;
  final String? startMonth;
  final String? endMonth;
  final bool active;
  final int? accountId;

  /// Active in the month [ym] (respecting start/end months and pause).
  bool activeIn(String ym) {
    if (!active) return false;
    if (startMonth != null && ym.compareTo(startMonth!) < 0) return false;
    if (endMonth != null && ym.compareTo(endMonth!) > 0) return false;
    if (frequency == Frequency.oneTime) return startMonth == null || startMonth == ym;
    return true;
  }
}

class PlannedSpec {
  const PlannedSpec({required this.templateId, required this.categoryId, required this.name, required this.amount, this.dueDate});
  final int templateId;
  final int categoryId;
  final String name;
  final int amount;
  final DateTime? dueDate;
}

abstract final class ScheduleExpander {
  /// Planned items for a month from monthly and one-time templates. Daily templates are
  /// not planned items — they are logged per day.
  static List<PlannedSpec> plannedForMonth(Iterable<TemplateSpec> templates, String ym) {
    final first = Dates.firstOfYearMonth(ym);
    return [
      for (final t in templates)
        if (t.frequency != Frequency.daily && t.activeIn(ym))
          PlannedSpec(
            templateId: t.id,
            categoryId: t.categoryId,
            name: t.name,
            amount: t.amount,
            dueDate: t.dueDay == null ? null : Dates.clampDay(first.year, first.month, t.dueDay!),
          ),
    ];
  }

  /// Each date in [from]..[to] on which a daily template occurs.
  static Iterable<DateTime> dailyOccurrences(TemplateSpec t, DateTime from, DateTime to) sync* {
    if (t.frequency != Frequency.daily) return;
    for (final d in Dates.range(from, to)) {
      if (t.activeIn(Dates.yearMonth(d)) && WeekMask.activeOn(t.daysOfWeek, d)) yield d;
    }
  }

  /// Total planned daily spend for a template across a month.
  static int dailyMonthTotal(TemplateSpec t, String ym, {int? amount}) {
    final first = Dates.firstOfYearMonth(ym);
    final n = dailyOccurrences(t, first, Dates.lastOfMonth(first)).length;
    return n * (amount ?? t.amount);
  }
}
