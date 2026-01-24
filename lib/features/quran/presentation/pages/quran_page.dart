import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:alfurqan/alfurqan.dart';
import 'package:alfurqan/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/services/audio_cache_service.dart';
import 'package:quran_app/core/services/bookmark_service.dart';
import 'package:quran_app/core/services/last_read_service.dart';
import 'package:quran_app/core/services/translation_service.dart';
import 'package:quran_app/core/services/word_by_word_service.dart';
import 'package:quran_app/core/settings/audio_settings.dart';
import 'package:quran_app/core/settings/quran_settings.dart';
import 'package:quran_app/features/quran/presentation/pages/tafsir_page.dart';
import 'package:share_plus/share_plus.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _showNotesOnly = false;
  String? _selectedFolderId;
  final List<_JuzStart> _juzStarts = const [
    _JuzStart(1, 1),
    _JuzStart(2, 142),
    _JuzStart(2, 253),
    _JuzStart(3, 93),
    _JuzStart(4, 24),
    _JuzStart(4, 148),
    _JuzStart(5, 82),
    _JuzStart(6, 111),
    _JuzStart(7, 88),
    _JuzStart(8, 41),
    _JuzStart(9, 93),
    _JuzStart(11, 6),
    _JuzStart(12, 53),
    _JuzStart(15, 1),
    _JuzStart(17, 1),
    _JuzStart(18, 75),
    _JuzStart(21, 1),
    _JuzStart(23, 1),
    _JuzStart(25, 21),
    _JuzStart(27, 56),
    _JuzStart(29, 46),
    _JuzStart(33, 31),
    _JuzStart(36, 28),
    _JuzStart(39, 32),
    _JuzStart(41, 47),
    _JuzStart(46, 1),
    _JuzStart(51, 31),
    _JuzStart(58, 1),
    _JuzStart(67, 1),
    _JuzStart(78, 1),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<int> _filteredSurahNumbers() {
    if (_query.isEmpty) {
      return List<int>.generate(114, (index) => index + 1);
    }
    final normalized = _query.toLowerCase().trim();
    return List<int>.generate(114, (index) => index + 1).where((surah) {
      final name = quran.getSurahName(surah).toLowerCase();
      return name.contains(normalized) || surah.toString() == normalized;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Al-Qur'an"),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Surah'),
              Tab(text: 'Juz'),
              Tab(text: 'Bookmark'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Cari surah, juz, atau kata terjemahan…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSurahList(context),
                  _buildJuzList(context),
                  _buildBookmarkList(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahList(BuildContext context) {
    final items = _filteredSurahNumbers();
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Surah tidak ditemukan.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final surahNumber = items[index];
        final place = quran.getPlaceOfRevelation(surahNumber);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SurahDetailPage(surahNumber: surahNumber),
                ),
              );
            },
            leading: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$surahNumber",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              quran.getSurahName(surahNumber),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "${place[0].toUpperCase()}${place.substring(1)} • ${quran.getVerseCount(surahNumber)} ayat",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  quran.getSurahNameArabic(surahNumber),
                  style: GoogleFonts.amiri(
                    fontSize: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJuzList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _juzStarts.length,
      itemBuilder: (context, index) {
        final juz = index + 1;
        final start = _juzStarts[index];
        final surahName = quran.getSurahName(start.surah);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Juz $juz'),
            subtitle: Text(
              'Mulai di $surahName ayat ${start.ayah}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SurahDetailPage(
                    surahNumber: start.surah,
                    initialVerse: start.ayah,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBookmarkList(BuildContext context) {
    return FutureBuilder<_BookmarkData>(
      future: _loadBookmarkData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data;
        final items = data?.bookmarks ?? [];
        final folders = data?.folders ?? [];
        final filtered = _showNotesOnly
            ? items.where((item) => (item.note ?? '').isNotEmpty).toList()
            : items;
        final filteredByFolder = _selectedFolderId == null
            ? filtered
            : filtered
                .where((item) => item.folderId == _selectedFolderId)
                .toList();
        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark_border, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _showNotesOnly ? 'Belum ada catatan' : 'Belum ada bookmark',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _showNotesOnly
                        ? 'Tambahkan catatan pada ayat favorit.'
                        : 'Tandai ayat favorit agar mudah diakses kembali.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Row(
              children: [
                Text(
                  'Bookmark',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showCreateFolderDialog,
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                  label: const Text('Folder'),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Favorit')),
                    ButtonSegment(value: true, label: Text('Catatan')),
                  ],
                  selected: {_showNotesOnly},
                  onSelectionChanged: (value) {
                    setState(() => _showNotesOnly = value.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (folders.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: folders.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ChoiceChip(
                        label: const Text('Semua'),
                        selected: _selectedFolderId == null,
                        onSelected: (_) =>
                            setState(() => _selectedFolderId = null),
                      );
                    }
                    final folder = folders[index - 1];
                    return ChoiceChip(
                      label: Text(folder.name),
                      selected: _selectedFolderId == folder.id,
                      onSelected: (_) =>
                          setState(() => _selectedFolderId = folder.id),
                    );
                  },
                ),
              ),
            if (folders.isNotEmpty) const SizedBox(height: 12),
            ...filteredByFolder.map((item) {
              final surahName = quran.getSurahName(item.surah);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('$surahName • Ayat ${item.ayah}'),
                  subtitle: Text(
                    item.note?.isNotEmpty == true
                        ? item.note!
                        : 'Tersimpan ${item.createdAt.toLocal().toString().split(' ').first}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SurahDetailPage(
                          surahNumber: item.surah,
                          initialVerse: item.ayah,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Contoh: Hafalan',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await BookmarkService.instance.addFolder(name);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<_BookmarkData> _loadBookmarkData() async {
    final results = await Future.wait([
      BookmarkService.instance.getAll(),
      BookmarkService.instance.getFolders(),
    ]);
    return _BookmarkData(
      bookmarks: results[0] as List<BookmarkItem>,
      folders: results[1] as List<BookmarkFolder>,
    );
  }
}

class SurahDetailPage extends StatefulWidget {
  final int surahNumber;
  final int? initialVerse;
  const SurahDetailPage({
    super.key,
    required this.surahNumber,
    this.initialVerse,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  late AudioPlayer _audioPlayer;
  late final ScrollController _scrollController;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  bool _isTranslationLoading = false;
  Map<String, String>? _customTranslationMap;
  TranslationSource? _customTranslationSource;
  int? _highlightVerse;
  Set<String> _bookmarkKeys = {};
  bool _isAyahMode = false;
  int? _currentAyah;
  final QuranSettingsController _quranSettings =
      QuranSettingsController.instance;
  final AudioSettingsController _audioSettings =
      AudioSettingsController.instance;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _scrollController = ScrollController(
      initialScrollOffset: _estimateScrollOffset(widget.initialVerse),
    );
    _highlightVerse = widget.initialVerse;
    _audioPlayer.playerStateStream.listen((state) async {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        _isLoading =
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
      });
      if (state.processingState == ProcessingState.completed &&
          _isAyahMode &&
          _audioSettings.value.autoPlayNextAyah) {
        final next = (_currentAyah ?? 0) + 1;
        final maxAyah = quran.getVerseCount(widget.surahNumber);
        if (next <= maxAyah) {
          await _playVerseAudio(next);
        }
      }
    });
    _quranSettings.addListener(_onSettingsChanged);
    _audioSettings.addListener(_onAudioSettingsChanged);
    _quranSettings.load();
    _audioSettings.load();
    _refreshDownloadStatus();
    _maybeLoadCustomTranslation();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _quranSettings.removeListener(_onSettingsChanged);
    _audioSettings.removeListener(_onAudioSettingsChanged);
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    _maybeLoadCustomTranslation();
    if (mounted) {
      setState(() {});
    }
  }

  void _onAudioSettingsChanged() {
    _audioPlayer.setVolume(_audioSettings.value.volume);
    _audioPlayer.setSpeed(_audioSettings.value.playbackSpeed);
    _audioPlayer.setLoopMode(
      _audioSettings.value.repeatOne ? LoopMode.one : LoopMode.off,
    );
    _refreshDownloadStatus();
    if (mounted) {
      setState(() {});
    }
  }

  double _estimateScrollOffset(int? verse) {
    if (verse == null || verse <= 1) return 0;
    const approxItemExtent = 190.0;
    return math.max(0, (verse - 1) * approxItemExtent);
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_audioPlayer.processingState == ProcessingState.idle) {
        try {
          _isAyahMode = false;
          _currentAyah = null;
          final qariId = _audioSettings.value.qariId;
          final localFile = await AudioCacheService.instance.getLocalSurahFile(
            widget.surahNumber,
            qariId,
          );
          if (localFile != null) {
            await _audioPlayer.setFilePath(localFile.path);
          } else {
            final url = AudioCacheService.instance.surahUrl(
              widget.surahNumber,
              qariId,
            );
            await _audioPlayer.setUrl(url);
          }
          _audioPlayer.setVolume(_audioSettings.value.volume);
          _audioPlayer.setSpeed(_audioSettings.value.playbackSpeed);
          _audioPlayer.setLoopMode(
            _audioSettings.value.repeatOne ? LoopMode.one : LoopMode.off,
          );
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

  Future<void> _playVerseAudio(int verseNumber) async {
    try {
      setState(() {
        _isAyahMode = true;
        _currentAyah = verseNumber;
        _highlightVerse = verseNumber;
      });
      final qari = AudioCacheService.instance.qariById(
        _audioSettings.value.qariId,
      );
      final globalIndex = _globalAyahIndex(widget.surahNumber, verseNumber);
      final url =
          'https://cdn.islamic.network/quran/audio/128/${qari.audioSlug}/$globalIndex.mp3';
      await _audioPlayer.setUrl(url);
      _audioPlayer.setVolume(_audioSettings.value.volume);
      _audioPlayer.setSpeed(_audioSettings.value.playbackSpeed);
      _audioPlayer.setLoopMode(
        _audioSettings.value.repeatOne ? LoopMode.one : LoopMode.off,
      );
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memutar audio ayat: $e')),
        );
      }
    }
  }

  Future<void> _playNextAyah() async {
    final maxAyah = quran.getVerseCount(widget.surahNumber);
    final next = (_currentAyah ?? 1) + 1;
    if (next <= maxAyah) {
      await _playVerseAudio(next);
    }
  }

  Future<void> _playPreviousAyah() async {
    final prev = (_currentAyah ?? 1) - 1;
    if (prev >= 1) {
      await _playVerseAudio(prev);
    }
  }

  int _globalAyahIndex(int surah, int ayah) {
    var index = ayah;
    for (var i = 1; i < surah; i++) {
      index += quran.getVerseCount(i);
    }
    return index;
  }

  TranslationType _translationType(TranslationSource source) {
    switch (source) {
      case TranslationSource.idKemenag:
      case TranslationSource.idKingFahad:
      case TranslationSource.idSabiq:
        return TranslationType.idIndonesianIslamicAffairsMinistry;
      case TranslationSource.enAbdelHaleem:
        return TranslationType.enMASAbdelHaleem;
      case TranslationSource.enSaheeh:
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
    required QuranSettings settings,
  }) {
    final baseStyle = _arabicTextStyle(settings, theme).copyWith(
      height: settings.arabicLineHeight,
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

  TextStyle _arabicTextStyle(QuranSettings settings, ThemeData theme) {
    switch (settings.arabicFontFamily) {
      case ArabicFontFamily.scheherazade:
        return GoogleFonts.scheherazadeNew(
          fontSize: settings.arabicFontSize,
          color: theme.textTheme.bodyLarge?.color,
        );
      case ArabicFontFamily.lateef:
        return GoogleFonts.lateef(
          fontSize: settings.arabicFontSize,
          color: theme.textTheme.bodyLarge?.color,
        );
      case ArabicFontFamily.amiri:
        return GoogleFonts.amiri(
          fontSize: settings.arabicFontSize,
          color: theme.textTheme.bodyLarge?.color,
        );
    }
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

  Future<void> _refreshDownloadStatus() async {
    final downloaded = await AudioCacheService.instance.isSurahDownloaded(
      widget.surahNumber,
      _audioSettings.value.qariId,
    );
    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
      });
    }
  }

  Future<void> _loadBookmarks() async {
    final keys = await BookmarkService.instance.getKeys();
    if (!mounted) return;
    setState(() => _bookmarkKeys = keys);
  }

  bool _isBookmarked(int verseNumber) {
    return _bookmarkKeys.contains('${widget.surahNumber}:$verseNumber');
  }

  Future<void> _toggleBookmark(int verseNumber) async {
    await BookmarkService.instance.toggleBookmark(
      surah: widget.surahNumber,
      ayah: verseNumber,
    );
    await _loadBookmarks();
  }

  Future<void> _maybeLoadCustomTranslation() async {
    final source = _quranSettings.value.translation;
    final needsAsset = TranslationAssetService.instance.requiresAsset(source);
    if (!needsAsset) {
      _customTranslationMap = null;
      _customTranslationSource = null;
      _isTranslationLoading = false;
      return;
    }
    if (_customTranslationSource == source && _customTranslationMap != null) {
      return;
    }
    setState(() => _isTranslationLoading = true);
    final map = await TranslationAssetService.instance.load(source);
    if (mounted) {
      setState(() {
        _customTranslationMap = map;
        _customTranslationSource = source;
        _isTranslationLoading = false;
      });
    }
  }

  Future<void> _toggleDownload() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      if (_isDownloaded) {
        await AudioCacheService.instance.deleteSurah(
          widget.surahNumber,
          _audioSettings.value.qariId,
        );
      } else {
        await AudioCacheService.instance.downloadSurah(
          widget.surahNumber,
          _audioSettings.value.qariId,
        );
      }
      await _refreshDownloadStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengunduh audio: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _showDisplaySettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: _quranSettings,
          builder: (context, _) {
            final settings = _quranSettings.value;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Tampilan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          'Aa',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSlider(
                      label: 'Ukuran Arab',
                      value: settings.arabicFontSize,
                      min: 26,
                      max: 38,
                      onChanged: (value) =>
                          _quranSettings.setArabicFontSize(value),
                    ),
                    _buildSlider(
                      label: 'Ukuran Terjemahan',
                      value: settings.translationFontSize,
                      min: 12,
                      max: 20,
                      onChanged: (value) =>
                          _quranSettings.setTranslationFontSize(value),
                    ),
                    _buildSlider(
                      label: 'Spasi Baris Arab',
                      value: settings.arabicLineHeight,
                      min: 1.6,
                      max: 2.6,
                      onChanged: (value) =>
                          _quranSettings.setArabicLineHeight(value),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ArabicFontFamily>(
                      initialValue: settings.arabicFontFamily,
                      decoration: const InputDecoration(
                        labelText: 'Font Arab',
                        border: OutlineInputBorder(),
                      ),
                      items: ArabicFontFamily.values
                          .map(
                            (font) => DropdownMenuItem(
                              value: font,
                              child: Text(font.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _quranSettings.setArabicFontFamily(value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Transliterasi (Latin)'),
                      value: settings.showLatin,
                      onChanged: (value) => _quranSettings.setShowLatin(value),
                    ),
                    SwitchListTile(
                      title: const Text('Tajwid'),
                      value: settings.showTajwid,
                      onChanged: (value) => _quranSettings.setShowTajwid(value),
                    ),
                    SwitchListTile(
                      title: const Text('Terjemahan per kata'),
                      value: settings.showWordByWord,
                      onChanged: (value) =>
                          _quranSettings.setShowWordByWord(value),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReaderMoreSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(_isDownloaded ? Icons.check_circle : Icons.download),
                title: Text(
                  _isDownloaded ? 'Hapus audio offline' : 'Unduh audio offline',
                ),
                onTap: _isDownloading
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _toggleDownload();
                      },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Simpan bookmark'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bookmark segera hadir.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Info surah'),
                onTap: () {
                  Navigator.pop(context);
                  _showSurahInfo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSurahInfo() {
    final name = quran.getSurahName(widget.surahNumber);
    final arabic = quran.getSurahNameArabic(widget.surahNumber);
    final place = quran.getPlaceOfRevelation(widget.surahNumber);
    final verses = quran.getVerseCount(widget.surahNumber);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(arabic, style: GoogleFonts.amiri(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              '${place[0].toUpperCase()}${place.substring(1)} • $verses ayat',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label),
              const Spacer(),
              Text(value.toStringAsFixed(0)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
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

  Widget _buildMiniPlayer() {
    final speed = _audioSettings.value.playbackSpeed;
    final repeatOn = _audioSettings.value.repeatOne;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.multitrack_audio, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isAyahMode && _currentAyah != null
                  ? 'Ayat ${_currentAyah!} • ${quran.getSurahName(widget.surahNumber)}'
                  : 'Murotal ${quran.getSurahName(widget.surahNumber)}',
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isAyahMode) ...[
            IconButton(
              onPressed: _playPreviousAyah,
              icon: const Icon(Icons.skip_previous),
              tooltip: 'Ayat sebelumnya',
            ),
            IconButton(
              onPressed: _playNextAyah,
              icon: const Icon(Icons.skip_next),
              tooltip: 'Ayat berikutnya',
            ),
          ],
          IconButton(
            onPressed: () {
              final next = !_audioSettings.value.repeatOne;
              _audioSettings.updateRepeatOne(next);
              _audioPlayer.setLoopMode(next ? LoopMode.one : LoopMode.off);
              setState(() {});
            },
            icon: Icon(
              repeatOn ? Icons.repeat_one : Icons.repeat,
              color: repeatOn ? Theme.of(context).primaryColor : null,
            ),
            tooltip: repeatOn ? 'Repeat ayat aktif' : 'Repeat ayat',
          ),
          PopupMenuButton<double>(
            onSelected: (value) {
              _audioSettings.updatePlaybackSpeed(value);
              _audioPlayer.setSpeed(value);
              setState(() {});
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 0.75, child: Text('0.75x')),
              PopupMenuItem(value: 1.0, child: Text('1.0x')),
              PopupMenuItem(value: 1.25, child: Text('1.25x')),
              PopupMenuItem(value: 1.5, child: Text('1.5x')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
              child: Text(
                '${speed.toStringAsFixed(2).replaceAll('.00', '')}x',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _playPause,
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVerseTap({
    required int verseNumber,
    required String arabic,
    required String translation,
    required String transliteration,
  }) async {
    await LastReadService.instance.save(
      surah: widget.surahNumber,
      ayah: verseNumber,
    );
    if (mounted) {
      setState(() => _highlightVerse = verseNumber);
    }
    _showVerseActionSheet(
      verseNumber: verseNumber,
      arabic: arabic,
      translation: translation,
      transliteration: transliteration,
    );
  }

  void _showVerseActionSheet({
    required int verseNumber,
    required String arabic,
    required String translation,
    required String transliteration,
  }) {
    final isSaved = _isBookmarked(verseNumber);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Putar audio ayat'),
                onTap: () {
                  Navigator.pop(context);
                  _playVerseAudio(verseNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: Text(isSaved ? 'Hapus bookmark' : 'Simpan bookmark'),
                onTap: () async {
                  Navigator.pop(context);
                  await _toggleBookmark(verseNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_add_outlined),
                title: const Text('Tambah catatan'),
                onTap: () {
                  Navigator.pop(context);
                  _showNoteDialog(verseNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Simpan ke folder'),
                onTap: () {
                  Navigator.pop(context);
                  _showFolderPicker(verseNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_all),
                title: const Text('Salin teks Arab'),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: arabic));
                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(
                      const SnackBar(content: Text('Teks Arab disalin.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Salin terjemahan'),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: translation));
                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(
                      const SnackBar(content: Text('Terjemahan disalin.')),
                  );
                },
              ),
              if (transliteration.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: const Text('Salin transliterasi'),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(
                      ClipboardData(text: transliteration),
                    );
                    if (!mounted) return;
                    navigator.pop();
                    messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Transliterasi disalin.'),
                        ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Bagikan ayat'),
                onTap: () {
                  Navigator.pop(context);
                  _showShareDialog(
                    verseNumber: verseNumber,
                    arabic: arabic,
                    translation: translation,
                    transliteration: transliteration,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Tafsir ringkas'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TafsirPage(
                        surahNumber: widget.surahNumber,
                        verseNumber: verseNumber,
                        arabic: arabic,
                        translation: translation,
                        transliteration: transliteration,
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Surah ${widget.surahNumber} • Ayat $verseNumber',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNoteDialog(int verseNumber) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Catatan Ayat'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Tulis catatan singkat...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final note = controller.text.trim();
                if (note.isNotEmpty) {
                  await BookmarkService.instance.saveNote(
                    surah: widget.surahNumber,
                    ayah: verseNumber,
                    note: note,
                  );
                  await _loadBookmarks();
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFolderPicker(int verseNumber) async {
    final folders = await BookmarkService.instance.getFolders();
    if (!mounted) return;
    if (!_isBookmarked(verseNumber)) {
      await BookmarkService.instance.toggleBookmark(
        surah: widget.surahNumber,
        ayah: verseNumber,
      );
      await _loadBookmarks();
      if (!mounted) return;
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Pilih Folder'),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.pop(context);
                    _showCreateFolderDialog();
                  },
                ),
              ),
              ListTile(
                title: const Text('Tanpa folder'),
                onTap: () async {
                  Navigator.pop(context);
                  await BookmarkService.instance.assignFolder(
                    surah: widget.surahNumber,
                    ayah: verseNumber,
                    folderId: null,
                  );
                  if (mounted) setState(() {});
                },
              ),
              ...folders.map(
                (folder) => ListTile(
                  title: Text(folder.name),
                  onTap: () async {
                    Navigator.pop(context);
                    await BookmarkService.instance.assignFolder(
                      surah: widget.surahNumber,
                      ayah: verseNumber,
                      folderId: folder.id,
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Contoh: Hafalan',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await BookmarkService.instance.addFolder(name);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog({
    required int verseNumber,
    required String arabic,
    required String translation,
    required String transliteration,
  }) {
    final boundaryKey = GlobalKey();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bagikan Ayat'),
          content: SingleChildScrollView(
            child: RepaintBoundary(
              key: boundaryKey,
              child: _buildShareCard(
                verseNumber: verseNumber,
                arabic: arabic,
                translation: translation,
                transliteration: transliteration,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _captureAndShare(
                  boundaryKey,
                  fileName:
                      'ayah_${widget.surahNumber}_$verseNumber.png',
                  subject:
                      'Surah ${quran.getSurahName(widget.surahNumber)} ayat $verseNumber',
                );
              },
              child: const Text('Bagikan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShareCard({
    required int verseNumber,
    required String arabic,
    required String translation,
    required String transliteration,
  }) {
    final theme = Theme.of(context);
    final title =
        'QS. ${quran.getSurahName(widget.surahNumber)} : $verseNumber';
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            arabic,
            textAlign: TextAlign.right,
            style: _arabicTextStyle(_quranSettings.value, theme).copyWith(
              fontSize: 24,
            ),
          ),
          if (transliteration.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              transliteration,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            translation,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: theme.primaryColor),
              const SizedBox(width: 6),
              Text(
                "Al-Qur'an Lengkap",
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndShare(
    GlobalKey boundaryKey, {
    required String fileName,
    required String subject,
  }) async {
    try {
      final boundary =
          boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Gagal menangkap gambar.');
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal mengonversi gambar.');
      }
      final pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: subject,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan ayat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int verseCount = quran.getVerseCount(widget.surahNumber);
    final settings = _quranSettings.value;
    final needsCustomTranslation =
        TranslationAssetService.instance.requiresAsset(settings.translation);
    if (needsCustomTranslation &&
        (_customTranslationMap == null || _isTranslationLoading)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(quran.getSurahName(widget.surahNumber)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(quran.getSurahName(widget.surahNumber)),
        actions: [
          IconButton(
            onPressed: _showDisplaySettingsSheet,
            icon: const Icon(Icons.text_fields),
            tooltip: "Tampilan",
          ),
          IconButton(
            onPressed: _isLoading ? null : _playPause,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            tooltip: "Audio",
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmark ayat segera hadir.')),
              );
            },
            icon: const Icon(Icons.bookmark_border),
            tooltip: "Bookmark",
          ),
          IconButton(
            onPressed: _showReaderMoreSheet,
            icon: const Icon(Icons.more_horiz),
            tooltip: "Lainnya",
          ),
        ],
      ),
      bottomNavigationBar:
          (_isPlaying || _isLoading) ? _buildMiniPlayer() : null,
      body: Column(
        children: [
          // Basmalah Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                  style: _arabicTextStyle(_quranSettings.value, Theme.of(context))
                      .copyWith(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
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
                final rawTranslation = needsCustomTranslation
                    ? (_customTranslationMap?[verseKey] ?? '')
                    : settings.translation == TranslationSource.enSaheeh
                        ? quran.getVerseTranslation(
                            widget.surahNumber,
                            verseNumber,
                            translation: quran.Translation.enSaheeh,
                          )
                        : AlQuran.translation(
                            _translationType(settings.translation),
                            verseKey,
                          ).text;
                final translationText = _sanitizeTranslation(rawTranslation);
                final transliterationText = settings.showLatin
                    ? _decodeHtml(AlQuran.transliteration(verseKey).text)
                    : '';
                return InkWell(
                  onTap: () => _handleVerseTap(
                    verseNumber: verseNumber,
                    arabic: verseText,
                    translation: translationText,
                    transliteration: transliterationText,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: _highlightVerse == verseNumber
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.08)
                          : null,
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
                              IconButton(
                                onPressed: () => _showShareDialog(
                                  verseNumber: verseNumber,
                                  arabic: verseText,
                                  translation: translationText,
                                  transliteration: transliterationText,
                                ),
                                icon: Icon(
                                  Icons.share_outlined,
                                  size: 20,
                                  color: Colors.grey[400],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _toggleBookmark(verseNumber),
                                icon: Icon(
                                  _isBookmarked(verseNumber)
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  size: 20,
                                  color: _isBookmarked(verseNumber)
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[400],
                                ),
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
                          settings: settings,
                        ),
                        if (settings.showLatin && transliterationText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              transliterationText,
                              style: GoogleFonts.poppins(
                                fontSize: math.max(
                                  12,
                                  settings.translationFontSize - 2,
                                ),
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
                            fontSize: settings.translationFontSize,
                            height: 1.6,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (settings.showWordByWord)
                          _buildWordByWordSection(
                            verseNumber: verseNumber,
                            showLatin: settings.showLatin,
                            language: settings.translation.language,
                          ),
                      ],
                    ),
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

class _JuzStart {
  final int surah;
  final int ayah;

  const _JuzStart(this.surah, this.ayah);
}

class _BookmarkData {
  final List<BookmarkItem> bookmarks;
  final List<BookmarkFolder> folders;

  const _BookmarkData({required this.bookmarks, required this.folders});
}
