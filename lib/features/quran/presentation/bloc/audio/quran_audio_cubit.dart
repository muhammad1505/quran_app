import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/services/audio_cache_service.dart';
import 'package:quran_app/core/settings/audio_settings.dart';
import 'quran_audio_state.dart';

@injectable
class QuranAudioCubit extends Cubit<QuranAudioState> {
  final AudioCacheService _audioCacheService;
  final AudioSettingsController _audioSettings = AudioSettingsController.instance;
  final AudioPlayer _player = AudioPlayer();
  
  // Stream subscriptions for proper cleanup
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  QuranAudioCubit(this._audioCacheService) : super(QuranAudioInitial()) {
    _playerStateSubscription = _player.playerStateStream.listen(_onPlayerStateChanged);
    _positionSubscription = _player.positionStream.listen(_onPositionChanged);
    _audioSettings.addListener(_onAudioSettingsChanged);
  }

  // Local state tracking
  int _currentSurah = 1;
  int? _currentAyah;
  bool _isAyahMode = false;
  Duration _position = Duration.zero;
  DownloadStatus _downloadStatus = DownloadStatus.notDownloaded;

  Future<void> _onPlayerStateChanged(PlayerState state) async {
    if (state.processingState == ProcessingState.completed) {
      if (_isAyahMode && _audioSettings.value.autoPlayNextAyah) {
        await playNextVerse();
      } else {
        emit(_getCurrentPausedState());
      }
    } else {
      _emitCurrentState();
    }
  }

  void _onPositionChanged(Duration position) {
    _position = position;
    _emitCurrentState();
  }

  void _onAudioSettingsChanged() {
    _player.setVolume(_audioSettings.value.volume);
    _player.setSpeed(_audioSettings.value.playbackSpeed);
    _player.setLoopMode(
      _audioSettings.value.repeatOne ? LoopMode.one : LoopMode.off,
    );
    _emitCurrentState();
  }

  void _emitCurrentState() {
    if (_player.playing) {
      emit(
        QuranAudioPlaying(
          surahNumber: _currentSurah,
          currentAyah: _currentAyah,
          position: _position,
          duration: _player.duration ?? Duration.zero,
          isAyahMode: _isAyahMode,
          isRepeatOne: _audioSettings.value.repeatOne,
          downloadStatus: _downloadStatus,
        ),
      );
    } else {
      emit(_getCurrentPausedState());
    }
  }

  QuranAudioPaused _getCurrentPausedState() {
    return QuranAudioPaused(
      surahNumber: _currentSurah,
      currentAyah: _currentAyah,
      isAyahMode: _isAyahMode,
      isRepeatOne: _audioSettings.value.repeatOne,
      position: _position,
      duration: _player.duration ?? Duration.zero,
      downloadStatus: _downloadStatus,
    );
  }

  Future<void> _updateDownloadStatus() async {
    final qariId = _audioSettings.value.qariId;
    final isDownloaded =
        await _audioCacheService.isSurahDownloaded(_currentSurah, qariId);
    _downloadStatus =
        isDownloaded ? DownloadStatus.downloaded : DownloadStatus.notDownloaded;
    _emitCurrentState();
  }

  Future<void> loadSurah({required int surahNumber, int? initialVerse}) async {
    _currentSurah = surahNumber;
    _currentAyah = initialVerse;
    _isAyahMode = initialVerse != null;
    await _updateDownloadStatus();
    _emitCurrentState();
  }

  Future<void> playSurah(int surahNumber) async {
    try {
      // Pause if it's the same surah playing
      if (state is QuranAudioPlaying &&
          _currentSurah == surahNumber &&
          !_isAyahMode) {
        await _player.pause();
        return;
      }
       // Resume if paused on the same surah
      if (state is QuranAudioPaused &&
          _currentSurah == surahNumber &&
          !_isAyahMode) {
        await _player.play();
        return;
      }

      emit(const QuranAudioLoading());
      _currentSurah = surahNumber;
      _isAyahMode = false;
      _currentAyah = null;

      await _updateDownloadStatus();

      final qariId = _audioSettings.value.qariId;
      final file =
          await _audioCacheService.getLocalSurahFile(surahNumber, qariId);

      if (file != null) {
        await _player.setFilePath(file.path);
      } else {
        final url = _audioCacheService.surahUrl(surahNumber, qariId);
        await _player.setUrl(url);
      }

      _onAudioSettingsChanged(); // Apply settings
      await _player.play();
    } catch (e) {
      emit(QuranAudioError('Gagal memutar audio: $e'));
    }
  }

  Future<void> playVerse(int surahNumber, int ayahNumber) async {
    try {
      emit(QuranAudioLoading(currentAyah: ayahNumber));
      _currentSurah = surahNumber;
      _isAyahMode = true;
      _currentAyah = ayahNumber;

      await _updateDownloadStatus();

      final qari = _audioCacheService.qariById(_audioSettings.value.qariId);
      final globalIndex = _getGlobalAyahIndex(surahNumber, ayahNumber);
      final url =
          'https://cdn.islamic.network/quran/audio/128/${qari.audioSlug}/$globalIndex.mp3';

      await _player.setUrl(url);
      _onAudioSettingsChanged(); // Apply settings
      await _player.play();
    } catch (e) {
      emit(QuranAudioError('Gagal memutar audio ayat: $e'));
    }
  }
  
  Future<void> playNextVerse() async {
    if(!_isAyahMode || _currentAyah == null) return;
    final maxAyah = quran.getVerseCount(_currentSurah);
    final next = _currentAyah! + 1;
    if (next <= maxAyah) {
      await playVerse(_currentSurah, next);
    }
  }

  Future<void> playPreviousVerse() async {
    if(!_isAyahMode || _currentAyah == null) return;
    final prev = _currentAyah! - 1;
    if (prev >= 1) {
      await playVerse(_currentSurah, prev);
    }
  }

  Future<void> toggleDownload() async {
    if (_downloadStatus == DownloadStatus.downloading) return;

    final qariId = _audioSettings.value.qariId;
    _downloadStatus = DownloadStatus.downloading;
    _emitCurrentState();

    try {
      if (await _audioCacheService.isSurahDownloaded(_currentSurah, qariId)) {
        await _audioCacheService.deleteSurah(_currentSurah, qariId);
      } else {
        await _audioCacheService.downloadSurah(_currentSurah, qariId);
      }
      await _updateDownloadStatus();
    } catch (e) {
      emit(QuranAudioError("Gagal mengunduh audio: $e"));
      await _updateDownloadStatus(); // Reset status on error
    }
  }

  Future<void> toggleRepeat() async {
    await _audioSettings.updateRepeatOne(!_audioSettings.value.repeatOne);
  }
  
  Future<void> setPlaybackSpeed(double speed) async {
    await _audioSettings.updatePlaybackSpeed(speed);
  }

  Future<void> playPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
  
  int _getGlobalAyahIndex(int surah, int ayah) {
    var index = ayah;
    for (var i = 1; i < surah; i++) {
      index += quran.getVerseCount(i);
    }
    return index;
  }

  @override
  Future<void> close() async {
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    _audioSettings.removeListener(_onAudioSettingsChanged);
    await _player.dispose();
    return super.close();
  }
}
