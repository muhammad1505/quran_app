import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_app/core/services/bookmark_service.dart';
import 'package:quran_app/core/services/last_read_service.dart';
import 'package:quran_app/core/services/translation_service.dart';
import 'package:quran_app/core/settings/quran_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alfurqan/alfurqan.dart';

import 'package:injectable/injectable.dart';

part 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  final LastReadService _lastReadService;
  final BookmarkService _bookmarkService;
  final QuranSettingsController _quranSettings;
  final TranslationService _translationService;

  HomeCubit(
    this._lastReadService,
    this._bookmarkService,
    this._quranSettings,
    this._translationService,
  ) : super(HomeLoading());

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
      final surah = (dayIndex % 114).toInt() + 1;
      final verseCount = AlQuran.chapter(surah).versesCount;
      final ayah = (dayIndex % verseCount).toInt() + 1;
      final arabic = AlQuran.verse(surah, ayah).text;
      final translation = await _translationService.getTranslation(
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
}
