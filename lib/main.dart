import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/quran/presentation/pages/quran_page.dart';
import 'features/prayer_times/presentation/pages/prayer_times_page.dart';
import 'features/qibla/presentation/pages/qibla_page.dart';
import 'features/doa/presentation/pages/doa_page.dart';
import 'features/prayer_guide/presentation/pages/prayer_guide_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/asmaul_husna/presentation/pages/asmaul_husna_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al-Quran Terjemahan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/splash.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const QuranPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Al-Quran',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Al-Quran Terjemahan"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Widget (Prayer Times Shortcut)
            const SizedBox(
              height: 200,
              child:
                  PrayerTimesPage(), // We embed the Prayer Times widget here directly or refactor it
            ),
            const SizedBox(height: 20),
            Text("Menu Utama", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 0.8,
              children: [
                _buildMenuIcon(context, Icons.book, "Al-Quran", () {
                  // Switch to tab 1 (Quran) - Need a way to control parent state or just push
                  // For now, let's push for simplicity or access ancestor
                  // Better: Push new route for full screen focus
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuranPage()),
                  );
                }),
                _buildMenuIcon(context, Icons.access_time_filled, "Jadwal", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Scaffold(body: PrayerTimesPage()),
                    ),
                  );
                }),
                _buildMenuIcon(context, Icons.explore, "Kiblat", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QiblaPage()),
                  );
                }),
                _buildMenuIcon(context, Icons.volunteer_activism, "Doa", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoaPage()),
                  );
                }),
                _buildMenuIcon(context, Icons.mosque, "Sholat", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrayerGuidePage()),
                  );
                }),
                _buildMenuIcon(context, Icons.auto_awesome, "Asmaul", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AsmaulHusnaPage()),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
