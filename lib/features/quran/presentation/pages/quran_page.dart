import 'package:alfurqan/alfurqan.dart';
import 'package:alfurqan/constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/services/word_by_word_service.dart';
import 'package:quran_app/core/settings/quran_settings.dart';

class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Al-Quran Al-Karim"),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 114,
        itemBuilder: (context, index) {
          final surahNumber = index + 1;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurahDetailPage(surahNumber: surahNumber),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: 0.785, // 45 degrees
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Text(
                          "$surahNumber",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quran.getSurahName(surahNumber),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${quran.getPlaceOfRevelation(surahNumber)} • ${quran.getVerseCount(surahNumber)} Ayat",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      quran.getSurahNameArabic(surahNumber),
                      style: GoogleFonts.amiri(
                        fontSize: 26,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
  final QuranSettingsController _quranSettings =
      QuranSettingsController.instance;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
        _isLoading =
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
      });
    });
    _quranSettings.addListener(_onSettingsChanged);
    _quranSettings.load();
  }

  @override
  void dispose() {
    _quranSettings.removeListener(_onSettingsChanged);
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_audioPlayer.processingState == ProcessingState.idle) {
        final String url = quran.getAudioURLBySurah(widget.surahNumber);
        try {
          await _audioPlayer.setUrl(url);
          await _audioPlayer.play();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Error: $e")));
          }
        }
      } else {
        await _audioPlayer.play();
      }
    }
  }

  TranslationType _translationType(TranslationLanguage language) {
    switch (language) {
      case TranslationLanguage.id:
        return TranslationType.idIndonesianIslamicAffairsMinistry;
      case TranslationLanguage.en:
        return TranslationType.enMASAbdelHaleem;
    }
  }

  String _decodeHtml(String input) {
    return input
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"');
  }

  String _sanitizeTranslation(String input) {
    final decoded = _decodeHtml(input);
    final withoutFootnotes =
        decoded.replaceAll(RegExp(r'<sup[^>]*>.*?</sup>'), '');
    final withoutTags = withoutFootnotes.replaceAll(RegExp(r'<[^>]+>'), '');
    return withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<InlineSpan> _buildTajweedSpans(
    String text,
    ThemeData theme,
  ) {
    final decoded = _decodeHtml(text);
    final regex = RegExp(
      r'<(tajweed|span) class=([a-z_]+)>(.*?)</\1>',
      dotAll: true,
    );
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in regex.allMatches(decoded)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: decoded.substring(cursor, match.start)));
      }
      final className = match.group(2) ?? '';
      final content = match.group(3) ?? '';
      final isEnd = className == 'end';
      spans.add(
        TextSpan(
          text: content,
          style: TextStyle(
            color: isEnd
                ? Colors.grey[500]
                : _tajweedColor(className, theme),
            fontSize: isEnd ? 18 : null,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < decoded.length) {
      spans.add(TextSpan(text: decoded.substring(cursor)));
    }
    return spans;
  }

  Color _tajweedColor(String className, ThemeData theme) {
    switch (className) {
      case 'ham_wasl':
        return const Color(0xFF1565C0);
      case 'laam_shamsiyah':
        return const Color(0xFF6A1B9A);
      case 'madda_normal':
        return const Color(0xFF2E7D32);
      case 'madda_permissible':
        return const Color(0xFF00897B);
      case 'madda_necessity':
        return const Color(0xFF00695C);
      case 'madda_obligatory':
        return const Color(0xFF00796B);
      case 'ikhfa':
        return const Color(0xFFF9A825);
      case 'iqlab':
        return const Color(0xFF00838F);
      case 'idgham_ghunnah':
        return const Color(0xFF7B1FA2);
      case 'idgham_wo_ghunnah':
        return const Color(0xFF5D4037);
      case 'qalqalah':
        return const Color(0xFFD32F2F);
      case 'ghunnah':
        return const Color(0xFFAD1457);
      default:
        return theme.primaryColor;
    }
  }

  Widget _buildArabicText({
    required String text,
    required bool showTajwid,
    required ThemeData theme,
  }) {
    final baseStyle = GoogleFonts.amiri(
      fontSize: 30,
      height: 2.2,
      color: theme.textTheme.bodyLarge?.color,
    );
    if (!showTajwid) {
      return Text(
        text,
        textAlign: TextAlign.right,
        style: baseStyle,
      );
    }
    return RichText(
      textAlign: TextAlign.right,
      text: TextSpan(style: baseStyle, children: _buildTajweedSpans(text, theme)),
    );
  }

  Widget _buildWordByWordSection({
    required int verseNumber,
    required bool showLatin,
    required TranslationLanguage language,
  }) {
    return FutureBuilder<List<WordByWordItem>>(
      future: WordByWordService.instance.wordsFor(
        widget.surahNumber,
        verseNumber,
        language: language,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final words = snapshot.data ?? const [];
        if (words.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              "Terjemahan per kata belum tersedia untuk ayat ini.",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: words
                .map((word) => _buildWordChip(word, showLatin))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildWordChip(WordByWordItem word, bool showLatin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            word.arabic,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          if (showLatin && word.transliteration.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              word.transliteration,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (word.translation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              word.translation,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int verseCount = quran.getVerseCount(widget.surahNumber);
    final settings = _quranSettings.value;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              quran.getSurahName(widget.surahNumber),
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              quran.getSurahNameArabic(widget.surahNumber),
              style: GoogleFonts.amiri(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _playPause,
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 30,
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Basmalah Header
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                style: GoogleFonts.amiri(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: verseCount,
              itemBuilder: (context, index) {
                final verseNumber = index + 1;
                final verseKey = "${widget.surahNumber}:$verseNumber";
                final verseText = AlQuran.verse(
                  widget.surahNumber,
                  verseNumber,
                  mode: settings.showTajwid
                      ? VerseMode.uthmaniTajweed
                      : VerseMode.uthmani,
                ).text;
                final translationText = _sanitizeTranslation(
                  AlQuran.translation(
                    _translationType(settings.translation),
                    verseKey,
                  ).text,
                );
                final transliterationText = settings.showLatin
                    ? _decodeHtml(AlQuran.transliteration(verseKey).text)
                    : '';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "Ayat $verseNumber",
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.share_outlined,
                                size: 20,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.bookmark_border,
                                size: 20,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildArabicText(
                        text: verseText,
                        showTajwid: settings.showTajwid,
                        theme: Theme.of(context),
                      ),
                      if (settings.showLatin && transliterationText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            transliterationText,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              height: 1.6,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        translationText,
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (settings.showWordByWord)
                        _buildWordByWordSection(
                          verseNumber: verseNumber,
                          showLatin: settings.showLatin,
                          language: settings.translation,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
