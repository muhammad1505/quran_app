import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/settings/audio_settings.dart';
import 'package:quran_app/features/quran/presentation/bloc/audio/quran_audio_cubit.dart';
import 'package:quran_app/features/quran/presentation/bloc/audio/quran_audio_state.dart';

class QuranAudioPlayerSheet extends StatelessWidget {
  const QuranAudioPlayerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<QuranAudioCubit>();
    final audioSettings = AudioSettingsController.instance;

    return BlocBuilder<QuranAudioCubit, QuranAudioState>(
      builder: (context, state) {
        String title;
        bool isPlaying = false;
        bool isLoading = false;
        bool isAyahMode = false;
        bool isRepeatOne = false;
        int? currentAyah;
        int surahNumber = 1;
        Duration position = Duration.zero;
        Duration duration = Duration.zero;

        if (state is QuranAudioPlaying) {
          isPlaying = true;
          isLoading = false;
          isAyahMode = state.isAyahMode;
          isRepeatOne = state.isRepeatOne;
          currentAyah = state.currentAyah;
          surahNumber = state.surahNumber;
          position = state.position;
          duration = state.duration;
        } else if (state is QuranAudioPaused) {
          isPlaying = false;
          isLoading = false;
          isAyahMode = state.isAyahMode;
          isRepeatOne = state.isRepeatOne;
          currentAyah = state.currentAyah;
          surahNumber = state.surahNumber;
          position = state.position;
          duration = state.duration;
        } else if (state is QuranAudioLoading) {
          isLoading = true;
        }

        if (isAyahMode && currentAyah != null) {
          title = 'Ayat ${currentAyah} • ${quran.getSurahName(surahNumber)}';
        } else {
          title = 'Murotal ${quran.getSurahName(surahNumber)}';
        }

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha((255 * 0.4).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    Slider(
                      value: duration.inMilliseconds > 0
                          ? position.inMilliseconds
                              .toDouble()
                              .clamp(0, duration.inMilliseconds.toDouble())
                          : 0,
                      max: duration.inMilliseconds > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1,
                      onChanged: duration.inMilliseconds > 0
                          ? (val) {
                              cubit.seek(Duration(milliseconds: val.round()));
                            }
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(_formatDuration(position)),
                          const Spacer(),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: isAyahMode ? cubit.playPreviousVerse : null,
                      icon: const Icon(Icons.skip_previous),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: isLoading ? null : cubit.playPause,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      iconSize: 32,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: isAyahMode ? cubit.playNextVerse : null,
                      icon: const Icon(Icons.skip_next),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: cubit.toggleRepeat,
                        icon: Icon(
                          isRepeatOne ? Icons.repeat_one : Icons.repeat,
                          color: isRepeatOne
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<double>(
                        onSelected: cubit.setPlaybackSpeed,
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 0.75, child: Text('0.75x')),
                          PopupMenuItem(value: 1.0, child: Text('1.0x')),
                          PopupMenuItem(value: 1.25, child: Text('1.25x')),
                          PopupMenuItem(value: 1.5, child: Text('1.5x')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color:
                                Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
                          ),
                          child: Text(
                            '${audioSettings.value.playbackSpeed.toStringAsFixed(2).replaceAll('.00', '')}x',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isAyahMode)
                        Text(
                          'Mode Ayat',
                          style: Theme.of(context).textTheme.labelMedium,
                        )
                      else
                        Text(
                          'Mode Surah',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'Ketuk mini player untuk membuka panel ini.',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
