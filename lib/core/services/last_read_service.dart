import 'package:shared_preferences/shared_preferences.dart';

class LastRead {
  final int surah;
  final int ayah;
  final DateTime updatedAt;

  const LastRead({
    required this.surah,
    required this.ayah,
    required this.updatedAt,
  });
}

class LastReadService {
  LastReadService._();

  static final LastReadService instance = LastReadService._();

  static const _surahKey = 'last_read_surah';
  static const _ayahKey = 'last_read_ayah';
  static const _updatedKey = 'last_read_at';

  Future<void> save({required int surah, required int ayah}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_surahKey, surah);
    await prefs.setInt(_ayahKey, ayah);
    await prefs.setString(_updatedKey, DateTime.now().toIso8601String());
  }

  Future<LastRead?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final surah = prefs.getInt(_surahKey);
    final ayah = prefs.getInt(_ayahKey);
    if (surah == null || ayah == null) return null;
    final updated = prefs.getString(_updatedKey);
    return LastRead(
      surah: surah,
      ayah: ayah,
      updatedAt: updated != null ? DateTime.parse(updated) : DateTime.now(),
    );
  }
}
