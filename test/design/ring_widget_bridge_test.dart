import 'package:brunt/features/dashboard/dashboard_data.dart';
import 'package:brunt/features/dashboard/ring_widget_bridge.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('widget gets shares and colours only, never amounts', () {
    const parts = [
      RingPart('Savings', Color(0xFF7AAEEE), 500000, 0),
      RingPart('Reserve', Color(0xFF7AAEEE), 0, 0),
      RingPart('Daily', Color(0xFFF5F5F5), 1500000, 0),
    ];
    final s = RingWidgetBridge.encode(parts);
    expect(s, '250:${0xFF7AAEEE},750:${0xFFF5F5F5}');
    expect(s.contains('500000'), isFalse);
    expect(RingWidgetBridge.encode(const []), '');
  });
}
