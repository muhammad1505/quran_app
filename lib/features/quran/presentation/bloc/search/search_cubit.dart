import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/services/translation_service.dart';
import 'package:quran_app/core/settings/quran_settings.dart';
import 'package:alfurqan/alfurqan.dart';
import 'package:alfurqan/constant.dart';

part 'search_state.dart';

@injectable
class SearchCubit extends Cubit<SearchState> {
  final QuranSettingsController _quranSettings;
  Timer? _searchDebounce;
  Map<String, String>? _translationSearchMap;
  TranslationSource? _translationSearchSource;

  SearchCubit(this._quranSettings)
      : super(SearchInitial(List<int>.generate(114, (i) => i + 1)));

  void search(String query) {
    _searchDebounce?.cancel();
    final normalized = query.trim();

    if (normalized.isEmpty) {
      emit(SearchInitial(List<int>.generate(114, (i) => i + 1)));
      return;
    }

    if (normalized.length < 3) {
      _filterSurahNames(normalized);
      return;
    }

    emit(SearchLoading());
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final nameMatches = _getSurahNameMatches(normalized);
      final translationMatches = await _searchTranslations(normalized);
      final combined = {...nameMatches, ...translationMatches}.toList();
      combined.sort();
      emit(SearchLoaded(combined));
    });
  }

  void _filterSurahNames(String normalized) {
    final nameMatches = _getSurahNameMatches(normalized);
    emit(SearchLoaded(nameMatches.toList()));
  }

  Set<int> _getSurahNameMatches(String normalized) {
    return List<int>.generate(114, (i) => i + 1).where((surah) {
      final name = quran.getSurahName(surah).toLowerCase();
      return name.contains(normalized) || surah.toString() == normalized;
    }).toSet();
  }

  Future<Set<int>> _searchTranslations(String query) async {
    final normalized = query.toLowerCase();
    final source = _quranSettings.value.translation;
    final needsAsset = TranslationAssetService.instance.requiresAsset(source);
    Map<String, String>? map;

    if (needsAsset) {
      if (_translationSearchSource != source || _translationSearchMap == null) {
        map = await TranslationAssetService.instance.load(source);
        _translationSearchMap = map;
        _translationSearchSource = source;
      } else {
        map = _translationSearchMap;
      }
    }

    final matches = <int>{};
    if (needsAsset && map != null) {
      for (final entry in map.entries) {
        if (entry.value.toLowerCase().contains(normalized)) {
          final surah = int.tryParse(entry.key.split(':').first);
          if (surah != null) {
            matches.add(surah);
          }
        }
      }
    } else {
      for (var surah = 1; surah <= 114; surah++) {
        final verses = quran.getVerseCount(surah);
        for (var ayah = 1; ayah <= verses; ayah++) {
          final translation = _translationForSearch(source, surah, ayah);
          if (translation.toLowerCase().contains(normalized)) {
            matches.add(surah);
            break;
          }
        }
      }
    }
    return matches;
  }

  String _translationForSearch(
    TranslationSource source,
    int surah,
    int ayah,
  ) {
    if (TranslationAssetService.instance.requiresAsset(source) &&
        _translationSearchMap != null) {
      return _sanitizeTranslation(_translationSearchMap!['$surah:$ayah'] ?? '');
    }
    if (source == TranslationSource.enSaheeh) {
      return _sanitizeTranslation(
        quran.getVerseTranslation(
          surah,
          ayah,
          translation: quran.Translation.enSaheeh,
        ),
      );
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

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
