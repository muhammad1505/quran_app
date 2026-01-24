import 'package:flutter/material.dart';

import 'package:quran_app/features/onboarding/presentation/pages/onboarding_location_page.dart';

class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'Al-Quran Terjemahan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Al-Qur\'an & Ibadah Harian',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Tenang, rapi, dan fokus untuk ibadah harian Anda.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingLocationPage(),
                      ),
                    );
                  },
                  child: const Text('Mulai'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
