import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Al-Quran")),
      body: ListView.separated(
        itemCount: 114,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final surahNumber = index + 1;
          return ListTile(
            leading: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.star_outline, size: 40, color: Colors.green),
                Text("$surahNumber", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            title: Text(quran.getSurahName(surahNumber), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${quran.getPlaceOfRevelation(surahNumber)} • ${quran.getVerseCount(surahNumber)} Ayat"),
            trailing: Text(
              quran.getSurahNameArabic(surahNumber),
              style: GoogleFonts.amiri(fontSize: 22, color: Theme.of(context).primaryColor),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SurahDetailPage(surahNumber: surahNumber)));
            },
          );
        },
      ),
    );
  }
}

class SurahDetailPage extends StatefulWidget {
  final int surahNumber;
  const SurahDetailPage({super.key, required this.surahNumber});

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
        _isLoading = state.processingState == ProcessingState.loading || state.processingState == ProcessingState.buffering;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_audioPlayer.processingState == ProcessingState.idle) {
        // Example URL: Mishary Rashid Alafasy
        final String url = quran.getAudioURLBySurah(widget.surahNumber);
        try {
          await _audioPlayer.setUrl(url);
          await _audioPlayer.play();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading audio: $e")));
        }
      } else {
        await _audioPlayer.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int verseCount = quran.getVerseCount(widget.surahNumber);
    return Scaffold(
      appBar: AppBar(
        title: Text(quran.getSurahName(widget.surahNumber)),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _playPause,
            icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: verseCount,
        itemBuilder: (context, index) {
          final verseNumber = index + 1;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(radius: 12, child: Text("$verseNumber", style: const TextStyle(fontSize: 12))),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.share, size: 20), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.bookmark_border, size: 20), onPressed: () {}),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  quran.getVerse(widget.surahNumber, verseNumber),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiri(fontSize: 28, height: 2.0),
                ),
                const SizedBox(height: 16),
                Text(
                  quran.getVerseTranslation(widget.surahNumber, verseNumber, translation: quran.Translation.idIndonesian),
                  textAlign: TextAlign.left,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                ),
                const Divider(),
              ],
            ),
          );
        },
      ),
    );
  }
}
