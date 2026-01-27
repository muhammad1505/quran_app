import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, sepia }

class ThemeSettings {
  final AppThemeMode mode;

  const ThemeSettings({this.mode = AppThemeMode.light});

  ThemeSettings copyWith({AppThemeMode? mode}) {
    return ThemeSettings(mode: mode ?? this.mode);
  }
}

@lazySingleton
class ThemeSettingsController extends ChangeNotifier {
  static const _themeKey = 'app_theme_mode';

  ThemeSettingsController();

  ThemeSettings _value = const ThemeSettings();
  ThemeSettings get value => _value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _value = _value.copyWith(
      mode: _parseMode(prefs.getString(_themeKey)),
    );
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _value = _value.copyWith(mode: mode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  AppThemeMode _parseMode(String? raw) {
    if (raw == null) return AppThemeMode.light;
    return AppThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => AppThemeMode.light,
    );
  }
}
