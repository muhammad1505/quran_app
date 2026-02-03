import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/services/bookmark_service.dart';
import 'package:quran_app/core/services/last_read_service.dart';
import 'package:quran_app/core/services/translation_service.dart';
import 'package:quran_app/core/settings/quran_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alfurqan/alfurqan.dart';
import 'package:alfurqan/constant.dart';

import 'package:quran_app/core/di/injection.dart';
import 'package:injectable/injectable.dart';

part 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  final LastReadService _lastReadService = LastReadService.instance;
  final BookmarkService _bookmarkService = BookmarkService.instance;
  final QuranSettingsController _quranSettings = getIt<QuranSettingsController>();

  HomeCubit() : super(HomeLoading());

  Future<void> fetchInitialData() async {
    try {
      emit(HomeLoading());

      final locationLabel = await _loadLocationLabel();
      final lastRead = await _lastReadService.getLastRead();
      final bookmarkKeys = await _bookmarkService.getKeys();

      emit(HomeLoaded(
        locationLabel: locationLabel,
        lastRead: lastRead,
        bookmarkKeys: bookmarkKeys,
        isDailyVerseLoading: true,
      ));

      await _loadDailyVerse();
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _loadDailyVerse() async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    try {
      emit(currentState.copyWith(isDailyVerseLoading: true));

      final now = DateTime.now();
      final dayIndex = now.difference(DateTime(now.year, 1, 1)).inDays;
      final surah = (dayIndex % 114) + 1;
      final verseCount = quran.getVerseCount(surah);
      final ayah = (dayIndex % verseCount) + 1;
      final arabic = quran.getVerse(surah, ayah);
      final translation = await _resolveTranslation(
        _quranSettings.value.translation,
        surah,
        ayah,
      );

      final dailyVerse = DailyVerse(
        surah: surah,
        ayah: ayah,
        arabic: arabic,
        translation: translation,
      );

      if (state is HomeLoaded) {
        emit((state as HomeLoaded)
            .copyWith(dailyVerse: dailyVerse, isDailyVerseLoading: false));
      }
    } catch (e) {
      if (state is HomeLoaded) {
        emit((state as HomeLoaded)
            .copyWith(dailyVerse: null, isDailyVerseLoading: false));
      }
    }
  }

  Future<void> toggleDailyVerseBookmark(DailyVerse verse) async {
    await _bookmarkService.toggleBookmark(
      surah: verse.surah,
      ayah: verse.ayah,
    );
    final bookmarkKeys = await _bookmarkService.getKeys();
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(bookmarkKeys: bookmarkKeys));
    }
  }

  Future<void> refreshLastRead() async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final lastRead = await _lastReadService.getLastRead();
      emit(currentState.copyWith(lastRead: lastRead));
    }
  }

  Future<String> _loadLocationLabel() async {
    final prefs = await SharedPreferences.getInstance();
    final manualEnabled = prefs.getBool('manual_location_enabled') ?? false;
    final manualName = prefs.getString('manual_location_name');
    final lat = prefs.getDouble('last_lat');
    final lng = prefs.getDouble('last_lng');

    if (manualEnabled && manualName != null) {
      return manualName;
    }
    if (lat == null || lng == null) {
      return 'Aktifkan lokasi untuk akurasi';
    }
    return 'Koordinat ${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}';
  }

  Future<String> _resolveTranslation(
    TranslationSource source,
    int surah,
    int ayah,
  ) async {
    if (TranslationAssetService.instance.requiresAsset(source)) {
      final map = await TranslationAssetService.instance.load(source);
      return _sanitizeTranslation(map['$surah:$ayah'] ?? '');
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
      AlQuran.translation(
        _translationType(source),
        verseKey,
      ).text,
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
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
