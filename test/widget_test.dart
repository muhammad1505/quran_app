import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuranApp());

    // Verify that Splash Screen is shown
    expect(find.byType(SplashScreen), findsOneWidget);

    // Wait for splash screen timer to finish (3 seconds) + transition
    // Use pump instead of pumpAndSettle to avoid timeout from infinite loading animations
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(); // Allow navigation to complete

    // Verify that we are now at DashboardScreen
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
