import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/settings/theme_settings.dart';
import 'core/settings/quran_settings.dart';
import 'core/services/prayer_notification_service.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'package:quran_app/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handling for production
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  await configureDependencies();
  await getIt<PrayerNotificationService>().initialize();
  await getIt<ThemeSettingsController>().load();
  await getIt<QuranSettingsController>().load();
  runApp(const QuranApp());
}

class QuranApp extends StatefulWidget {
  const QuranApp({super.key});

  @override
  State<QuranApp> createState() => _QuranAppState();
}

class _QuranAppState extends State<QuranApp> {
  final ThemeSettingsController _themeSettings = getIt<ThemeSettingsController>();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeSettings,
      builder: (context, _) {
        final mode = _themeSettings.value.mode;
        final ThemeMode themeMode = mode == AppThemeMode.dark
            ? ThemeMode.dark
            : ThemeMode.light;
        final ThemeData lightTheme =
            mode == AppThemeMode.sepia ? AppTheme.sepiaTheme : AppTheme.lightTheme;
        return MaterialApp(
          title: 'Al-Quran Terjemahan',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
