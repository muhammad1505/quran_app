// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../../features/quran/presentation/bloc/audio/quran_audio_cubit.dart'
    as _i7;
import '../services/audio_cache_service.dart' as _i3;
import '../services/prayer_notification_service.dart' as _i4;
import '../settings/quran_settings.dart' as _i5;
import '../settings/theme_settings.dart' as _i6;

import '../../features/home/presentation/bloc/home_cubit.dart' as _i8;

import '../../features/quran/presentation/bloc/search/search_cubit.dart'
    as _i9;

import '../../features/quran/presentation/bloc/bookmark/bookmark_cubit.dart'
    as _i10;

extension GetItInjectableX on _i1.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i1.GetIt init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.lazySingleton<_i3.AudioCacheService>(() => _i3.AudioCacheService());
    gh.lazySingleton<_i4.PrayerNotificationService>(
        () => _i4.PrayerNotificationService());
    gh.lazySingleton<_i5.QuranSettingsController>(
        () => _i5.QuranSettingsController());
    gh.lazySingleton<_i6.ThemeSettingsController>(
        () => _i6.ThemeSettingsController());
    gh.factory<_i7.QuranAudioCubit>(
        () => _i7.QuranAudioCubit(gh<_i3.AudioCacheService>()));

    // Manually registered by Gemini-CLI, will be overwritten by build_runner
    gh.factory<_i8.HomeCubit>(() => _i8.HomeCubit());
    gh.factory<_i9.SearchCubit>(
        () => _i9.SearchCubit(gh<_i5.QuranSettingsController>()));
    gh.factory<_i10.BookmarkCubit>(() => _i10.BookmarkCubit());

    return this;
  }
}
