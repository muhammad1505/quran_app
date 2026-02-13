import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:quran_app/core/services/bookmark_service.dart';
import 'package:quran_app/core/services/translation_asset_service.dart';
import 'package:quran_app/core/settings/quran_settings.dart';
import 'package:alfurqan/alfurqan.dart';
import 'package:alfurqan/constant.dart';
import 'package:quran_app/features/quran/presentation/bloc/search/search_constants.dart';

part 'search_state.dart';

@injectable
class SearchCubit extends Cubit<SearchState> {
  final QuranSettingsController _quranSettings;
  final TranslationAssetService _translationAssetService;
  final BookmarkService _bookmarkService;
  Timer? _searchDebounce;
  Map<String, String>? _translationSearchMap;
  TranslationSource? _translationSearchSource;

  SearchCubit(
    this._quranSettings,
    this._translationAssetService,
    this._bookmarkService,
  ) : super(const SearchInitial(
          surahNumbers,
          juzNumbers,
          [],
          [],
        )) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final bookmarks = await _bookmarkService.getAll();
    final folders = await _bookmarkService.getFolders();
    emit(SearchInitial(
      surahNumbers,
      juzNumbers,
      bookmarks,
      folders,
    ));
  }

  void search(String query) {
    _searchDebounce?.cancel();
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      _loadInitialData();
      return;
    }

    emit(const SearchLoading());
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      // Surah Search
      final nameMatches = _getSurahNameMatches(normalized);
      final translationMatches = await _searchTranslations(normalized);
      final combinedSurahs = {...nameMatches, ...translationMatches}.toList();
      combinedSurahs.sort();

      // Juz Search
      final juzMatches = List<int>.generate(30, (i) => i + 1).where((juz) {
        return 'juz $juz'.contains(normalized) || juz.toString() == normalized;
      }).toList();

      // Bookmark Search
      final allBookmarks = await _bookmarkService.getAll();
      final allFolders = await _bookmarkService.getFolders();

      final bookmarkMatches = allBookmarks.where((bookmark) {
        return bookmark.note?.toLowerCase().contains(normalized) ?? false;
      }).toList();

      final folderMatches = allFolders.where((folder) {
        return folder.name.toLowerCase().contains(normalized);
      }).toList();

      emit(SearchLoaded(combinedSurahs, juzMatches, bookmarkMatches, folderMatches));
    });
  }

  Set<int> _getSurahNameMatches(String normalized) {
    return List<int>.generate(114, (i) => i + 1).where((surah) {
      final name = AlQuran.chapter(surah).nameSimple.toLowerCase();
      return name.contains(normalized) || surah.toString() == normalized;
    }).toSet();
  }

  Future<Set<int>> _searchTranslations(String query) async {
    final normalized = query.toLowerCase();
    final source = _quranSettings.value.translation;
    final needsAsset = _translationAssetService.requiresAsset(source);
    Map<String, String>? map;

    if (needsAsset) {
      if (_translationSearchSource != source || _translationSearchMap == null) {
        map = await _translationAssetService.load(source);
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
        final verses = AlQuran.chapter(surah).versesCount;
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
    if (_translationAssetService.requiresAsset(source) &&
        _translationSearchMap != null) {
      return _sanitizeTranslation(_translationSearchMap!['$surah:$ayah'] ?? '');
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
