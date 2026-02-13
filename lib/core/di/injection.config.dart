// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/home/presentation/bloc/home_cubit.dart' as _i816;
import '../../features/quran/presentation/bloc/audio/quran_audio_cubit.dart'
    as _i860;
import '../../features/quran/presentation/bloc/bookmark/bookmark_cubit.dart'
    as _i814;
import '../../features/quran/presentation/bloc/search/search_cubit.dart'
    as _i257;
import '../services/asmaul_husna_service.dart' as _i791;
import '../services/audio_cache_service.dart' as _i807;
import '../services/bookmark_service.dart' as _i467;
import '../services/doa_favorite_service.dart' as _i492;
import '../services/last_read_service.dart' as _i757;
import '../services/prayer_notification_service.dart' as _i35;
import '../services/tafsir_service.dart' as _i412;
import '../services/translation_asset_service.dart' as _i235;
import '../services/translation_service.dart' as _i298;
import '../services/tts_service.dart' as _i27;
import '../services/word_by_word_service.dart' as _i393;
import '../settings/audio_settings.dart' as _i203;
import '../settings/prayer_settings.dart' as _i509;
import '../settings/quran_settings.dart' as _i942;
import '../settings/theme_settings.dart' as _i422;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.lazySingleton<_i791.AsmaulHusnaService>(
        () => _i791.AsmaulHusnaService());
    gh.lazySingleton<_i807.AudioCacheService>(() => _i807.AudioCacheService());
    gh.lazySingleton<_i467.BookmarkService>(() => _i467.BookmarkService());
    gh.lazySingleton<_i492.DoaFavoriteService>(
        () => _i492.DoaFavoriteService());
    gh.lazySingleton<_i757.LastReadService>(() => _i757.LastReadService());
    gh.lazySingleton<_i35.PrayerNotificationService>(
        () => _i35.PrayerNotificationService());
    gh.lazySingleton<_i412.TafsirService>(() => _i412.TafsirService());
    gh.lazySingleton<_i235.TranslationAssetService>(
        () => _i235.TranslationAssetService());
    gh.lazySingleton<_i27.TtsService>(() => _i27.TtsService());
    gh.lazySingleton<_i393.WordByWordService>(() => _i393.WordByWordService());
    gh.lazySingleton<_i203.AudioSettingsController>(
        () => _i203.AudioSettingsController());
    gh.lazySingleton<_i509.PrayerSettingsController>(
        () => _i509.PrayerSettingsController());
    gh.lazySingleton<_i942.QuranSettingsController>(
        () => _i942.QuranSettingsController());
    gh.lazySingleton<_i422.ThemeSettingsController>(
        () => _i422.ThemeSettingsController());
    gh.factory<_i860.QuranAudioCubit>(
        () => _i860.QuranAudioCubit(gh<_i807.AudioCacheService>()));
    gh.factory<_i814.BookmarkCubit>(
        () => _i814.BookmarkCubit(gh<_i467.BookmarkService>()));
    gh.lazySingleton<_i298.TranslationService>(
        () => _i298.TranslationService(gh<_i235.TranslationAssetService>()));
    gh.factory<_i816.HomeCubit>(() => _i816.HomeCubit(
          gh<_i757.LastReadService>(),
          gh<_i467.BookmarkService>(),
          gh<_i942.QuranSettingsController>(),
          gh<_i298.TranslationService>(),
        ));
    gh.factory<_i257.SearchCubit>(() => _i257.SearchCubit(
          gh<_i942.QuranSettingsController>(),
          gh<_i235.TranslationAssetService>(),
          gh<_i467.BookmarkService>(),
        ));
    return this;
  }
}
