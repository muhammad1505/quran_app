import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/core/services/prayer_notification_service.dart';
import 'package:quran_app/features/prayer_times/presentation/pages/prayer_times_page.dart';
import 'package:quran_app/features/prayer_times/presentation/widgets/prayer_times_summary_card.dart';
import 'package:quran_app/features/qibla/presentation/pages/qibla_page.dart';
import 'package:quran_app/features/prayer_guide/presentation/pages/prayer_guide_page.dart';
import 'package:quran_app/features/more/presentation/pages/articles_page.dart';

class SholatPage extends StatefulWidget {
  const SholatPage({super.key});

  @override
  State<SholatPage> createState() => _SholatPageState();
}

class _SholatPageState extends State<SholatPage> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications');
    if (!mounted) return;
    setState(() => _notificationsEnabled = enabled ?? true);
  }

  Future<void> _setNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    if (!value) {
      await PrayerNotificationService.instance.cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sholat')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Waktu Sholat Hari Ini',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          const PrayerTimesSummaryCard(),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text('Notifikasi Adzan'),
              subtitle: const Text('Aktifkan pengingat waktu sholat'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _setNotificationSetting(value);
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Akses Cepat',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            icon: Icons.access_time_filled,
            title: 'Jadwal Sholat Detail',
            subtitle: 'Lihat jadwal harian, mingguan, dan pengaturan metode',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrayerTimesPage()),
              );
            },
          ),
          _buildActionCard(
            context,
            icon: Icons.explore,
            title: 'Kompas Kiblat',
            subtitle: 'Arah kiblat dan tips kalibrasi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QiblaPage()),
              );
            },
          ),
          _buildActionCard(
            context,
            icon: Icons.mosque,
            title: 'Panduan Sholat',
            subtitle: 'Langkah lengkap dengan bacaan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrayerGuidePage()),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Links',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(context, 'Wudhu'),
              _buildChip(context, 'Bacaan Sholat'),
              _buildChip(context, 'Rakaat Sholat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ArticlesPage()),
        );
      },
    );
  }
}
