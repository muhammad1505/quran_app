import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AudioQari {
  final String id;
  final String label;
  final String audioSlug;

  const AudioQari({
    required this.id,
    required this.label,
    required this.audioSlug,
  });
}

class AudioCacheService {
  AudioCacheService._();

  static final AudioCacheService instance = AudioCacheService._();

  static const List<AudioQari> qaris = [
    AudioQari(
      id: 'alafasy',
      label: 'Mishary Rashid Alafasy',
      audioSlug: 'ar.alafasy',
    ),
    AudioQari(
      id: 'abdulbasit',
      label: 'Abdul Basit (Murattal)',
      audioSlug: 'ar.abdulbasitmurattal',
    ),
    AudioQari(
      id: 'basfar',
      label: 'Abdullah Basfar',
      audioSlug: 'ar.abdullahbasfar',
    ),
  ];

  AudioQari qariById(String id) {
    return qaris.firstWhere(
      (qari) => qari.id == id,
      orElse: () => qaris.first,
    );
  }

  String surahUrl(int surahNumber, String qariId) {
    final qari = qariById(qariId);
    return
        'https://cdn.islamic.network/quran/audio-surah/128/${qari.audioSlug}/$surahNumber.mp3';
  }

  Future<File?> getLocalSurahFile(int surahNumber, String qariId) async {
    final file = await _surahFile(surahNumber, qariId);
    return file.existsSync() ? file : null;
  }

  Future<bool> isSurahDownloaded(int surahNumber, String qariId) async {
    final file = await _surahFile(surahNumber, qariId);
    return file.existsSync();
  }

  Future<File> downloadSurah(int surahNumber, String qariId) async {
    final file = await _surahFile(surahNumber, qariId);
    if (file.existsSync()) {
      return file;
    }
    final url = surahUrl(surahNumber, qariId);
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('Gagal mengunduh audio', uri: Uri.parse(url));
    }
    await file.parent.create(recursive: true);
    final sink = file.openWrite();
    await response.pipe(sink);
    await sink.close();
    return file;
  }

  Future<void> deleteSurah(int surahNumber, String qariId) async {
    final file = await _surahFile(surahNumber, qariId);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<File> _surahFile(int surahNumber, String qariId) async {
    final dir = await getApplicationDocumentsDirectory();
    final qari = qariById(qariId);
    final path =
        '${dir.path}/audio/${qari.audioSlug}/surah_${surahNumber.toString().padLeft(3, '0')}.mp3';
    return File(path);
  }
}
