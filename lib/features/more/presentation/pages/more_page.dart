import 'package:flutter/material.dart';

import 'package:quran_app/features/offline/presentation/pages/offline_manager_page.dart';
import 'package:quran_app/features/settings/presentation/pages/settings_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTile(
            context,
            icon: Icons.download_for_offline,
            title: 'Unduhan Offline',
            subtitle: 'Kelola audio dan teks offline',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfflineManagerPage(),
                ),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.menu_book,
            title: 'Tafsir',
            subtitle: 'Ringkas & lengkap (segera hadir)',
            onTap: () => _comingSoon(context),
          ),
          _buildTile(
            context,
            icon: Icons.article_outlined,
            title: 'Artikel Panduan',
            subtitle: 'Wudhu, tayammum, adab (segera hadir)',
            onTap: () => _comingSoon(context),
          ),
          _buildTile(
            context,
            icon: Icons.settings,
            title: 'Pengaturan',
            subtitle: 'Tampilan, sholat, audio, offline',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.support_agent,
            title: 'Bantuan & Feedback',
            subtitle: 'Laporkan bug atau saran',
            onTap: () => _comingSoon(context),
          ),
          _buildTile(
            context,
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: 'Informasi versi dan lisensi',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Al-Qur\'an Lengkap',
                applicationVersion: 'v1.0.0',
                applicationLegalese: '© 2026 Quran App',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur ini akan hadir segera.')),
    );
  }
}
