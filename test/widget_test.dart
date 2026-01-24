import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
    });

    // Mock Flutter Timezone
    const MethodChannel timezoneChannel = MethodChannel('flutter_timezone');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      timezoneChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getLocalTimezone') {
          return 'Asia/Jakarta';
        }
        return null;
      },
    );

    // Mock Local Notifications
    const MethodChannel notificationChannel =
        MethodChannel('dexterous.com/flutter/local_notifications');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      notificationChannel,
      (MethodCall methodCall) async {
        return null;
      },
    );

    // Mock Geolocator
    const MethodChannel geolocatorChannel =
        MethodChannel('flutter.baseflow.com/geolocator');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      geolocatorChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getCurrentPosition') {
          return {
            'latitude': -6.2088,
            'longitude': 106.8456,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'accuracy': 10.0,
            'altitude': 0.0,
            'heading': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
            'is_mocked': true,
          };
        }
        return null;
      },
    );

    // Mock Permission Handler
    const MethodChannel permissionChannel =
        MethodChannel('flutter.baseflow.com/permissions/methods');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      permissionChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermissionStatus') {
          return 1; // PermissionStatus.granted
        }
        if (methodCall.method == 'requestPermissions') {
          // 3: Permission.locationWhenInUse, 1: PermissionStatus.granted
          return {
            3: 1, 
          };
        }
        return null;
      },
    );

    // Mock Flutter TTS
    const MethodChannel ttsChannel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      ttsChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getVoices':
            return [];
          case 'setLanguage':
          case 'setSpeechRate':
          case 'setPitch':
          case 'awaitSpeakCompletion':
          case 'speak':
          case 'stop':
            return 1;
          default:
            return null;
        }
      },
    );

    // Mock Share Plus
    const MethodChannel shareChannel =
        MethodChannel('dev.fluttercommunity.plus/share');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      shareChannel,
      (MethodCall methodCall) async {
        return null;
      },
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuranApp());

    // Verify that Splash Screen is shown
    expect(find.byType(SplashScreen), findsOneWidget);

    // Wait for splash screen timer to finish (2 seconds) + transition
    // Use pump instead of pumpAndSettle to avoid timeout from infinite loading animations
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(); // Allow navigation to complete

    // Verify that we are now at DashboardScreen
    expect(find.byType(DashboardScreen), findsOneWidget);

    // Dispose tree to stop periodic timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
