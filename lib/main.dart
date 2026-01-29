import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'core/theme/app_theme.dart';
import 'core/settings/theme_settings.dart';
import 'core/settings/quran_settings.dart';
import 'features/home/presentation/bloc/home_cubit.dart';
import 'features/quran/presentation/pages/quran_page.dart';
import 'features/prayer_times/presentation/pages/prayer_times_page.dart';
import 'features/prayer_times/presentation/widgets/prayer_times_summary_card.dart';
import 'features/qibla/presentation/pages/qibla_page.dart';
import 'features/doa/presentation/pages/doa_page.dart';
import 'features/prayer_guide/presentation/pages/prayer_guide_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/asmaul_husna/presentation/pages/asmaul_husna_page.dart';
import 'features/sholat/presentation/pages/sholat_page.dart';
import 'features/more/presentation/pages/more_page.dart';
import 'core/services/prayer_notification_service.dart';
import 'core/services/last_read_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/onboarding/presentation/pages/onboarding_welcome_page.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await getIt<PrayerNotificationService>().initialize();
  await getIt<ThemeSettingsController>().load();
  await getIt<QuranSettingsController>().load();
  runApp(const QuranApp());
}

class QuranApp extends StatefulWidget {
  const QuranApp({super.key});

  @override
  State<QuranApp> createState() => _QuranAppState();
}

class _QuranAppState extends State<QuranApp> {
  final ThemeSettingsController _themeSettings = getIt<ThemeSettingsController>();

  @override
  void initState() {
    super.initState();
    // Loaded in main()
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeSettings,
      builder: (context, _) {
        final mode = _themeSettings.value.mode;
        final ThemeMode themeMode = mode == AppThemeMode.dark
            ? ThemeMode.dark
            : ThemeMode.light;
        final ThemeData lightTheme =
            mode == AppThemeMode.sepia ? AppTheme.sepiaTheme : AppTheme.lightTheme;
        return MaterialApp(
          title: 'Al-Quran Terjemahan',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
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
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final finished = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            finished ? const DashboardScreen() : const OnboardingWelcomePage(),
      ),
    );
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
    BlocProvider(
      create: (_) => getIt<HomeCubit>()..fetchInitialData(),
      child: const HomePage(),
    ),
    const QuranPage(),
    const SholatPage(),
    const DoaPage(),
    const MorePage(),
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
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: 'Sholat',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism),
            label: 'Doa',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Lainnya',
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
        title: const Text("Beranda"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuranPage()),
              );
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeError) {
            return Center(child: Text(state.message));
          }
          if (state is HomeLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationHeader(context, state.locationLabel),
                  const PrayerTimesSummaryCard(),
                  const SizedBox(height: 16),
                  _buildContinueReadingCard(context, state.lastRead),
                  const SizedBox(height: 20),
                  Text("Aksi Cepat", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 0.95,
                    children: [
                      _buildMenuIcon(context, Icons.book, "Al-Quran", () {
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
                  const SizedBox(height: 20),
                  Text("Hari Ini", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildDailyHighlightCard(context, state),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildLocationHeader(BuildContext context, String locationLabel) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrayerTimesPage()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locationLabel,
                style: Theme.of(context).textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueReadingCard(BuildContext context, LastRead? lastRead) {
    final hasLastRead = lastRead != null;
    final surahName =
        hasLastRead ? quran.getSurahName(lastRead.surah) : '';
    final totalVerses =
        hasLastRead ? quran.getVerseCount(lastRead.surah) : 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.bookmark_border,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lanjutkan Bacaan",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasLastRead
                        ? '$surahName • Ayat ${lastRead.ayah} / $totalVerses'
                        : "Belum ada bacaan tersimpan",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                if (!hasLastRead) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuranPage()),
                  ).then((_) => context.read<HomeCubit>().fetchInitialData());
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurahDetailPage(
                      surahNumber: lastRead.surah,
                      initialVerse: lastRead.ayah,
                    ),
                  ),
                ).then((_) => context.read<HomeCubit>().fetchInitialData());
              },
              child: const Text("Lanjut"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyHighlightCard(BuildContext context, HomeLoaded state) {
    final verse = state.dailyVerse;
    final isLoading = state.isDailyVerseLoading;
    final isBookmarked =
        verse != null && state.bookmarkKeys.contains('${verse.surah}:${verse.ayah}');

    _toggleDailyVerseBookmark(DailyVerse verse) async {
      final messenger = ScaffoldMessenger.of(context);
      final wasBookmarked = isBookmarked;
      await context.read<HomeCubit>().toggleDailyVerseBookmark(verse);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasBookmarked ? 'Bookmark dihapus.' : 'Bookmark disimpan.',
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ayat pilihan hari ini",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              )
            else if (verse == null)
              Text(
                "Bacaan singkat untuk menjaga ketenangan hari ini.",
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              Text(
                verse.arabic,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (verse.translation.isNotEmpty)
                Text(
                  verse.translation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 6),
              Text(
                '${quran.getSurahName(verse.surah)} • Ayat ${verse.ayah}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: verse == null
                      ? null
                      : () => _toggleDailyVerseBookmark(verse),
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                  ),
                  label: Text(isBookmarked ? "Tersimpan" : "Simpan"),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: verse == null
                      ? null
                      : () => Share.share(_dailyVerseShareText(verse)),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text("Bagikan"),
                ),
              ],
            )
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
              color: Theme.of(context).primaryColor.withOpacity(0.1),
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

String _dailyVerseShareText(DailyVerse verse) {
  final buffer = StringBuffer()
    ..writeln('Ayat pilihan hari ini')
    ..writeln()
    ..writeln(verse.arabic);
  if (verse.translation.isNotEmpty) {
    buffer..writeln()..writeln(verse.translation);
  }
  buffer
    ..writeln()
    ..writeln('${quran.getSurahName(verse.surah)} • Ayat ${verse.ayah}');
  return buffer.toString().trim();
}
