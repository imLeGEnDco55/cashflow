// Basic smoke test for CashFlow app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cashflow_flutter/main.dart';

void main() {
  testWidgets('CashFlow app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CashFlowApp());

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that the app title is displayed
    expect(find.text('CashFlow'), findsOneWidget);

    // Verify that bottom navigation exists
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
