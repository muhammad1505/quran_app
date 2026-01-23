import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

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

class WordByWordService {
  WordByWordService._();

  static final WordByWordService instance = WordByWordService._();

  Future<Map<String, List<WordByWordItem>>>? _loadFuture;
  Map<String, List<WordByWordItem>>? _cacheEn;
  final Map<String, Map<String, List<WordByWordItem>>> _remoteCache = {};

  Future<List<WordByWordItem>> wordsFor(
    int chapter,
    int verse, {
    required TranslationLanguage language,
  }) async {
    final key = '$chapter:$verse';
    if (language == TranslationLanguage.en) {
      final data = await _loadEnglish();
      return data[key] ?? const [];
    }
    if (_remoteCache[language.name]?.containsKey(key) == true) {
      return _remoteCache[language.name]![key] ?? const [];
    }
    final fetched = await _fetchRemoteWords(
      chapter: chapter,
      verse: verse,
      languageCode: _languageCode(language),
    );
    _remoteCache.putIfAbsent(language.name, () => {})[key] = fetched;
    return fetched;
  }

  Future<Map<String, List<WordByWordItem>>> _loadEnglish() {
    if (_cacheEn != null) {
      return Future.value(_cacheEn);
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
            translation: (word['trn'] as String?) ?? '',
          );
          result.putIfAbsent(key, () => []).add(item);
        }
      }
    }

    _cacheEn = result;
    return result;
  }

  Future<List<WordByWordItem>> _fetchRemoteWords({
    required int chapter,
    required int verse,
    required String languageCode,
  }) async {
    final uri = Uri.parse(
      'https://api.quran.com/api/v4/verses/by_key/$chapter:$verse'
      '?words=true&language=$languageCode',
    );
    try {
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) {
        return const [];
      }
      final body = await response.transform(utf8.decoder).join();
      final jsonMap = jsonDecode(body) as Map<String, dynamic>;
      final verseData = jsonMap['verse'] as Map<String, dynamic>?;
      if (verseData == null) {
        return const [];
      }
      final words = verseData['words'] as List<dynamic>? ?? const [];
      final results = <WordByWordItem>[];
      for (final rawWord in words) {
        final word = rawWord as Map<String, dynamic>;
        if (word['char_type_name'] != 'word') {
          continue;
        }
        final translationMap =
            word['translation'] as Map<String, dynamic>? ?? const {};
        final transliterationMap =
            word['transliteration'] as Map<String, dynamic>? ?? const {};
        results.add(
          WordByWordItem(
            arabic: (word['text'] as String?) ?? '',
            transliteration:
                (transliterationMap['text'] as String?) ?? '',
            translation: (translationMap['text'] as String?) ?? '',
          ),
        );
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  String _languageCode(TranslationLanguage language) {
    switch (language) {
      case TranslationLanguage.id:
        return 'id';
      case TranslationLanguage.en:
        return 'en';
    }
  }
}
