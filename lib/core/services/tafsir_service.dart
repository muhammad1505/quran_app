import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class TafsirService {
  TafsirService._();

  static final TafsirService instance = TafsirService._();
  Map<String, String>? _cache;

  Future<Map<String, String>> _loadCache() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString('assets/tafsir_id.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _cache = decoded.map((key, value) => MapEntry(key, value.toString()));
      return _cache!;
    } catch (_) {
      _cache = {};
      return _cache!;
    }
  }

  Future<String?> getTafsir(int surah, int ayah) async {
    final cache = await _loadCache();
    return cache['$surah:$ayah'];
  }
}
