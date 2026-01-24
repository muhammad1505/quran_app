import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quran_app/core/services/asmaul_husna_service.dart';
import 'package:quran_app/core/services/tts_service.dart';
import 'package:quran_app/features/asmaul_husna/presentation/pages/asmaul_detail_page.dart';

class AsmaulHusnaPage extends StatefulWidget {
  const AsmaulHusnaPage({super.key});

  @override
  State<AsmaulHusnaPage> createState() => _AsmaulHusnaPageState();
}

class _AsmaulHusnaPageState extends State<AsmaulHusnaPage> {
  bool _showEnglish = false;
  bool _isPlayingAll = false;
  bool _stopRequested = false;

  Future<void> _togglePlayAll(List<AsmaulHusnaItem> items) async {
    if (_isPlayingAll) {
      _stopRequested = true;
      await TtsService.instance.stop();
      if (mounted) {
        setState(() => _isPlayingAll = false);
      }
      return;
    }
    setState(() {
      _isPlayingAll = true;
      _stopRequested = false;
    });
    for (final item in items) {
      if (_stopRequested) break;
      final meaning = _showEnglish ? item.meaningEn : item.meaningId;
      final text =
          meaning.isNotEmpty ? '${item.transliteration}. $meaning' : item.transliteration;
      await TtsService.instance.speak(
        text,
        language: _showEnglish ? 'en-US' : 'id-ID',
      );
    }
    if (mounted) {
      setState(() => _isPlayingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Asmaul Husna")),
      body: FutureBuilder<List<AsmaulHusnaItem>>(
        future: AsmaulHusnaService.instance.load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                "Data Asmaul Husna tidak ditemukan",
                style: GoogleFonts.poppins(),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Bahasa Makna",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('ID'),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('EN'),
                            ),
                          ],
                          selected: {_showEnglish},
                          onSelectionChanged: (value) {
                            setState(() => _showEnglish = value.first);
                          },
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _togglePlayAll(items),
                        icon: Icon(
                          _isPlayingAll
                              ? Icons.stop_circle_outlined
                              : Icons.play_circle_outline,
                          size: 18,
                        ),
                        label:
                            Text(_isPlayingAll ? 'Hentikan' : 'Putar semua'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final meaning =
                        _showEnglish ? item.meaningEn : item.meaningId;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AsmaulDetailPage(
                              item: item,
                              showEnglish: _showEnglish,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).cardTheme.color ?? Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.number.toString(),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.arabic,
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.amiri(
                                      fontSize: 24,
                                      height: 1.6,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.transliteration,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  if (meaning.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      meaning,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
