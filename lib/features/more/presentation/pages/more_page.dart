import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:quran_app/features/more/presentation/pages/articles_page.dart';
import 'package:quran_app/features/more/presentation/pages/help_feedback_page.dart';
import 'package:quran_app/features/more/presentation/pages/tafsir_hub_page.dart';
import 'package:quran_app/features/offline/presentation/pages/offline_manager_page.dart';
import 'package:quran_app/features/settings/presentation/pages/settings_page.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}';
      });
    }
  }

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
            subtitle: 'Ringkas & lengkap',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TafsirHubPage()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.article_outlined,
            title: 'Artikel Panduan',
            subtitle: 'Wudhu, tayammum, adab',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArticlesPage()),
              );
            },
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpFeedbackPage()),
              );
            },
          ),
          _buildTile(
            context,
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: 'Informasi versi dan lisensi',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Al-Quran Terjemahan',
                applicationVersion: _appVersion,
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
}
