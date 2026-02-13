import 'package:injectable/injectable.dart';
import 'package:quran_app/core/services/translation_asset_service.dart';
import 'package:quran_app/core/settings/quran_settings.dart';
import 'package:alfurqan/alfurqan.dart';
import 'package:alfurqan/constant.dart';

@lazySingleton
class TranslationService {
  final TranslationAssetService _assetService;

  TranslationService(this._assetService);

  bool requiresAsset(TranslationSource source) {
    return _assetService.requiresAsset(source);
  }

  Future<String> getTranslation(
    TranslationSource source,
    int surah,
    int ayah,
  ) async {
    if (_assetService.requiresAsset(source)) {
      final map = await _assetService.load(source);
      return _sanitizeTranslation(map['$surah:$ayah'] ?? '');
    }
    final verseKey = '$surah:$ayah';
    return _sanitizeTranslation(
      AlQuran.translation(_translationType(source), verseKey).text,
    );
  }

  TranslationType _translationType(TranslationSource source) {
    switch (source) {
      case TranslationSource.idKemenag:
      case TranslationSource.idKingFahad:
      case TranslationSource.idSabiq:
        return TranslationType.idIndonesianIslamicAffairsMinistry;
      case TranslationSource.enAbdelHaleem:
      case TranslationSource.enSaheeh:
        return TranslationType.enMASAbdelHaleem;
    }
  }

  String _sanitizeTranslation(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
