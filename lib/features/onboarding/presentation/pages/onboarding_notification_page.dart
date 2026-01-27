import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/core/di/injection.dart';
import 'package:quran_app/core/services/prayer_notification_service.dart';
import 'package:quran_app/main.dart';

class OnboardingNotificationPage extends StatefulWidget {
  const OnboardingNotificationPage({super.key});

  @override
  State<OnboardingNotificationPage> createState() =>
      _OnboardingNotificationPageState();
}

class _OnboardingNotificationPageState
    extends State<OnboardingNotificationPage> {
  bool _enabled = true;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _enabled);
    await prefs.setBool('onboarding_done', true);
    if (_enabled) {
      await getIt<PrayerNotificationService>().requestPermissions();
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi Adzan')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifikasi Adzan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Dapatkan pengingat waktu sholat.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Aktifkan notifikasi'),
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Aktifkan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
