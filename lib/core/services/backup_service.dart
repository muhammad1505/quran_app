import 'package:adhan/adhan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/core/di/injection.dart';
import 'package:quran_app/core/services/prayer_notification_service.dart';
import 'package:quran_app/core/settings/audio_settings.dart';
import 'package:quran_app/core/settings/prayer_settings.dart';
import 'package:quran_app/core/settings/quran_settings.dart';
import 'package:quran_app/core/settings/theme_settings.dart';

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  static const List<String> _prefsKeys = [
    'onboarding_done',
    'notifications',
    'manual_location_enabled',
    'manual_location_name',
    'last_lat',
    'last_lng',
    'last_location_name',
    'last_read_surah',
    'last_read_ayah',
    'last_read_at',
    'translation',
    'show_latin',
    'show_tajwid',
    'show_word_by_word',
    'arabic_font_size',
    'translation_font_size',
    'arabic_line_height',
    'translation_line_height',
    'arabic_font_family',
    'tafsir_source',
    'prayer_method',
    'prayer_madhab',
    'prayer_correction_minutes',
    'notify_fajr',
    'notify_dhuhr',
    'notify_asr',
    'notify_maghrib',
    'notify_isha',
    'prayer_silent_mode',
    'prayer_adzan_sound',
    'qari',
    'volume',
    'audio_speed',
    'audio_repeat_one',
    'audio_auto_next',
    'app_theme_mode',
    'bookmarks',
    'bookmark_folders',
    'doa_favorites',
  ];

  static const Set<String> _intKeys = {
    'last_read_surah',
    'last_read_ayah',
    'prayer_correction_minutes',
  };

  Future<void> backupNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Silakan login terlebih dahulu.');
    }
    final prefsMap = await _collectPrefs();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('backups')
        .doc('latest')
        .set(
      {
        'updatedAt': FieldValue.serverTimestamp(),
        'prefs': prefsMap,
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> restoreLatest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Silakan login terlebih dahulu.');
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('backups')
        .doc('latest')
        .get();
    if (!snapshot.exists) return false;
    final data = snapshot.data();
    final prefsData = data?['prefs'];
    if (prefsData is! Map) return false;
    await _restorePrefs(Map<String, dynamic>.from(prefsData));
    await _refreshControllers();
    await _rescheduleNotificationsIfNeeded();
    return true;
  }

  Future<Map<String, dynamic>> _collectPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final key in _prefsKeys) {
      if (!prefs.containsKey(key)) continue;
      final value = prefs.get(key);
      if (value == null) continue;
      map[key] = value;
    }
    return map;
  }

  Future<void> _restorePrefs(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in data.entries) {
      final key = entry.key;
      if (!_prefsKeys.contains(key)) continue;
      final value = entry.value;
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is num) {
        if (_intKeys.contains(key)) {
          await prefs.setInt(key, value.toInt());
        } else {
          await prefs.setDouble(key, value.toDouble());
        }
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List) {
        await prefs.setStringList(
          key,
          value.map((e) => e.toString()).toList(),
        );
      }
    }
  }

  Future<void> _refreshControllers() async {
    await getIt<QuranSettingsController>().load();
    await AudioSettingsController.instance.load();
    await PrayerSettingsController.instance.load();
    await getIt<ThemeSettingsController>().load();
  }

  Future<void> _rescheduleNotificationsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications') ?? true;
    if (!enabled) return;
    final lat = prefs.getDouble('last_lat');
    final lng = prefs.getDouble('last_lng');
    if (lat == null || lng == null) return;
    final settings = PrayerSettingsController.instance.value;
    final params = PrayerSettingsController.instance.buildParameters();
    final coordinates = Coordinates(lat, lng);
    final now = DateTime.now();
    final today = PrayerTimes.today(coordinates, params);
    final tomorrow = PrayerTimes(
      coordinates,
      DateComponents.from(now.add(const Duration(days: 1))),
      params,
    );
    await getIt<PrayerNotificationService>().schedulePrayerTimes(
      today,
      tomorrow,
      settings,
    );
  }
}
