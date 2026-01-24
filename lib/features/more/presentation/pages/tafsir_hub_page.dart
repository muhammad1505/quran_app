import 'package:flutter/material.dart';

import 'package:quran_app/core/settings/quran_settings.dart';
import 'package:quran_app/features/quran/presentation/pages/quran_page.dart';
import 'package:quran_app/features/settings/presentation/pages/settings_page.dart';

class TafsirHubPage extends StatefulWidget {
  const TafsirHubPage({super.key});

  @override
  State<TafsirHubPage> createState() => _TafsirHubPageState();
}

class _TafsirHubPageState extends State<TafsirHubPage> {
  final QuranSettingsController _quranSettings =
      QuranSettingsController.instance;

  @override
  void initState() {
    super.initState();
    _quranSettings.addListener(_onSettingsChanged);
    _quranSettings.load();
  }

  @override
  void dispose() {
    _quranSettings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tafsir')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Sumber Tafsir'),
              subtitle: Text(_quranSettings.value.tafsirSource.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Baca Tafsir di Reader'),
              subtitle:
                  const Text('Buka surah lalu pilih ayat untuk melihat tafsir.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuranPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tips',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Gunakan menu “Tafsir ringkas” di aksi ayat untuk membaca penjelasan singkat. Jika ingin lengkap, pilih sumber tafsir di Pengaturan.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
