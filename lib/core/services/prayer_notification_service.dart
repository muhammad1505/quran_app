import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran_app/core/settings/prayer_settings.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@lazySingleton
class PrayerNotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.toString()));
      debugPrint('Timezone initialized: $timezoneInfo');
    } catch (e) {
      debugPrint('Timezone init failed: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final notification = await _ensureNotificationPermission();
    final alarm = await _ensureAlarmPermission();
    return notification && alarm;
  }

  Future<bool> _ensureNotificationPermission() async {
    if (kIsWeb) return false;
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  Future<bool> _ensureAlarmPermission() async {
    if (kIsWeb) return true;
    // Android 12+ (API 31+) requires SCHEDULE_EXACT_ALARM
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return true;

    if (await Permission.scheduleExactAlarm.isDenied) {
      final result = await Permission.scheduleExactAlarm.request();
      return result.isGranted;
    }
    
    // If status is restricted or permanently denied, we can't do much.
    // On older Android, it might be granted by default. 
    // The current status is the source of truth if we can't request.
    return status.isGranted;
  }

  Future<bool> _scheduleZonedWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduled,
    required NotificationDetails details,
  }) async {
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return true;
    } catch (error) {
      debugPrint('Exact schedule failed: $error');
    }

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } catch (error) {
      debugPrint('Inexact schedule failed: $error');
    }
    return false;
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<bool> scheduleTestNotification() async {
    await initialize();
    final permissionGranted = await _ensureNotificationPermission();
    if (!permissionGranted) return false;
    final scheduled =
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    const androidDetails = AndroidNotificationDetails(
      'prayer_test',
      'Test Notifikasi',
      channelDescription: 'Uji notifikasi adzan',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    final success = await _scheduleZonedWithFallback(
      id: 2998,
      title: 'Test Notifikasi Adzan',
      body: 'Jika kamu melihat ini, notifikasi berhasil.',
      scheduled: scheduled,
      details: details,
    );
    if (!success) {
      await _notifications.show(
        2998,
        'Test Notifikasi Adzan',
        'Jika kamu melihat ini, notifikasi berhasil.',
        details,
      );
    }
    return true;
  }

  Future<bool> schedulePrayerTimes(
    PrayerTimes today,
    PrayerTimes tomorrow,
    PrayerSettings settings,
  ) async {
    await initialize();
    final permissionGranted = await _ensureNotificationPermission();
    if (!permissionGranted) {
      debugPrint('Notification permission not granted, cannot schedule prayer times.');
      return false;
    }
    await cancelAll();

    final now = DateTime.now();
    final offset = Duration(minutes: settings.correctionMinutes);
    final prayers = <Prayer, DateTime>{
      Prayer.fajr: today.fajr,
      Prayer.dhuhr: today.dhuhr,
      Prayer.asr: today.asr,
      Prayer.maghrib: today.maghrib,
      Prayer.isha: today.isha,
    };
    final prayersTomorrow = <Prayer, DateTime>{
      Prayer.fajr: tomorrow.fajr,
      Prayer.dhuhr: tomorrow.dhuhr,
      Prayer.asr: tomorrow.asr,
      Prayer.maghrib: tomorrow.maghrib,
      Prayer.isha: tomorrow.isha,
    };

    bool allScheduledSuccessfully = true;
    for (final entry in prayers.entries) {
      final prayer = entry.key;
      if (!settings.isNotificationEnabled(prayer)) {
        continue;
      }
      var time = entry.value;
      if (time.isBefore(now)) {
        time = prayersTomorrow[prayer]!;
      }
      final success = await _scheduleNotification(prayer, time.add(offset), settings);
      if (!success) {
        allScheduledSuccessfully = false;
      }
    }
    return allScheduledSuccessfully;
  }

  Future<bool> _scheduleNotification(
    Prayer prayer,
    DateTime time,
    PrayerSettings settings,
  ) async {
    final id = _notificationId(prayer);
    final title = 'Waktu ${_prayerName(prayer)}';
    final body = 'Saatnya sholat ${_prayerName(prayer)}';
    final scheduled = tz.TZDateTime.from(time, tz.local);

    final details = _notificationDetails(settings, withSound: true);
    var success = await _scheduleZonedWithFallback(
      id: id,
      title: title,
      body: body,
      scheduled: scheduled,
      details: details,
    );
    if (success) return true;

    // Fallback for when sound fails
    if (settings.adzanSound != AdzanSound.defaultTone) {
      final fallbackDetails = _notificationDetails(settings, withSound: false);
      success = await _scheduleZonedWithFallback(
        id: id,
        title: title,
        body: body,
        scheduled: scheduled,
        details: fallbackDetails,
      );
      if (success) return true;
    }
    
    debugPrint('Failed to schedule notification for ${prayer.name}');
    return false;
  }

  NotificationDetails _notificationDetails(
    PrayerSettings settings, {
    required bool withSound,
  }) {
    final androidSound =
        withSound ? _androidSound(settings.adzanSound) : null;
    final androidDetails = AndroidNotificationDetails(
      'prayer_times',
      'Jadwal Sholat',
      channelDescription: 'Pengingat waktu sholat harian',
      importance: Importance.high,
      priority: Priority.high,
      playSound: !settings.silentMode,
      sound: settings.silentMode ? null : androidSound,
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: !settings.silentMode,
    );
    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  AndroidNotificationSound? _androidSound(AdzanSound sound) {
    switch (sound) {
      case AdzanSound.makkah:
        return const RawResourceAndroidNotificationSound('azan_makkah');
      case AdzanSound.madinah:
        return const RawResourceAndroidNotificationSound('azan_madinah');
      case AdzanSound.defaultTone:
        return null;
    }
  }

  int _notificationId(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 2001;
      case Prayer.dhuhr:
        return 2002;
      case Prayer.asr:
        return 2003;
      case Prayer.maghrib:
        return 2004;
      case Prayer.isha:
        return 2005;
      default:
        return 2999;
    }
  }

  String _prayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Subuh';
      case Prayer.dhuhr:
        return 'Dzuhur';
      case Prayer.asr:
        return 'Ashar';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isya';
      default:
        return 'Sholat';
    }
  }
}
