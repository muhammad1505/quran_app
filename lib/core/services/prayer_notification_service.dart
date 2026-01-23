import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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

  Future<void> schedulePrayerTimes(
    PrayerTimes today,
    PrayerTimes tomorrow,
  ) async {
    await initialize();
    await requestPermissions();
    await cancelAll();

    final now = DateTime.now();
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
      var time = entry.value;
      if (time.isBefore(now)) {
        time = prayersTomorrow[prayer]!;
      }
      await _scheduleNotification(prayer, time);
    }
  }

  Future<void> _scheduleNotification(Prayer prayer, DateTime time) async {
    final id = _notificationId(prayer);
    final title = 'Waktu ${_prayerName(prayer)}';
    final body = 'Saatnya sholat ${_prayerName(prayer)}';
    final scheduled = tz.TZDateTime.from(time, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'prayer_times',
      'Jadwal Sholat',
      channelDescription: 'Pengingat waktu sholat harian',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    const details = NotificationDetails(
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
