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
    return this;
  }
}
