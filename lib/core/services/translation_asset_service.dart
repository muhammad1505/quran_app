import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:quran_app/core/settings/quran_settings.dart';

@lazySingleton
class TranslationAssetService {
  final Map<TranslationSource, Map<String, String>> _cache = {};
  final Map<TranslationSource, Future<Map<String, String>>> _inFlight = {};

  Future<Map<String, String>> load(TranslationSource source) {
    if (_cache.containsKey(source)) {
      return Future.value(_cache[source]!);
    }
    if (_inFlight.containsKey(source)) {
      return _inFlight[source]!;
    }
    final future = _loadFromAssets(source);
    _inFlight[source] = future;
    return future;
  }

  bool requiresAsset(TranslationSource source) {
    return _assetPath(source) != null;
  }

  Future<Map<String, String>> _loadFromAssets(TranslationSource source) async {
    final path = _assetPath(source);
    if (path == null) {
      return {};
    }
    final jsonString = await rootBundle.loadString(path);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final map = <String, String>{};
    data.forEach((key, value) {
      map[key] = value?.toString() ?? '';
    });
    _cache[source] = map;
    _inFlight.remove(source);
    return map;
  }

  String? _assetPath(TranslationSource source) {
    switch (source) {
      case TranslationSource.idKingFahad:
        return 'assets/translations/translation_134.json';
      case TranslationSource.idSabiq:
        return 'assets/translations/translation_141.json';
      case TranslationSource.idKemenag:
      case TranslationSource.enAbdelHaleem:
      case TranslationSource.enSaheeh:
        return null;
    }
  }
}
