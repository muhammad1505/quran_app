import 'dart:isolate';
import 'dart:ui';

import 'package:adhan/adhan.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:quran_app/core/di/injection.dart';
import 'package:quran_app/core/services/prayer_notification_service.dart';
import 'package:quran_app/core/settings/prayer_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

const alarmId = 0;
const String isolateName = 'prayer-time-alarm';
SendPort? uiSendPort;

@pragma('vm:entry-point')
Future<void> scheduleAdzanNotification() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  final prayerNotificationService = getIt<PrayerNotificationService>();
  final prayerSettingsController = getIt<PrayerSettingsController>();
  await prayerSettingsController.load();
  final prayerSettings = prayerSettingsController.value;

  final prefs = await SharedPreferences.getInstance();
  final lat = prefs.getDouble('last_lat');
  final lng = prefs.getDouble('last_lng');

  if (lat != null && lng != null) {
    final coordinates = Coordinates(lat, lng);
    final params = prayerSettingsController.buildParameters();
    final today = PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now()),
      params,
    );
    final tomorrow = PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now().add(const Duration(days: 1))),
      params,
    );

    await prayerNotificationService.schedulePrayerTimes(
      today,
      tomorrow,
      prayerSettings,
    );
  }

  uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
  uiSendPort?.send(null);
}

class BackgroundService {
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isNotificationEnabled =
        prefs.getBool('notifications') ?? true;
    if (isNotificationEnabled) {
      await AndroidAlarmManager.periodic(
        const Duration(hours: 1),
        alarmId,
        scheduleAdzanNotification,
        exact: true,
        wakeup: true,
        startAt: DateTime.now(),
        rescheduleOnReboot: true,
      );
    }
  }

  static Future<void> cancel() async {
    await AndroidAlarmManager.cancel(alarmId);
  }
}

