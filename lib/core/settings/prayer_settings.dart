import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adhan/adhan.dart';

enum PrayerCalculationMethod {
  kemenagMabims,
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  northAmerica,
  moonSightingCommittee,
  dubai,
  kuwait,
  qatar,
  turkey,
  tehran,
}

enum PrayerMadhab { shafi, hanafi }

class PrayerSettings {
  final PrayerCalculationMethod method;
  final PrayerMadhab madhab;

  const PrayerSettings({
    this.method = PrayerCalculationMethod.kemenagMabims,
    this.madhab = PrayerMadhab.shafi,
  });

  PrayerSettings copyWith({
    PrayerCalculationMethod? method,
    PrayerMadhab? madhab,
  }) {
    return PrayerSettings(
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
    );
  }
}

class PrayerSettingsController extends ChangeNotifier {
  static const _methodKey = 'prayer_method';
  static const _madhabKey = 'prayer_madhab';

  PrayerSettingsController._();

  static final PrayerSettingsController instance = PrayerSettingsController._();

  PrayerSettings _value = const PrayerSettings();
  PrayerSettings get value => _value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _value = _value.copyWith(
      method: _parseMethod(prefs.getString(_methodKey)),
      madhab: _parseMadhab(prefs.getString(_madhabKey)),
    );
    notifyListeners();
  }

  Future<void> updateMethod(PrayerCalculationMethod method) async {
    _value = _value.copyWith(method: method);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_methodKey, method.name);
  }

  Future<void> updateMadhab(PrayerMadhab madhab) async {
    _value = _value.copyWith(madhab: madhab);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_madhabKey, madhab.name);
  }

  CalculationParameters buildParameters() {
    final params = _methodToParams(_value.method);
    params.madhab = _value.madhab == PrayerMadhab.hanafi
        ? Madhab.hanafi
        : Madhab.shafi;
    return params;
  }

  PrayerCalculationMethod _parseMethod(String? raw) {
    if (raw == null) return PrayerCalculationMethod.kemenagMabims;
    return PrayerCalculationMethod.values.firstWhere(
      (method) => method.name == raw,
      orElse: () => PrayerCalculationMethod.kemenagMabims,
    );
  }

  PrayerMadhab _parseMadhab(String? raw) {
    if (raw == null) return PrayerMadhab.shafi;
    return PrayerMadhab.values.firstWhere(
      (madhab) => madhab.name == raw,
      orElse: () => PrayerMadhab.shafi,
    );
  }

  CalculationParameters _methodToParams(PrayerCalculationMethod method) {
    switch (method) {
      case PrayerCalculationMethod.kemenagMabims:
        return CalculationMethod.singapore.getParameters();
      case PrayerCalculationMethod.muslimWorldLeague:
        return CalculationMethod.muslim_world_league.getParameters();
      case PrayerCalculationMethod.egyptian:
        return CalculationMethod.egyptian.getParameters();
      case PrayerCalculationMethod.karachi:
        return CalculationMethod.karachi.getParameters();
      case PrayerCalculationMethod.ummAlQura:
        return CalculationMethod.umm_al_qura.getParameters();
      case PrayerCalculationMethod.northAmerica:
        return CalculationMethod.north_america.getParameters();
      case PrayerCalculationMethod.moonSightingCommittee:
        return CalculationMethod.moon_sighting_committee.getParameters();
      case PrayerCalculationMethod.dubai:
        return CalculationMethod.dubai.getParameters();
      case PrayerCalculationMethod.kuwait:
        return CalculationMethod.kuwait.getParameters();
      case PrayerCalculationMethod.qatar:
        return CalculationMethod.qatar.getParameters();
      case PrayerCalculationMethod.turkey:
        return CalculationMethod.turkey.getParameters();
      case PrayerCalculationMethod.tehran:
        return CalculationMethod.tehran.getParameters();
    }
  }
}

String prayerMethodLabel(PrayerCalculationMethod method) {
  switch (method) {
    case PrayerCalculationMethod.kemenagMabims:
      return 'Kemenag/MABIMS';
    case PrayerCalculationMethod.muslimWorldLeague:
      return 'Muslim World League (MWL)';
    case PrayerCalculationMethod.egyptian:
      return 'Egyptian General Authority';
    case PrayerCalculationMethod.karachi:
      return 'Karachi (UIS)';
    case PrayerCalculationMethod.ummAlQura:
      return 'Umm al-Qura';
    case PrayerCalculationMethod.northAmerica:
      return 'North America (ISNA)';
    case PrayerCalculationMethod.moonSightingCommittee:
      return 'Moon Sighting Committee';
    case PrayerCalculationMethod.dubai:
      return 'Dubai';
    case PrayerCalculationMethod.kuwait:
      return 'Kuwait';
    case PrayerCalculationMethod.qatar:
      return 'Qatar';
    case PrayerCalculationMethod.turkey:
      return 'Turkey (Diyanet)';
    case PrayerCalculationMethod.tehran:
      return 'Tehran';
  }
}

String prayerMadhabLabel(PrayerMadhab madhab) {
  switch (madhab) {
    case PrayerMadhab.shafi:
      return 'Syafi\'i';
    case PrayerMadhab.hanafi:
      return 'Hanafi';
  }
}
