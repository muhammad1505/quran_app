import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:quran_app/core/services/background_service.dart';
import 'core/theme/app_theme.dart';
import 'core/settings/theme_settings.dart';
import 'core/settings/quran_settings.dart';
import 'core/services/prayer_notification_service.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'package:quran_app/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';
  await AndroidAlarmManager.initialize();

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
  
  await BackgroundService.init();

  runApp(const QuranApp());
}

class QuranApp extends StatefulWidget {
  const QuranApp({super.key});

  @override
  State<QuranApp> createState() => _QuranAppState();
}

class _QuranAppState extends State<QuranApp> {
  final ThemeSettingsController _themeSettings = getIt<ThemeSettingsController>();
  final _receivePort = ReceivePort();

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(
      _receivePort.sendPort,
      isolateName,
    );
    _receivePort.listen((_) async {
      // you can call any function here, almost any
    });
  }

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
