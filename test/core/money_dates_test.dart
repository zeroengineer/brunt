import 'package:brunt/core/dates.dart';
import 'package:brunt/core/money.dart';
import 'package:brunt/domain/cards/card_cycle.dart';
import 'package:brunt/domain/rollover/month_rollover.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('formats with Indian grouping', () {
      expect(Money.format(123456789), '₹12,34,567.89');
      expect(Money.format(4000), '₹40');
      expect(Money.format(4050), '₹40.50');
      expect(Money.format(-150000), '−₹1,500');
      expect(Money.format(100000000), '₹10,00,000');
      expect(Money.format(0), '₹0');
    });
    test('parses without floating point', () {
      expect(Money.parse('40.5'), 4050);
      expect(Money.parse('₹1,250.05'), 125005);
      expect(Money.parse('0.1'), 10);
      expect(Money.parse('abc'), isNull);
      expect(Money.parse(''), isNull);
      expect(Money.parse('1.234'), isNull);
    });
    test('compact', () {
      expect(Money.compact(15000000), '₹1.5L');
      expect(Money.compact(4530000), '₹45.3K');
      expect(Money.compact(98000), '₹980');
    });
    test('median & rounding', () {
      expect(Money.median([3, 1, 2]), 2);
      expect(Money.median([1, 2, 3, 4]), 3);
      expect(Money.divRound(10, 4), 3);
      expect(Money.median([]), 0);
    });
  });

  group('Dates', () {
    test('days in month: 28/29/30/31', () {
      expect(Dates.daysInMonth(2027, 2), 28);
      expect(Dates.daysInMonth(2028, 2), 29);
      expect(Dates.daysInMonth(2026, 11), 30);
      expect(Dates.daysInMonth(2026, 12), 31);
    });
    test('year-month arithmetic over year boundary', () {
      expect(Dates.nextYearMonth('2026-12'), '2027-01');
      expect(Dates.prevYearMonth('2027-01'), '2026-12');
    });
    test('week mask (Mon=1 … Sun=64)', () {
      expect(WeekMask.bit(DateTime.monday), 1);
      expect(WeekMask.bit(DateTime.sunday), 64);
      expect(WeekMask.has(WeekMask.all, DateTime.sunday), isTrue);
      expect(WeekMask.has(WeekMask.toggle(WeekMask.all, 7), 7), isFalse);
      expect(WeekMask.describe(WeekMask.weekdays), 'Mon–Fri');
      expect(WeekMask.describe(63), 'Mon–Sat');
      expect(WeekMask.describe(1 | 4 | 16), 'Mon, Wed, Fri');
    });
    test('ordinals', () {
      expect(Dates.ordinal(1), '1st');
      expect(Dates.ordinal(12), '12th');
      expect(Dates.ordinal(23), '23rd');
    });
  });

  group('Rollover & card cycle', () {
    test('months to create', () {
      expect(MonthRollover.monthsToCreate('2026-11', '2026-11'), isEmpty);
      expect(MonthRollover.monthsToCreate('2026-11', '2027-01'), ['2026-12', '2027-01']);
      expect(MonthRollover.monthsToCreate(null, '2026-11'), ['2026-11']);
    });
    test('statement and due dates', () {
      expect(CardCycle.lastStatementDate(DateTime(2026, 11, 7), 5), DateTime(2026, 11, 5));
      expect(CardCycle.lastStatementDate(DateTime(2026, 11, 3), 5), DateTime(2026, 10, 5));
      expect(CardCycle.lastStatementDate(DateTime(2027, 1, 3), 20), DateTime(2026, 12, 20));
      expect(CardCycle.dueDateFor(DateTime(2026, 11, 5), 25), DateTime(2026, 11, 25));
      expect(CardCycle.dueDateFor(DateTime(2026, 11, 20), 8), DateTime(2026, 12, 8));
      expect(CardCycle.lastStatementDate(DateTime(2027, 2, 28), 31), DateTime(2027, 2, 28));
    });
  });
}
