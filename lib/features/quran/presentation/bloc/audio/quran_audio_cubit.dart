import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran_app/core/services/audio_cache_service.dart';
import 'package:quran_app/core/settings/audio_settings.dart';
import 'package:quran/quran.dart' as quran;
import 'quran_audio_state.dart';

@injectable
class QuranAudioCubit extends Cubit<QuranAudioState> {
  final AudioCacheService _audioCacheService;
  final AudioPlayer _player = AudioPlayer();

  QuranAudioCubit(this._audioCacheService) : super(QuranAudioInitial()) {
    _player.playerStateStream.listen(_onPlayerStateChanged);
    _player.positionStream.listen(_onPositionChanged);
  }

  // Local state tracking to emit updates
  int _currentSurah = 1;
  int? _currentAyah;
  bool _isAyahMode = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  Future<void> playSurah(int surahNumber, {required AudioSettings settings}) async {
    try {
      if (_currentSurah == surahNumber && !_isAyahMode && _player.playing) {
        await _player.pause();
        return;
      }
      
      emit(const QuranAudioLoading());
      _currentSurah = surahNumber;
      _isAyahMode = false;
      _currentAyah = null;

      final qariId = settings.qariId;
      final file = await _audioCacheService.getLocalSurahFile(surahNumber, qariId);
      
      if (file != null) {
        await _player.setFilePath(file.path);
      } else {
        final url = _audioCacheService.surahUrl(surahNumber, qariId);
        await _player.setUrl(url);
      }
      
      _player.setVolume(settings.volume);
      _player.setSpeed(settings.playbackSpeed);
      await _player.play();
    } catch (e) {
      emit(QuranAudioError('Gagal memutar audio: $e'));
    }
  }
  
  Future<void> pause() async {
    await _player.pause();
  }
  
  Future<void> resume() async {
    await _player.play();
  }

  void _onPlayerStateChanged(PlayerState state) {
    if (state.processingState == ProcessingState.ready && state.playing) {
       emit(QuranAudioPlaying(
         surahNumber: _currentSurah,
         currentAyah: _currentAyah,
         position: _position,
         duration: _player.duration ?? Duration.zero,
         isAyahMode: _isAyahMode,
       ));
    } else if (!state.playing) {
       emit(QuranAudioPaused(
         surahNumber: _currentSurah,
         currentAyah: _currentAyah,
         isAyahMode: _isAyahMode,
       ));
    }
  }

  void _onPositionChanged(Duration position) {
    _position = position;
    if (state is QuranAudioPlaying) {
      emit(QuranAudioPlaying(
        surahNumber: _currentSurah,
        currentAyah: _currentAyah,
        position: position,
        duration: _player.duration ?? Duration.zero,
        isAyahMode: _isAyahMode,
      ));
    }
  }

  @override
  Future<void> close() {
    _player.dispose();
    return super.close();
  }
}
