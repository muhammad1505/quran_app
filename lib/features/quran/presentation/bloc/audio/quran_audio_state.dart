import 'package:equatable/equatable.dart';

enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
}

abstract class QuranAudioState extends Equatable {
  const QuranAudioState();

  @override
  List<Object?> get props => [];
}

class QuranAudioInitial extends QuranAudioState {}

class QuranAudioLoading extends QuranAudioState {
  final int? currentAyah;
  const QuranAudioLoading({this.currentAyah});
}

class QuranAudioPlaying extends QuranAudioState {
  final int surahNumber;
  final int? currentAyah;
  final Duration position;
  final Duration duration;
  final bool isAyahMode;
  final bool isRepeatOne;
  final DownloadStatus downloadStatus;

  const QuranAudioPlaying({
    required this.surahNumber,
    this.currentAyah,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    required this.isAyahMode,
    required this.isRepeatOne,
    required this.downloadStatus,
  });

  @override
  List<Object?> get props => [
        surahNumber,
        currentAyah,
        position,
        duration,
        isAyahMode,
        isRepeatOne,
        downloadStatus,
      ];
}

class QuranAudioPaused extends QuranAudioState {
  final int surahNumber;
  final int? currentAyah;
  final bool isAyahMode;
  final bool isRepeatOne;
  final Duration position;
  final Duration duration;
  final DownloadStatus downloadStatus;

  const QuranAudioPaused({
    required this.surahNumber,
    this.currentAyah,
    required this.isAyahMode,
    required this.isRepeatOne,
    required this.position,
    required this.duration,
    required this.downloadStatus,
  });

  @override
  List<Object?> get props => [
        surahNumber,
        currentAyah,
        isAyahMode,
        isRepeatOne,
        position,
        duration,
        downloadStatus,
      ];
}

class QuranAudioError extends QuranAudioState {
  final String message;

  const QuranAudioError(this.message);

  @override
  List<Object?> get props => [message];
}
