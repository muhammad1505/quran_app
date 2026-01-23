import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;

import 'package:quran_app/core/services/tafsir_service.dart';
import 'package:quran_app/core/settings/quran_settings.dart';

class TafsirPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final title =
        '${quran.getSurahName(surahNumber)} : $verseNumber';
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
            _TafsirSection(
              arabic: arabic,
              transliteration: transliteration,
              content: translation,
              sourceLabel: 'Terjemahan sebagai tafsir ringkas',
            ),
            FutureBuilder<String?>(
              future: TafsirService.instance.getTafsir(
                surahNumber,
                verseNumber,
              ),
              builder: (context, snapshot) {
                final tafsir = snapshot.data;
                final content = (tafsir == null || tafsir.isEmpty)
                    ? 'Tafsir lengkap belum tersedia offline.'
                    : tafsir;
                return _TafsirSection(
                  arabic: arabic,
                  transliteration: transliteration,
                  content: content,
                  sourceLabel: tafsir == null || tafsir.isEmpty
                      ? 'Tambahkan assets/tafsir_id.json untuk offline'
                      : 'Tafsir lengkap (offline)',
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
    final settings = QuranSettingsController.instance.value;
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
      default:
        return GoogleFonts.amiri(
          fontSize: settings.arabicFontSize,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        );
    }
  }
}
