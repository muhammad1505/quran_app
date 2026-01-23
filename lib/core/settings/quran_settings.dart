import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TranslationLanguage { id, en }

enum TranslationSource { idKemenag, enAbdelHaleem, enSaheeh }

extension TranslationSourceExtension on TranslationSource {
  TranslationLanguage get language {
    switch (this) {
      case TranslationSource.idKemenag:
        return TranslationLanguage.id;
      case TranslationSource.enAbdelHaleem:
      case TranslationSource.enSaheeh:
        return TranslationLanguage.en;
    }
  }

  String get label {
    switch (this) {
      case TranslationSource.idKemenag:
        return 'Bahasa Indonesia (Kemenag RI)';
      case TranslationSource.enAbdelHaleem:
        return 'English (Abdel Haleem)';
      case TranslationSource.enSaheeh:
        return 'English (Saheeh International)';
    }
  }
}

class QuranSettings {
  final TranslationSource translation;
  final bool showLatin;
  final bool showTajwid;
  final bool showWordByWord;

  const QuranSettings({
    this.translation = TranslationSource.idKemenag,
    this.showLatin = false,
    this.showTajwid = false,
    this.showWordByWord = false,
  });

  QuranSettings copyWith({
    TranslationSource? translation,
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
    final translationCode = prefs.getString(_translationKey);
    _value = _value.copyWith(
      translation: _parseTranslation(translationCode),
      showLatin: prefs.getBool(_showLatinKey) ?? false,
      showTajwid: prefs.getBool(_showTajwidKey) ?? false,
      showWordByWord: prefs.getBool(_showWordByWordKey) ?? false,
    );
    notifyListeners();
  }

  Future<void> updateTranslation(TranslationSource source) async {
    _value = _value.copyWith(translation: source);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_translationKey, source.name);
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

  TranslationSource _parseTranslation(String? code) {
    if (code == null) {
      return TranslationSource.idKemenag;
    }
    if (code == 'id') {
      return TranslationSource.idKemenag;
    }
    if (code == 'en') {
      return TranslationSource.enAbdelHaleem;
    }
    return TranslationSource.values.firstWhere(
      (source) => source.name == code,
      orElse: () => TranslationSource.idKemenag,
    );
  }
}
