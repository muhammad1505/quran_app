import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/features/onboarding/presentation/pages/onboarding_notification_page.dart';

class OnboardingLocationPage extends StatelessWidget {
  const OnboardingLocationPage({super.key});

  Future<void> _requestLocation(BuildContext context) async {
    final status = await Permission.locationWhenInUse.request();
    if (!context.mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi bisa diaktifkan nanti.')),
      );
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OnboardingNotificationPage(),
      ),
    );
  }

  Future<void> _pickManualCity(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Kota Manual'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Contoh: Bandung',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      final locations = await locationFromAddress(result);
      if (locations.isEmpty) throw Exception('Lokasi tidak ditemukan');
      final location = locations.first;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('manual_location_enabled', true);
      await prefs.setString('manual_location_name', result);
      await prefs.setDouble('last_lat', location.latitude);
      await prefs.setDouble('last_lng', location.longitude);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingNotificationPage(),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menemukan lokasi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akses Lokasi')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Akses Lokasi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Untuk jadwal sholat & kiblat yang akurat.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _requestLocation(context),
                  child: const Text('Izinkan Lokasi'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _pickManualCity(context),
                  child: const Text('Pilih kota manual'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
