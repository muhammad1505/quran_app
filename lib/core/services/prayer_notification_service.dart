import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:quran_app/core/settings/prayer_settings.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PrayerNotificationService {
  PrayerNotificationService._();

  static final PrayerNotificationService instance =
      PrayerNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(settings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    final ios = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> scheduleTestNotification() async {
    await initialize();
    await requestPermissions();
    final scheduled =
        tz.TZDateTime.from(DateTime.now().add(const Duration(seconds: 5)), tz.local);
    const androidDetails = AndroidNotificationDetails(
      'prayer_test',
      'Test Notifikasi',
      channelDescription: 'Uji notifikasi adzan',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.zonedSchedule(
      2998,
      'Test Notifikasi Adzan',
      'Jika kamu melihat ini, notifikasi berhasil.',
      scheduled,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> schedulePrayerTimes(
    PrayerTimes today,
    PrayerTimes tomorrow,
    PrayerSettings settings,
  ) async {
    await initialize();
    await requestPermissions();
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

    for (final entry in prayers.entries) {
      final prayer = entry.key;
      if (!settings.isNotificationEnabled(prayer)) {
        continue;
      }
      var time = entry.value;
      if (time.isBefore(now)) {
        time = prayersTomorrow[prayer]!;
      }
      await _scheduleNotification(prayer, time.add(offset), settings);
    }
  }

  Future<void> _scheduleNotification(
    Prayer prayer,
    DateTime time,
    PrayerSettings settings,
  ) async {
    final id = _notificationId(prayer);
    final title = 'Waktu ${_prayerName(prayer)}';
    final body = 'Saatnya sholat ${_prayerName(prayer)}';
    final scheduled = tz.TZDateTime.from(time, tz.local);

    final androidDetails = AndroidNotificationDetails(
      'prayer_times',
      'Jadwal Sholat',
      channelDescription: 'Pengingat waktu sholat harian',
      importance: Importance.high,
      priority: Priority.high,
      playSound: !settings.silentMode,
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: !settings.silentMode,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

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
