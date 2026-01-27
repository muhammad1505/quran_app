import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;

class QuranAudioPlayerSheet extends StatelessWidget {
  final AudioPlayer player;
  final int surahNumber;
  final bool isAyahMode;
  final int? currentAyah;
  final bool isPlaying;
  final bool isLoading;
  final bool repeatOne;
  final double speed;
  final VoidCallback onPlayPause;
  final VoidCallback? onNextAyah;
  final VoidCallback? onPrevAyah;
  final VoidCallback onToggleRepeat;
  final ValueChanged<double> onSpeedChanged;

  const QuranAudioPlayerSheet({
    super.key,
    required this.player,
    required this.surahNumber,
    required this.isAyahMode,
    required this.currentAyah,
    required this.isPlaying,
    required this.isLoading,
    required this.repeatOne,
    required this.speed,
    required this.onPlayPause,
    required this.onNextAyah,
    required this.onPrevAyah,
    required this.onToggleRepeat,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final title = isAyahMode && currentAyah != null
        ? 'Ayat ${currentAyah!} • ${quran.getSurahName(surahNumber)}'
        : 'Murotal ${quran.getSurahName(surahNumber)}';
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
                color: Colors.grey.withValues(alpha: 0.4),
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
            StreamBuilder<Duration?>(
              stream: player.durationStream,
              builder: (context, snapshot) {
                final duration = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    final max = duration.inMilliseconds.toDouble();
                    final value = position.inMilliseconds.toDouble();
                    return Column(
                      children: [
                        Slider(
                          value: max > 0 ? value.clamp(0, max) : 0,
                          max: max > 0 ? max : 1,
                          onChanged: max > 0
                              ? (val) {
                                  player.seek(
                                    Duration(milliseconds: val.round()),
                                  );
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
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onPrevAyah,
                  icon: const Icon(Icons.skip_previous),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: isLoading ? null : onPlayPause,
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
                  onPressed: onNextAyah,
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
                    onPressed: onToggleRepeat,
                    icon: Icon(
                      repeatOne ? Icons.repeat_one : Icons.repeat,
                      color:
                          repeatOne ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<double>(
                    onSelected: onSpeedChanged,
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
                            Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      ),
                      child: Text(
                        '${speed.toStringAsFixed(2).replaceAll('.00', '')}x',
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
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
