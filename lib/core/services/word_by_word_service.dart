import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import 'package:quran_app/core/settings/quran_settings.dart';

class WordByWordItem {
  final String arabic;
  final String transliteration;
  final String translation;

  const WordByWordItem({
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });
}

@lazySingleton
class WordByWordService {
  Future<Map<String, List<WordByWordItem>>>? _loadEnFuture;
  Future<Map<String, List<WordByWordItem>>>? _loadIdFuture;
  Map<String, List<WordByWordItem>>? _cacheEn;
  Map<String, List<WordByWordItem>>? _cacheId;

  Future<List<WordByWordItem>> wordsFor(
    int chapter,
    int verse, {
    required TranslationLanguage language,
  }) async {
    final key = '$chapter:$verse';
    final data = language == TranslationLanguage.id
        ? await _loadIndonesian()
        : await _loadEnglish();
    return data[key] ?? const [];
  }

  Future<Map<String, List<WordByWordItem>>> _loadEnglish() {
    if (_cacheEn != null) {
      return Future.value(_cacheEn);
    }
    _loadEnFuture ??= _loadFromAssets();
    return _loadEnFuture!;
  }

  Future<Map<String, List<WordByWordItem>>> _loadFromAssets() async {
    try {
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
              translation: (word['trn'] as String?) ?? '',
            );
            result.putIfAbsent(key, () => []).add(item);
          }
        }
      }

      _cacheEn = result;
      return result;
    } catch (e, s) {
      debugPrint('Failed to load word-by-word (EN) data: $e');
      debugPrint(s.toString());
      return {};
    }
  }

  Future<Map<String, List<WordByWordItem>>> _loadIndonesian() {
    if (_cacheId != null) {
      return Future.value(_cacheId);
    }
    _loadIdFuture ??= _loadFromIdAssets();
    return _loadIdFuture!;
  }

  Future<Map<String, List<WordByWordItem>>> _loadFromIdAssets() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/word_by_word_id.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final Map<String, List<WordByWordItem>> result = {};
      data.forEach((key, value) {
        final items = <WordByWordItem>[];
        for (final rawWord in value as List<dynamic>) {
          final word = rawWord as Map<String, dynamic>;
          items.add(
            WordByWordItem(
              arabic: (word['arabic'] as String?) ?? '',
              transliteration: (word['transliteration'] as String?) ?? '',
              translation: (word['translation'] as String?) ?? '',
            ),
          );
        }
        if (items.isNotEmpty) {
          result[key] = items;
        }
      });
      _cacheId = result;
      return result;
    } catch (e, s) {
      debugPrint('Failed to load word-by-word (ID) data: $e');
      debugPrint(s.toString());
      return {};
    }
  }
}
