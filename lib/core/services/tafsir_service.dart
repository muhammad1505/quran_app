import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import 'package:quran_app/core/settings/quran_settings.dart';

class TafsirEntry {
  final String? short;
  final String? long;
  final String sourceLabel;
  final bool offline;

  const TafsirEntry({
    required this.short,
    required this.long,
    required this.sourceLabel,
    required this.offline,
  });
}

class TafsirService {
  TafsirService._();

  static final TafsirService instance = TafsirService._();
  Map<String, String>? _offlineCache;
  final Map<String, Future<Map<String, TafsirEntry>>> _inFlight = {};
  final Map<String, Map<String, TafsirEntry>> _remoteCache = {};

  Future<Map<String, String>> _loadOffline() async {
    if (_offlineCache != null) return _offlineCache!;
    try {
      final raw = await rootBundle.loadString('assets/tafsir_id.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _offlineCache = decoded.map((key, value) => MapEntry(key, value.toString()));
      return _offlineCache!;
    } catch (_) {
      _offlineCache = {};
      return _offlineCache!;
    }
  }

  Future<bool> hasOfflineData() async {
    final cache = await _loadOffline();
    return cache.isNotEmpty;
  }

  Future<TafsirEntry?> getTafsir({
    required int surah,
    required int ayah,
    required TafsirSource source,
  }) async {
    final offline = await _loadOffline();
    final offlineText = offline['$surah:$ayah'];
    if (offlineText != null && offlineText.isNotEmpty) {
      return TafsirEntry(
        short: null,
        long: offlineText,
        sourceLabel: 'Tafsir offline (lokal)',
        offline: true,
      );
    }
    switch (source) {
      case TafsirSource.equran:
        return _fetchEquran(surah).then((map) => map['$surah:$ayah']);
      case TafsirSource.gading:
        return _fetchGading(surah).then((map) => map['$surah:$ayah']);
      case TafsirSource.kemenag:
        return null;
    }
  }

  Future<Map<String, TafsirEntry>> _fetchEquran(int surah) {
    return _fetchWithCache('equran_$surah', () async {
      final url = Uri.parse('https://equran.id/api/tafsir/$surah');
      final data = await _getJson(url) as Map<String, dynamic>;
      final tafsir = data['tafsir'] as List<dynamic>? ?? [];
      final result = <String, TafsirEntry>{};
      for (final item in tafsir) {
        final map = item as Map<String, dynamic>;
        final ayah = map['ayat'] as int? ?? 0;
        final text = map['tafsir']?.toString() ?? '';
        if (ayah > 0 && text.isNotEmpty) {
          result['$surah:$ayah'] = TafsirEntry(
            short: null,
            long: text,
            sourceLabel: 'EQuran.id (Tafsir Kemenag)',
            offline: false,
          );
        }
      }
      return result;
    });
  }

  Future<Map<String, TafsirEntry>> _fetchGading(int surah) {
    return _fetchWithCache('gading_$surah', () async {
      final url = Uri.parse('https://api.quran.gading.dev/surah/$surah');
      final data = await _getJson(url) as Map<String, dynamic>;
      final verses = (data['data']?['verses'] as List<dynamic>?) ?? [];
      final result = <String, TafsirEntry>{};
      for (final item in verses) {
        final map = item as Map<String, dynamic>;
        final ayah = map['number']?['inSurah'] as int? ?? 0;
        final tafsir = map['tafsir']?['id'] as Map<String, dynamic>?;
        if (ayah == 0 || tafsir == null) continue;
        final short = tafsir['short']?.toString();
        final long = tafsir['long']?.toString();
        if ((short ?? '').isEmpty && (long ?? '').isEmpty) continue;
        result['$surah:$ayah'] = TafsirEntry(
          short: short,
          long: long,
          sourceLabel: 'Quran Gading (Tafsir Kemenag)',
          offline: false,
        );
      }
      return result;
    });
  }

  Future<Map<String, TafsirEntry>> _fetchWithCache(
    String key,
    Future<Map<String, TafsirEntry>> Function() loader,
  ) {
    if (_remoteCache.containsKey(key)) {
      return Future.value(_remoteCache[key]!);
    }
    if (_inFlight.containsKey(key)) {
      return _inFlight[key]!;
    }
    final future = loader();
    _inFlight[key] = future;
    return future.then((value) {
      _remoteCache[key] = value;
      _inFlight.remove(key);
      return value;
    });
  }

  Future<dynamic> _getJson(Uri url) async {
    final client = HttpClient();
    final request = await client.getUrl(url);
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('Gagal memuat tafsir', uri: url);
    }
    final body = await response.transform(utf8.decoder).join();
    return jsonDecode(body);
  }
}
