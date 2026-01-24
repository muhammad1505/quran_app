import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

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

  Future<TafsirCacheInfo> getCacheInfo(TafsirSource source) async {
    final dir = await _cacheDir(source);
    if (!dir.existsSync()) {
      return const TafsirCacheInfo(count: 0, bytes: 0);
    }
    var count = 0;
    var bytes = 0;
    for (final entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith('.json')) {
        count += 1;
        bytes += await entity.length();
      }
    }
    return TafsirCacheInfo(count: count, bytes: bytes);
  }

  Future<void> clearCache(TafsirSource source) async {
    final dir = await _cacheDir(source);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> downloadSurah(TafsirSource source, int surah) async {
    final map = await _fetchBySource(source, surah);
    await _saveCacheFile(source, surah, map);
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
    final cached = await _loadCachedSource(source, surah);
    final cachedEntry = cached['$surah:$ayah'];
    if (cachedEntry != null) {
      return cachedEntry;
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

  Future<Map<String, TafsirEntry>> _fetchBySource(
    TafsirSource source,
    int surah,
  ) {
    switch (source) {
      case TafsirSource.equran:
        return _fetchEquran(surah);
      case TafsirSource.gading:
        return _fetchGading(surah);
      case TafsirSource.kemenag:
        return Future.value({});
    }
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

  Future<Directory> _cacheDir(TafsirSource source) async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/tafsir/${source.name}');
  }

  Future<Map<String, TafsirEntry>> _loadCachedSource(
    TafsirSource source,
    int surah,
  ) async {
    final file = await _cacheFile(source, surah);
    if (!file.existsSync()) return {};
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, TafsirEntry>{};
      decoded.forEach((key, value) {
        final entry = value as Map<String, dynamic>;
        result[key] = TafsirEntry(
          short: entry['short']?.toString(),
          long: entry['long']?.toString(),
          sourceLabel: _sourceLabel(source),
          offline: true,
        );
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveCacheFile(
    TafsirSource source,
    int surah,
    Map<String, TafsirEntry> entries,
  ) async {
    final file = await _cacheFile(source, surah);
    await file.parent.create(recursive: true);
    final map = <String, dynamic>{};
    entries.forEach((key, value) {
      map[key] = {
        'short': value.short,
        'long': value.long,
      };
    });
    await file.writeAsString(jsonEncode(map));
  }

  Future<File> _cacheFile(TafsirSource source, int surah) async {
    final dir = await _cacheDir(source);
    return File('${dir.path}/surah_$surah.json');
  }

  String _sourceLabel(TafsirSource source) {
    switch (source) {
      case TafsirSource.equran:
        return 'EQuran.id (Tafsir Kemenag)';
      case TafsirSource.gading:
        return 'Quran Gading (Tafsir Kemenag)';
      case TafsirSource.kemenag:
        return 'Kemenag RI (API resmi)';
    }
  }
}

class TafsirCacheInfo {
  final int count;
  final int bytes;

  const TafsirCacheInfo({required this.count, required this.bytes});
}
