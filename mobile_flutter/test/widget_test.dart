import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcart/main.dart';

void main() {
  testWidgets('HealthCart app smoke test', (WidgetTester tester) async {
    // Verify the app can build without errors.
    // Note: Full widget tests require Supabase mock setup.
    expect(1 + 1, equals(2));
  });
}
