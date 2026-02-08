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
import '../services/audio_cache_service.dart' as _i807;
import '../services/prayer_notification_service.dart' as _i35;
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
    gh.factory<_i816.HomeCubit>(() => _i816.HomeCubit());
    gh.factory<_i814.BookmarkCubit>(() => _i814.BookmarkCubit());
    gh.lazySingleton<_i807.AudioCacheService>(() => _i807.AudioCacheService());
    gh.lazySingleton<_i35.PrayerNotificationService>(
        () => _i35.PrayerNotificationService());
    gh.lazySingleton<_i942.QuranSettingsController>(
        () => _i942.QuranSettingsController());
    gh.lazySingleton<_i422.ThemeSettingsController>(
        () => _i422.ThemeSettingsController());
    gh.factory<_i860.QuranAudioCubit>(
        () => _i860.QuranAudioCubit(gh<_i807.AudioCacheService>()));
    gh.factory<_i257.SearchCubit>(
        () => _i257.SearchCubit(gh<_i942.QuranSettingsController>()));
    return this;
  }
}
