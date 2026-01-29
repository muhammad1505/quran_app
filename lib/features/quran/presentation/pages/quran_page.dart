import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:alfurqan/alfurqan.dart';
import 'package:alfurqan/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/di/injection.dart';
import 'package:quran_app/core/services/bookmark_service.dart';
import 'package:quran_app/core/services/last_read_service.dart';
import 'package:quran_app/core/services/translation_service.dart';
import 'package:quran_app/core/services/word_by_word_service.dart';
import 'package:quran_app/core/settings/quran_settings.dart';
import 'package:quran_app/core/settings/theme_settings.dart';
import 'package:quran_app/features/quran/presentation/bloc/audio/quran_audio_cubit.dart';
import 'package:quran_app/features/quran/presentation/bloc/audio/quran_audio_state.dart';
import 'package:quran_app/features/quran/presentation/bloc/bookmark/bookmark_cubit.dart';
import 'package:quran_app/features/quran/presentation/bloc/search/search_cubit.dart';
import 'package:quran_app/features/quran/presentation/pages/tafsir_page.dart';
import 'package:quran_app/features/quran/presentation/widgets/audio_player_sheet.dart';
import 'package:quran_app/features/quran/presentation/widgets/display_settings_sheet.dart';
import 'package:share_plus/share_plus.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final TextEditingController _searchController = TextEditingController();
  final QuranSettingsController _quranSettings =
      getIt<QuranSettingsController>();
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
  void initState() {
    super.initState();
    _quranSettings.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        body: MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => getIt<SearchCubit>()),
            BlocProvider(
              create: (context) => getIt<BookmarkCubit>()..loadBookmarks(),
            ),
          ],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    context.read<SearchCubit>().search(value);
                    context.read<BookmarkCubit>().search(value);
                    setState(() {}); // To rebuild the Juz list
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Cari surah, juz, atau kata terjemahan…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey.withAlpha(51),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey.withAlpha(51),
                      ),
                    ),
                  ),
                ),
              ),
              BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildSurahList(),
                    _buildJuzList(),
                    _buildBookmarkList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahList() {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (state is SearchLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<int> items = [];
        if (state is SearchInitial) {
          items = state.surahNumbers;
        } else if (state is SearchLoaded) {
          items = state.surahNumbers;
        }

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
                    color: Theme.of(context).primaryColor.withAlpha(26),
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
      },
    );
  }

  Widget _buildJuzList() {
    final normalized = _searchController.text.toLowerCase().trim();
    final filtered = _juzStarts.where((start) {
      if (normalized.isEmpty) return true;
      final juz = _juzStarts.indexOf(start) + 1;
      final label = 'juz $juz';
      return label.contains(normalized) || juz.toString() == normalized;
    }).toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final start = filtered[index];
        final juz = _juzStarts.indexOf(start) + 1;
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

  Widget _buildBookmarkList() {
    return BlocBuilder<BookmarkCubit, BookmarkState>(
      builder: (context, state) {
        if (state is! BookmarkLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = state.filteredBookmarks;
        final folders = state.allFolders;

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark_border, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    state.showNotesOnly
                        ? 'Belum ada catatan'
                        : 'Belum ada bookmark',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.showNotesOnly
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
                  onPressed: () =>
                      _showCreateFolderDialog(context.read<BookmarkCubit>()),
                  icon:
                      const Icon(Icons.create_new_folder_outlined, size: 18),
                  label: const Text('Folder'),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Favorit')),
                    ButtonSegment(value: true, label: Text('Catatan')),
                  ],
                  selected: {state.showNotesOnly},
                  onSelectionChanged: (_) =>
                      context.read<BookmarkCubit>().toggleShowNotesOnly(),
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
                        selected: state.selectedFolderId == null,
                        onSelected: (_) =>
                            context.read<BookmarkCubit>().selectFolder(null),
                      );
                    }
                    final folder = folders[index - 1];
                    return ChoiceChip(
                      label: Text(folder.name),
                      selected: state.selectedFolderId == folder.id,
                      onSelected: (_) => context
                          .read<BookmarkCubit>()
                          .selectFolder(folder.id),
                    );
                  },
                ),
              ),
            if (folders.isNotEmpty) const SizedBox(height: 12),
            ...items.map((item) {
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
                    ).then((_) => context.read<BookmarkCubit>().loadBookmarks());
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _showCreateFolderDialog(BookmarkCubit cubit) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Folder Baru'),
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
              await cubit.addFolder(name);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class SurahDetailPage extends StatelessWidget {
  final int surahNumber;
  final int? initialVerse;

  const SurahDetailPage({
    super.key,
    required this.surahNumber,
    this.initialVerse,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<QuranAudioCubit>()..loadSurah(surahNumber, initialVerse),
      child: _SurahDetailView(
        surahNumber: surahNumber,
        initialVerse: initialVerse,
      ),
    );
  }
}

class _SurahDetailView extends StatefulWidget {
  final int surahNumber;
  final int? initialVerse;
  const _SurahDetailView({required this.surahNumber, this.initialVerse});

  @override
  State<_SurahDetailView> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<_SurahDetailView> {
  late final ScrollController _scrollController;
  Map<String, String>? _customTranslationMap;
  TranslationSource? _customTranslationSource;
  bool _isTranslationLoading = false;
  Set<String> _bookmarkKeys = {};
  int? _highlightVerse;

  final QuranSettingsController _quranSettings =
      getIt<QuranSettingsController>();
  final ThemeSettingsController _themeSettings =
      getIt<ThemeSettingsController>();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _estimateScrollOffset(widget.initialVerse),
    );
    _highlightVerse = widget.initialVerse;

    _quranSettings.addListener(_onSettingsChanged);
    _themeSettings.addListener(_onSettingsChanged);
    _maybeLoadCustomTranslation();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _quranSettings.removeListener(_onSettingsChanged);
    _themeSettings.removeListener(_onSettingsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    _maybeLoadCustomTranslation();
    if (mounted) {
      setState(() {});
    }
  }

  double _estimateScrollOffset(int? verse) {
    if (verse == null || verse <= 1) return 0;
    const approxItemExtent = 190.0;
    return math.max(0, (verse - 1) * approxItemExtent);
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
          return const SizedBox.shrink();
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          textDirection: TextDirection.rtl,
          children: words.map((w) => _buildWordChip(w, showLatin)).toList(),
        );
      },
    );
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
      if (mounted) {
        setState(() {
          _customTranslationMap = null;
          _customTranslationSource = null;
          _isTranslationLoading = false;
        });
      }
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

  void _showDisplaySettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const QuranDisplaySettingsSheet();
      },
    );
  }

  void _showReaderMoreSheet(
    BuildContext context,
    QuranAudioState state,
    QuranAudioCubit cubit,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final currentVerse = state.currentVerse ?? _highlightVerse ?? 1;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: state.downloadStatus == DownloadStatus.downloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        state.downloadStatus == DownloadStatus.downloaded
                            ? Icons.check_circle
                            : Icons.download,
                      ),
                title: Text(
                  state.downloadStatus == DownloadStatus.downloaded
                      ? 'Hapus audio offline'
                      : 'Unduh audio offline',
                ),
                onTap: state.downloadStatus == DownloadStatus.downloading
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await cubit.toggleDownload();
                      },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: Text(
                  _isBookmarked(currentVerse)
                      ? 'Hapus bookmark'
                      : 'Simpan bookmark',
                ),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final wasBookmarked = _isBookmarked(currentVerse);
                  navigator.pop();
                  await _toggleBookmark(currentVerse);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        wasBookmarked
                            ? 'Bookmark dihapus.'
                            : 'Bookmark disimpan.',
                      ),
                    ),
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
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quran.getSurahName(widget.surahNumber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quran.getSurahNameArabic(widget.surahNumber),
              style: GoogleFonts.amiri(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              '${quran.getPlaceOfRevelation(widget.surahNumber)[0].toUpperCase()}${quran.getPlaceOfRevelation(widget.surahNumber).substring(1)} • ${quran.getVerseCount(widget.surahNumber)} ayat',
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

  Widget _buildWordChip(WordByWordItem word, bool showLatin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(51)),
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

  Widget _buildMiniPlayer(
    BuildContext context,
    QuranAudioState state,
    QuranAudioCubit cubit,
  ) {
    return Material(
      color: Theme.of(context).cardTheme.color ?? Colors.white,
      child: InkWell(
        onTap: () => _showAudioPlayerSheet(context, state, cubit),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
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
                  state.isAyahMode
                      ? 'Ayat ${state.currentVerse!} • ${quran.getSurahName(cubit.surahNumber)}'
                      : 'Murotal ${quran.getSurahName(cubit.surahNumber)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (state.isAyahMode) ...[
                IconButton(
                  onPressed: cubit.playPreviousVerse,
                  icon: const Icon(Icons.skip_previous),
                  tooltip: 'Ayat sebelumnya',
                ),
                IconButton(
                  onPressed: cubit.playNextVerse,
                  icon: const Icon(Icons.skip_next),
                  tooltip: 'Ayat berikutnya',
                ),
              ],
              IconButton(
                onPressed: cubit.toggleRepeat,
                icon: Icon(
                  state.isRepeatOne ? Icons.repeat_one : Icons.repeat,
                  color:
                      state.isRepeatOne ? Theme.of(context).primaryColor : null,
                ),
                tooltip:
                    state.isRepeatOne ? 'Ulangi ayat' : 'Jangan ulangi ayat',
              ),
              PopupMenuButton<double>(
                onSelected: cubit.setPlaybackSpeed,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 0.75, child: Text('0.75x')),
                  PopupMenuItem(value: 1.0, child: Text('1.0x')),
                  PopupMenuItem(value: 1.25, child: Text('1.25x')),
                  PopupMenuItem(value: 1.5, child: Text('1.5x')),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).primaryColor.withAlpha(26),
                  ),
                  child: Text(
                    '${state.playbackSpeed.toStringAsFixed(2).replaceAll('.00', '')}x',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed:
                    state.status == PlayerStatus.loading ? null : cubit.playPause,
                icon: Icon(
                  state.status == PlayerStatus.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAudioPlayerSheet(
    BuildContext context,
    QuranAudioState state,
    QuranAudioCubit cubit,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return QuranAudioPlayerSheet(
          surahNumber: cubit.surahNumber,
          isAyahMode: state.isAyahMode,
          currentAyah: state.currentVerse,
          isPlaying: state.status == PlayerStatus.playing,
          isLoading: state.status == PlayerStatus.loading,
          repeatOne: state.isRepeatOne,
          speed: state.playbackSpeed,
          onPlayPause: cubit.playPause,
          onNextAyah: state.isAyahMode ? cubit.playNextVerse : null,
          onPrevAyah: state.isAyahMode ? cubit.playPreviousVerse : null,
          onToggleRepeat: cubit.toggleRepeat,
          onSpeedChanged: cubit.setPlaybackSpeed,
        );
      },
    );
  }

  Future<void> _handleVerseTap({
    required int verseNumber,
    required String arabic,
    required String translation,
    required String transliteration,
  }) async {
    context.read<QuranAudioCubit>().setHighlight(verseNumber);
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
    final cubit = context.read<QuranAudioCubit>();
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
                  cubit.playVerse(widget.surahNumber, verseNumber);
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
        color: theme.colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(51)),
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
                "Al-Quran Terjemahan",
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
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      // Tunggu dialog merender konten sepenuhnya (wait for dialog animation)
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;

      // Ensure frame is drawn
      await WidgetsBinding.instance.endOfFrame;

      final contextObject = boundaryKey.currentContext;
      if (contextObject == null) {
        throw Exception('Gagal menangkap gambar: Context null.');
      }

      RenderRepaintBoundary? boundary =
          contextObject.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Gagal menangkap gambar: RenderObject null.');
      }

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;
        await WidgetsBinding.instance.endOfFrame;
      }

      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Gagal mengonversi gambar.');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      try {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: subject,
        );
      } catch (e) {
        // Abaikan error spesifik share sheet yang sering terjadi tapi tidak fatal
        if (e.toString().contains('LateInitializationError') ||
            e.toString().contains('localResult')) {
          return;
        }
        rethrow;
      }
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text('Gagal membagikan ayat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuranAudioCubit, QuranAudioState>(
      listener: (context, state) {
        if (state.highlightVerse != null &&
            state.highlightVerse != _highlightVerse) {
          setState(() {
            _highlightVerse = state.highlightVerse;
          });
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<QuranAudioCubit>();
        final surahNumber = cubit.surahNumber;
        final int verseCount = quran.getVerseCount(surahNumber);
        final settings = _quranSettings.value;
        final needsCustomTranslation =
            TranslationAssetService.instance.requiresAsset(settings.translation);

        if (needsCustomTranslation &&
            (_customTranslationMap == null || _isTranslationLoading)) {
          return Scaffold(
            appBar: AppBar(title: Text(quran.getSurahName(surahNumber))),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final currentVerse = state.currentVerse ?? _highlightVerse ?? 1;
        final isBookmarked = _isBookmarked(currentVerse);

        return Scaffold(
          appBar: AppBar(
            title: Text(quran.getSurahName(surahNumber)),
            actions: [
              IconButton(
                onPressed: _showDisplaySettingsSheet,
                icon: const Icon(Icons.text_fields),
                tooltip: "Tampilan",
              ),
              IconButton(
                onPressed:
                    state.status == PlayerStatus.loading ? null : cubit.playPause,
                icon: state.status == PlayerStatus.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        state.status == PlayerStatus.playing
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                tooltip: "Audio",
              ),
              IconButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final wasBookmarked = isBookmarked;
                  await _toggleBookmark(currentVerse);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        wasBookmarked
                            ? 'Bookmark dihapus.'
                            : 'Bookmark disimpan.',
                      ),
                    ),
                  );
                },
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
                tooltip: isBookmarked ? "Hapus Bookmark" : "Simpan Bookmark",
              ),
              IconButton(
                onPressed: () => _showReaderMoreSheet(context, state, cubit),
                icon: const Icon(Icons.more_horiz),
                tooltip: "Lainnya",
              ),
            ],
          ),
          bottomNavigationBar: state.showPlayer ? _buildMiniPlayer(context, state, cubit) : null,
          body: Column(
            children: [
              // Basmalah Header
              if (surahNumber != 1 && surahNumber != 9)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                        style: _arabicTextStyle(
                          _quranSettings.value,
                          Theme.of(context),
                        ).copyWith(fontSize: 24),
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
                    final verseKey = "$surahNumber:$verseNumber";
                    final verseText = AlQuran.verse(
                      surahNumber,
                      verseNumber,
                      mode: settings.showTajwid
                          ? VerseMode.uthmaniTajweed
                          : VerseMode.uthmani,
                    ).text;
                    final rawTranslation = needsCustomTranslation
                        ? (_customTranslationMap?[verseKey] ?? '')
                        : settings.translation == TranslationSource.enSaheeh
                            ? quran.getVerseTranslation(
                                surahNumber,
                                verseNumber,
                                translation: quran.Translation.enSaheeh,
                              )
                            : AlQuran.translation(
                                _translationType(settings.translation),
                                verseKey,
                              ).text;
                    final translationText =
                        _sanitizeTranslation(rawTranslation);
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
                              ? Theme.of(context).primaryColor.withAlpha(20)
                              : null,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withAlpha(26),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withAlpha(26),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        "Ayat $verseNumber",
                                        style: TextStyle(
                                          color:
                                              Theme.of(context).primaryColor,
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
                                        transliteration:
                                            transliterationText,
                                      ),
                                      icon: Icon(
                                        Icons.share_outlined,
                                        size: 20,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _toggleBookmark(verseNumber),
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
                            if (settings.showLatin &&
                                transliterationText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  transliterationText,
                                  style: GoogleFonts.poppins(
                                    fontSize: math.max(
                                      12,
                                      settings.translationFontSize - 2,
                                    ),
                                    height:
                                        settings.translationLineHeight,
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
                                height: settings.translationLineHeight,
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
      },
    );
  }
}

class _JuzStart {
  final int surah;
  final int ayah;

  const _JuzStart(this.surah, this.ayah);
}



