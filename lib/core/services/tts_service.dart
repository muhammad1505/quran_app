import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  Future<void> speak(String text, {String? language}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _init();
    if (language != null) {
      await _tts.setLanguage(language);
    }
    await _tts.stop();
    await _tts.speak(trimmed);
  }

  Future<void> stop() async {
    await _init();
    await _tts.stop();
  }
}
