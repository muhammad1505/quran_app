import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quran_app/core/services/asmaul_husna_service.dart';

class AsmaulDetailPage extends StatelessWidget {
  final AsmaulHusnaItem item;
  final bool showEnglish;

  const AsmaulDetailPage({
    super.key,
    required this.item,
    this.showEnglish = false,
  });

  @override
  Widget build(BuildContext context) {
    final meaning = showEnglish ? item.meaningEn : item.meaningId;
    return Scaffold(
      appBar: AppBar(
        title: Text(item.transliteration),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Text(
              item.arabic,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 36,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              item.transliteration,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Makna',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            meaning,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Penjelasan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Nama ini mengingatkan kita akan sifat ${item.transliteration} yang mengandung makna “$meaning”. Jadikan nama ini sebagai dzikir untuk menumbuhkan ketenangan dan ketakwaan dalam keseharian.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Audio pelafalan segera hadir.')),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Putar Audio'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bagikan segera hadir.')),
                    );
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Bagikan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
