import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TranslationLanguage { id, en }

class QuranSettings {
  final TranslationLanguage translation;
  final bool showLatin;
  final bool showTajwid;
  final bool showWordByWord;

  const QuranSettings({
    this.translation = TranslationLanguage.id,
    this.showLatin = false,
    this.showTajwid = false,
    this.showWordByWord = false,
  });

  QuranSettings copyWith({
    TranslationLanguage? translation,
    bool? showLatin,
    bool? showTajwid,
    bool? showWordByWord,
  }) {
    return QuranSettings(
      translation: translation ?? this.translation,
      showLatin: showLatin ?? this.showLatin,
      showTajwid: showTajwid ?? this.showTajwid,
      showWordByWord: showWordByWord ?? this.showWordByWord,
    );
  }
}

class QuranSettingsController extends ChangeNotifier {
  static const _translationKey = 'translation';
  static const _showLatinKey = 'show_latin';
  static const _showTajwidKey = 'show_tajwid';
  static const _showWordByWordKey = 'show_word_by_word';

  QuranSettingsController._();

  static final QuranSettingsController instance = QuranSettingsController._();

  QuranSettings _value = const QuranSettings();
  QuranSettings get value => _value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final translationCode = prefs.getString(_translationKey) ?? 'id';
    _value = _value.copyWith(
      translation: _parseTranslation(translationCode),
      showLatin: prefs.getBool(_showLatinKey) ?? false,
      showTajwid: prefs.getBool(_showTajwidKey) ?? false,
      showWordByWord: prefs.getBool(_showWordByWordKey) ?? false,
    );
    notifyListeners();
  }

  Future<void> updateTranslation(TranslationLanguage language) async {
    _value = _value.copyWith(translation: language);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_translationKey, _translationCode(language));
  }

  Future<void> setShowLatin(bool enabled) async {
    _value = _value.copyWith(showLatin: enabled);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showLatinKey, enabled);
  }

  Future<void> setShowTajwid(bool enabled) async {
    _value = _value.copyWith(showTajwid: enabled);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTajwidKey, enabled);
  }

  Future<void> setShowWordByWord(bool enabled) async {
    _value = _value.copyWith(showWordByWord: enabled);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showWordByWordKey, enabled);
  }

  TranslationLanguage _parseTranslation(String code) {
    switch (code) {
      case 'en':
        return TranslationLanguage.en;
      case 'id':
      default:
        return TranslationLanguage.id;
    }
  }

  String _translationCode(TranslationLanguage language) {
    switch (language) {
      case TranslationLanguage.en:
        return 'en';
      case TranslationLanguage.id:
        return 'id';
    }
  }
}
