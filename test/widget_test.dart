import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/core/di/injection.dart';
import 'package:quran_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    await configureDependencies();
    // Disable network fetching for google_fonts
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
    });

    // All other mocks for method channels remain the same.
    const MethodChannel pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (MethodCall methodCall) async => '.',
    );

    const MethodChannel timezoneChannel = MethodChannel('flutter_timezone');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      timezoneChannel,
      (MethodCall methodCall) async =>
          methodCall.method == 'getLocalTimezone' ? 'Asia/Jakarta' : null,
    );

    const MethodChannel notificationChannel =
        MethodChannel('dexterous.com/flutter/local_notifications');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        notificationChannel, (MethodCall methodCall) async => null);

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

    const MethodChannel permissionChannel =
        MethodChannel('flutter.baseflow.com/permissions/methods');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      permissionChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermissionStatus') {
          return 1; // PermissionStatus.granted
        }
        if (methodCall.method == 'requestPermissions') {
          return {3: 1}; // locationWhenInUse: granted
        }
        return null;
      },
    );

    const MethodChannel ttsChannel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      ttsChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getVoices':
            return [];
          default:
            return 1;
        }
      },
    );

    const MethodChannel shareChannel =
        MethodChannel('dev.fluttercommunity.plus/share');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        shareChannel, (MethodCall methodCall) async => null);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuranApp());

    // Verify that Splash Screen is shown
    expect(find.byType(SplashScreen), findsOneWidget);

    // Wait for splash screen timer to finish (2 seconds) + transition
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Verify that we are now at DashboardScreen
    expect(find.byType(DashboardScreen), findsOneWidget);

    // Dispose tree to stop periodic timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

