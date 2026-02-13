import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alfurqan/alfurqan.dart';

import 'package:quran_app/core/services/tafsir_service.dart';
import 'package:quran_app/core/di/injection.dart';
import 'package:quran_app/core/settings/quran_settings.dart';

class TafsirPage extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final String arabic;
  final String translation;
  final String transliteration;

  const TafsirPage({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    required this.arabic,
    required this.translation,
    required this.transliteration,
  });

  @override
  State<TafsirPage> createState() => _TafsirPageState();
}

class _TafsirPageState extends State<TafsirPage> {
  late final TafsirService _tafsirService;

  @override
  void initState() {
    super.initState();
    _tafsirService = getIt<TafsirService>();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        '${AlQuran.chapter(widget.surahNumber).nameSimple} : ${widget.verseNumber}';
    final settings = getIt<QuranSettingsController>().value;
    final future = _tafsirService.getTafsir(
      surah: widget.surahNumber,
      ayah: widget.verseNumber,
      source: settings.tafsirSource,
    );
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Tafsir $title'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ringkas'),
              Tab(text: 'Lengkap'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FutureBuilder<TafsirEntry?>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _TafsirSection(
                    arabic: widget.arabic,
                    transliteration: widget.transliteration,
                    content: widget.translation,
                    sourceLabel: 'Gagal memuat tafsir. Menampilkan terjemahan.',
                  );
                }
                final entry = snapshot.data;
                final content = entry?.short?.isNotEmpty == true
                    ? entry!.short!
                    : (entry?.long?.isNotEmpty == true
                        ? entry!.long!
                        : widget.translation);
                final label = entry?.sourceLabel ??
                    'Terjemahan sebagai ringkasan tafsir';
                return _TafsirSection(
                  arabic: widget.arabic,
                  transliteration: widget.transliteration,
                  content: content,
                  sourceLabel: label,
                );
              },
            ),
            FutureBuilder<TafsirEntry?>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _TafsirSection(
                    arabic: widget.arabic,
                    transliteration: widget.transliteration,
                    content: 'Gagal memuat tafsir lengkap.',
                    sourceLabel: 'Periksa koneksi atau pilih sumber lain.',
                  );
                }
                final entry = snapshot.data;
                final content = entry?.long?.isNotEmpty == true
                    ? entry!.long!
                    : (entry?.short?.isNotEmpty == true
                        ? entry!.short!
                        : 'Tafsir lengkap belum tersedia.');
                final label = entry?.sourceLabel ??
                    'Tambahkan tafsir offline atau pilih sumber online.';
                return _TafsirSection(
                  arabic: widget.arabic,
                  transliteration: widget.transliteration,
                  content: content,
                  sourceLabel: label,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TafsirSection extends StatelessWidget {
  final String arabic;
  final String transliteration;
  final String content;
  final String sourceLabel;

  const _TafsirSection({
    required this.arabic,
    required this.transliteration,
    required this.content,
    required this.sourceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final settings = getIt<QuranSettingsController>().value;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          arabic,
          textAlign: TextAlign.right,
          style: _arabicStyle(settings, context).copyWith(fontSize: 28),
        ),
        if (transliteration.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(transliteration, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text(
          sourceLabel,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }

  TextStyle _arabicStyle(QuranSettings settings, BuildContext context) {
    switch (settings.arabicFontFamily) {
      case ArabicFontFamily.scheherazade:
        return GoogleFonts.scheherazadeNew(
          fontSize: settings.arabicFontSize,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        );
      case ArabicFontFamily.lateef:
        return GoogleFonts.lateef(
          fontSize: settings.arabicFontSize,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        );
      case ArabicFontFamily.amiri:
        return GoogleFonts.amiri(
          fontSize: settings.arabicFontSize,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        );
    }
  }
}
