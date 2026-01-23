import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioSettings {
  final String qariId;
  final double volume;
  final double playbackSpeed;

  const AudioSettings({
    this.qariId = 'alafasy',
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
  });

  AudioSettings copyWith({
    String? qariId,
    double? volume,
    double? playbackSpeed,
  }) {
    return AudioSettings(
      qariId: qariId ?? this.qariId,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

class AudioSettingsController extends ChangeNotifier {
  static const _qariKey = 'qari';
  static const _volumeKey = 'volume';
  static const _speedKey = 'audio_speed';
  static const _allowedQariIds = {'alafasy', 'abdulbasit', 'basfar'};

  AudioSettingsController._();

  static final AudioSettingsController instance = AudioSettingsController._();

  AudioSettings _value = const AudioSettings();
  AudioSettings get value => _value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedQari = prefs.getString(_qariKey) ?? 'alafasy';
    _value = _value.copyWith(
      qariId: _allowedQariIds.contains(storedQari) ? storedQari : 'alafasy',
      volume: prefs.getDouble(_volumeKey) ?? 1.0,
      playbackSpeed: prefs.getDouble(_speedKey) ?? 1.0,
    );
    notifyListeners();
  }

  Future<void> updateQari(String qariId) async {
    _value = _value.copyWith(qariId: qariId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_qariKey, qariId);
  }

  Future<void> updateVolume(double volume) async {
    _value = _value.copyWith(volume: volume);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, volume);
  }

  Future<void> updatePlaybackSpeed(double speed) async {
    _value = _value.copyWith(playbackSpeed: speed);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speedKey, speed);
  }
}
