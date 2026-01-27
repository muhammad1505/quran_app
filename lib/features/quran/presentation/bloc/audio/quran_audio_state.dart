import 'package:equatable/equatable.dart';

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

  const QuranAudioPlaying({
    required this.surahNumber,
    this.currentAyah,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    required this.isAyahMode,
  });

  @override
  List<Object?> get props => [surahNumber, currentAyah, position, duration, isAyahMode];
}

class QuranAudioPaused extends QuranAudioState {
  final int surahNumber;
  final int? currentAyah;
  final bool isAyahMode;

  const QuranAudioPaused({
    required this.surahNumber,
    this.currentAyah,
    required this.isAyahMode,
  });
  
  @override
  List<Object?> get props => [surahNumber, currentAyah, isAyahMode];
}

class QuranAudioError extends QuranAudioState {
  final String message;

  const QuranAudioError(this.message);

  @override
  List<Object?> get props => [message];
}
