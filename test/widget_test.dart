import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuranApp());

    // Verify that Splash Screen is shown
    expect(find.byType(SplashScreen), findsOneWidget);

    // Wait for splash screen timer to finish (3 seconds) + transition
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify that we are now at DashboardScreen
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
