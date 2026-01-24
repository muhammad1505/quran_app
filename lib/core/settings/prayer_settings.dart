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

enum AdzanSound { defaultTone, makkah, madinah }

extension AdzanSoundExtension on AdzanSound {
  String get label {
    switch (this) {
      case AdzanSound.defaultTone:
        return 'Default';
      case AdzanSound.makkah:
        return 'Makkah';
      case AdzanSound.madinah:
        return 'Madinah';
    }
  }
}

class PrayerSettings {
  final PrayerCalculationMethod method;
  final PrayerMadhab madhab;
  final int correctionMinutes;
  final bool notifyFajr;
  final bool notifyDhuhr;
  final bool notifyAsr;
  final bool notifyMaghrib;
  final bool notifyIsha;
  final bool silentMode;
  final AdzanSound adzanSound;

  const PrayerSettings({
    this.method = PrayerCalculationMethod.kemenagMabims,
    this.madhab = PrayerMadhab.shafi,
    this.correctionMinutes = 0,
    this.notifyFajr = true,
    this.notifyDhuhr = true,
    this.notifyAsr = true,
    this.notifyMaghrib = true,
    this.notifyIsha = true,
    this.silentMode = false,
    this.adzanSound = AdzanSound.defaultTone,
  });

  bool isNotificationEnabled(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return notifyFajr;
      case Prayer.dhuhr:
        return notifyDhuhr;
      case Prayer.asr:
        return notifyAsr;
      case Prayer.maghrib:
        return notifyMaghrib;
      case Prayer.isha:
        return notifyIsha;
      default:
        return true;
    }
  }

  PrayerSettings copyWith({
    PrayerCalculationMethod? method,
    PrayerMadhab? madhab,
    int? correctionMinutes,
    bool? notifyFajr,
    bool? notifyDhuhr,
    bool? notifyAsr,
    bool? notifyMaghrib,
    bool? notifyIsha,
    bool? silentMode,
    AdzanSound? adzanSound,
  }) {
    return PrayerSettings(
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
      correctionMinutes: correctionMinutes ?? this.correctionMinutes,
      notifyFajr: notifyFajr ?? this.notifyFajr,
      notifyDhuhr: notifyDhuhr ?? this.notifyDhuhr,
      notifyAsr: notifyAsr ?? this.notifyAsr,
      notifyMaghrib: notifyMaghrib ?? this.notifyMaghrib,
      notifyIsha: notifyIsha ?? this.notifyIsha,
      silentMode: silentMode ?? this.silentMode,
      adzanSound: adzanSound ?? this.adzanSound,
    );
  }
}

class PrayerSettingsController extends ChangeNotifier {
  static const _methodKey = 'prayer_method';
  static const _madhabKey = 'prayer_madhab';
  static const _correctionKey = 'prayer_correction_minutes';
  static const _notifyFajrKey = 'notify_fajr';
  static const _notifyDhuhrKey = 'notify_dhuhr';
  static const _notifyAsrKey = 'notify_asr';
  static const _notifyMaghribKey = 'notify_maghrib';
  static const _notifyIshaKey = 'notify_isha';
  static const _silentModeKey = 'prayer_silent_mode';
  static const _adzanSoundKey = 'prayer_adzan_sound';

  PrayerSettingsController._();

  static final PrayerSettingsController instance = PrayerSettingsController._();

  PrayerSettings _value = const PrayerSettings();
  PrayerSettings get value => _value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _value = _value.copyWith(
      method: _parseMethod(prefs.getString(_methodKey)),
      madhab: _parseMadhab(prefs.getString(_madhabKey)),
      correctionMinutes: prefs.getInt(_correctionKey) ?? 0,
      notifyFajr: prefs.getBool(_notifyFajrKey) ?? true,
      notifyDhuhr: prefs.getBool(_notifyDhuhrKey) ?? true,
      notifyAsr: prefs.getBool(_notifyAsrKey) ?? true,
      notifyMaghrib: prefs.getBool(_notifyMaghribKey) ?? true,
      notifyIsha: prefs.getBool(_notifyIshaKey) ?? true,
      silentMode: prefs.getBool(_silentModeKey) ?? false,
      adzanSound: _parseAdzanSound(prefs.getString(_adzanSoundKey)),
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

  Future<void> updateCorrectionMinutes(int minutes) async {
    _value = _value.copyWith(correctionMinutes: minutes);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_correctionKey, minutes);
  }

  Future<void> setNotificationEnabled(Prayer prayer, bool enabled) async {
    switch (prayer) {
      case Prayer.fajr:
        _value = _value.copyWith(notifyFajr: enabled);
        break;
      case Prayer.dhuhr:
        _value = _value.copyWith(notifyDhuhr: enabled);
        break;
      case Prayer.asr:
        _value = _value.copyWith(notifyAsr: enabled);
        break;
      case Prayer.maghrib:
        _value = _value.copyWith(notifyMaghrib: enabled);
        break;
      case Prayer.isha:
        _value = _value.copyWith(notifyIsha: enabled);
        break;
      default:
        return;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    switch (prayer) {
      case Prayer.fajr:
        await prefs.setBool(_notifyFajrKey, enabled);
        break;
      case Prayer.dhuhr:
        await prefs.setBool(_notifyDhuhrKey, enabled);
        break;
      case Prayer.asr:
        await prefs.setBool(_notifyAsrKey, enabled);
        break;
      case Prayer.maghrib:
        await prefs.setBool(_notifyMaghribKey, enabled);
        break;
      case Prayer.isha:
        await prefs.setBool(_notifyIshaKey, enabled);
        break;
      default:
        break;
    }
  }

  Future<void> setSilentMode(bool enabled) async {
    _value = _value.copyWith(silentMode: enabled);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_silentModeKey, enabled);
  }

  Future<void> setAdzanSound(AdzanSound sound) async {
    _value = _value.copyWith(adzanSound: sound);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adzanSoundKey, sound.name);
  }

  bool isNotificationEnabled(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return _value.notifyFajr;
      case Prayer.dhuhr:
        return _value.notifyDhuhr;
      case Prayer.asr:
        return _value.notifyAsr;
      case Prayer.maghrib:
        return _value.notifyMaghrib;
      case Prayer.isha:
        return _value.notifyIsha;
      default:
        return true;
    }
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

  AdzanSound _parseAdzanSound(String? raw) {
    if (raw == null) return AdzanSound.defaultTone;
    return AdzanSound.values.firstWhere(
      (sound) => sound.name == raw,
      orElse: () => AdzanSound.defaultTone,
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
