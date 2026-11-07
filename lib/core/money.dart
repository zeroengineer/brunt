/// Money helpers. All amounts are integer **paise** (₹40.50 → 4050). Never floats.
library;

typedef Paise = int;

abstract final class Money {
  /// Formats paise as rupees with Indian digit grouping: 123456789 → "₹12,34,567.89".
  /// Paise are dropped when zero unless [showPaise] is true.
  static String format(Paise paise, {bool symbol = true, bool showPaise = false, bool signed = false}) {
    final negative = paise < 0;
    final abs = paise.abs();
    final rupees = abs ~/ 100;
    final p = abs % 100;
    final grouped = groupIndian(rupees);
    final frac = (p != 0 || showPaise) ? '.${p.toString().padLeft(2, '0')}' : '';
    final sign = negative ? '−' : (signed && paise > 0 ? '+' : '');
    return '$sign${symbol ? '₹' : ''}$grouped$frac';
  }

  /// Compact form for tight spaces: ₹1.2L, ₹45.3K, ₹980.
  static String compact(Paise paise) {
    final negative = paise < 0;
    final r = paise.abs() / 100;
    String body;
    if (r >= 10000000) {
      body = '${_trim(r / 10000000)}Cr';
    } else if (r >= 100000) {
      body = '${_trim(r / 100000)}L';
    } else if (r >= 1000) {
      body = '${_trim(r / 1000)}K';
    } else {
      body = r.round().toString();
    }
    return '${negative ? '−' : ''}₹$body';
  }

  static String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  /// 1234567 → "12,34,567".
  static String groupIndian(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  /// Parses user input like "1,250.5", "₹40", "40.05" into paise. Returns null when invalid.
  /// Uses string arithmetic only (no floating point).
  static Paise? parse(String input) {
    var s = input.trim().replaceAll(',', '').replaceAll('₹', '').replaceAll(' ', '');
    if (s.isEmpty) return null;
    var negative = false;
    if (s.startsWith('-') || s.startsWith('−')) {
      negative = true;
      s = s.substring(1);
    }
    final m = RegExp(r'^(\d*)(?:\.(\d{0,2}))?$').firstMatch(s);
    if (m == null) return null;
    final whole = m.group(1) ?? '';
    final frac = m.group(2) ?? '';
    if (whole.isEmpty && frac.isEmpty) return null;
    if (whole.length > 13) return null;
    final rupees = whole.isEmpty ? 0 : int.parse(whole);
    final paise = frac.isEmpty ? 0 : int.parse(frac.padRight(2, '0'));
    final v = rupees * 100 + paise;
    return negative ? -v : v;
  }

  /// Rupees (whole) → paise.
  static Paise rupees(int r) => r * 100;

  /// Integer division with rounding half up, for averages of paise.
  static Paise divRound(int total, int count) {
    if (count == 0) return 0;
    final q = total ~/ count;
    final r = total.remainder(count).abs() * 2;
    if (r >= count) return total >= 0 ? q + 1 : q - 1;
    return q;
  }

  /// Median of a list of paise values (rounded). Empty → 0.
  static Paise median(List<int> values) {
    if (values.isEmpty) return 0;
    final v = [...values]..sort();
    final mid = v.length ~/ 2;
    if (v.length.isOdd) return v[mid];
    return divRound(v[mid - 1] + v[mid], 2);
  }

  /// Percentage of [value] (paise) with integer maths: pct(100000, 10) → 10000.
  static Paise percent(Paise value, int pct) => value * pct ~/ 100;
}
