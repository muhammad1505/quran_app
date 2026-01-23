import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TranslationLanguage { id, en }

enum TranslationSource {
  idKemenag,
  idKingFahad,
  idSabiq,
  enAbdelHaleem,
  enSaheeh,
}

enum ArabicFontFamily { amiri, scheherazade, lateef }

extension ArabicFontFamilyExtension on ArabicFontFamily {
  String get label {
    switch (this) {
      case ArabicFontFamily.amiri:
        return 'Amiri';
      case ArabicFontFamily.scheherazade:
        return 'Scheherazade';
      case ArabicFontFamily.lateef:
        return 'Lateef';
    }
  }
}

extension TranslationSourceExtension on TranslationSource {
  TranslationLanguage get language {
    switch (this) {
      case TranslationSource.idKemenag:
      case TranslationSource.idKingFahad:
      case TranslationSource.idSabiq:
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
      case TranslationSource.idKingFahad:
        return 'Bahasa Indonesia (King Fahad Quran Complex)';
      case TranslationSource.idSabiq:
        return 'Bahasa Indonesia (The Sabiq Company)';
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
  final double arabicFontSize;
  final double translationFontSize;
  final double arabicLineHeight;
  final ArabicFontFamily arabicFontFamily;

  const QuranSettings({
    this.translation = TranslationSource.idKemenag,
    this.showLatin = false,
    this.showTajwid = false,
    this.showWordByWord = false,
    this.arabicFontSize = 32,
    this.translationFontSize = 16,
    this.arabicLineHeight = 2.0,
    this.arabicFontFamily = ArabicFontFamily.amiri,
  });

  QuranSettings copyWith({
    TranslationSource? translation,
    bool? showLatin,
    bool? showTajwid,
    bool? showWordByWord,
    double? arabicFontSize,
    double? translationFontSize,
    double? arabicLineHeight,
    ArabicFontFamily? arabicFontFamily,
  }) {
    return QuranSettings(
      translation: translation ?? this.translation,
      showLatin: showLatin ?? this.showLatin,
      showTajwid: showTajwid ?? this.showTajwid,
      showWordByWord: showWordByWord ?? this.showWordByWord,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      arabicLineHeight: arabicLineHeight ?? this.arabicLineHeight,
      arabicFontFamily: arabicFontFamily ?? this.arabicFontFamily,
    );
  }
}

class QuranSettingsController extends ChangeNotifier {
  static const _translationKey = 'translation';
  static const _showLatinKey = 'show_latin';
  static const _showTajwidKey = 'show_tajwid';
  static const _showWordByWordKey = 'show_word_by_word';
  static const _arabicFontSizeKey = 'arabic_font_size';
  static const _translationFontSizeKey = 'translation_font_size';
  static const _arabicLineHeightKey = 'arabic_line_height';
  static const _arabicFontKey = 'arabic_font_family';

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
      arabicFontSize: prefs.getDouble(_arabicFontSizeKey) ?? 32,
      translationFontSize: prefs.getDouble(_translationFontSizeKey) ?? 16,
      arabicLineHeight: prefs.getDouble(_arabicLineHeightKey) ?? 2.0,
      arabicFontFamily: _parseArabicFont(prefs.getString(_arabicFontKey)),
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

  Future<void> setArabicFontSize(double size) async {
    _value = _value.copyWith(arabicFontSize: size);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_arabicFontSizeKey, size);
  }

  Future<void> setTranslationFontSize(double size) async {
    _value = _value.copyWith(translationFontSize: size);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_translationFontSizeKey, size);
  }

  Future<void> setArabicLineHeight(double height) async {
    _value = _value.copyWith(arabicLineHeight: height);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_arabicLineHeightKey, height);
  }

  Future<void> setArabicFontFamily(ArabicFontFamily family) async {
    _value = _value.copyWith(arabicFontFamily: family);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_arabicFontKey, family.name);
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

  ArabicFontFamily _parseArabicFont(String? code) {
    if (code == null) return ArabicFontFamily.amiri;
    return ArabicFontFamily.values.firstWhere(
      (font) => font.name == code,
      orElse: () => ArabicFontFamily.amiri,
    );
  }
}
