import 'dart:convert';

import 'package:flutter/services.dart';

class WordByWordItem {
  final String arabic;
  final String transliteration;
  final String translationEn;

  const WordByWordItem({
    required this.arabic,
    required this.transliteration,
    required this.translationEn,
  });
}

class WordByWordService {
  WordByWordService._();

  static final WordByWordService instance = WordByWordService._();

  Future<Map<String, List<WordByWordItem>>>? _loadFuture;
  Map<String, List<WordByWordItem>>? _cache;

  Future<List<WordByWordItem>> wordsFor(int chapter, int verse) async {
    final data = await _load();
    return data['$chapter:$verse'] ?? const [];
  }

  Future<Map<String, List<WordByWordItem>>> _load() {
    if (_cache != null) {
      return Future.value(_cache);
    }
    _loadFuture ??= _loadFromAssets();
    return _loadFuture!;
  }

  Future<Map<String, List<WordByWordItem>>> _loadFromAssets() async {
    final jsonString = await rootBundle.loadString('assets/word_by_word.json');
    final pages = jsonDecode(jsonString) as List<dynamic>;
    final Map<String, List<WordByWordItem>> result = {};

    var currentSurah = 1;
    for (final page in pages) {
      final ayahs = (page as Map<String, dynamic>)['ayahs'] as List<dynamic>;
      for (final entry in ayahs) {
        final entryMap = entry as Map<String, dynamic>;
        final metaData = (entryMap['metaData'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};
        if (metaData['sura'] != null) {
          final suraValue = metaData['sura'];
          if (suraValue is int) {
            currentSurah = suraValue;
          } else {
            final parsed = int.tryParse(suraValue.toString());
            if (parsed != null) {
              currentSurah = parsed;
            }
          }
        }
        final words = entryMap['words'] as List<dynamic>;
        for (final rawWord in words) {
          final word = rawWord as Map<String, dynamic>;
          if (word['type'] != 'word') {
            continue;
          }
          final ayahValue = word['ayah'];
          final ayah = ayahValue is int
              ? ayahValue
              : int.tryParse(ayahValue.toString()) ?? 0;
          if (ayah == 0) {
            continue;
          }
          final key = '$currentSurah:$ayah';
          final item = WordByWordItem(
            arabic: (word['uth'] as String?) ?? '',
            transliteration: (word['lit'] as String?) ?? '',
            translationEn: (word['trn'] as String?) ?? '',
          );
          result.putIfAbsent(key, () => []).add(item);
        }
      }
    }

    _cache = result;
    return result;
  }
}
