import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:alfurqan/alfurqan.dart';
import 'package:alfurqan/constant.dart';
import 'package:share_plus/share_plus.dart';
import 'core/theme/app_theme.dart';
import 'core/settings/theme_settings.dart';
import 'core/settings/quran_settings.dart';
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
import 'core/services/bookmark_service.dart';
import 'core/services/translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/onboarding/presentation/pages/onboarding_welcome_page.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await _initFirebase();
  await getIt<PrayerNotificationService>().initialize();
  runApp(const QuranApp());
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init gagal: $e');
  }
}

class QuranApp extends StatefulWidget {
  const QuranApp({super.key});

  @override
  State<QuranApp> createState() => _QuranAppState();
}

class _QuranAppState extends State<QuranApp> {
  final ThemeSettingsController _themeSettings =
      ThemeSettingsController.instance;

  @override
  void initState() {
    super.initState();
    _themeSettings.load();
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

  final List<Widget> _pages = const [
    HomePage(),
    QuranPage(),
    SholatPage(),
    DoaPage(),
    MorePage(),
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _locationLabel = 'Lokasi otomatis';
  LastRead? _lastRead;
  DailyVerse? _dailyVerse;
  bool _isDailyVerseLoading = false;
  Set<String> _bookmarkKeys = {};
  final QuranSettingsController _quranSettings =
      QuranSettingsController.instance;

  @override
  void initState() {
    super.initState();
    _quranSettings.addListener(_onSettingsChanged);
    _loadLocationLabel();
    _loadLastRead();
    unawaited(_initHome());
    _loadBookmarkKeys();
  }

  @override
  void dispose() {
    _quranSettings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    _loadDailyVerse();
  }

  Future<void> _initHome() async {
    await _quranSettings.load();
    await _loadDailyVerse();
  }

  Future<void> _loadLocationLabel() async {
    final prefs = await SharedPreferences.getInstance();
    final manualEnabled = prefs.getBool('manual_location_enabled') ?? false;
    final manualName = prefs.getString('manual_location_name');
    final lat = prefs.getDouble('last_lat');
    final lng = prefs.getDouble('last_lng');
    if (!mounted) return;
    if (manualEnabled && manualName != null) {
      setState(() => _locationLabel = manualName);
      return;
    }
    if (lat == null || lng == null) {
      setState(() => _locationLabel = 'Aktifkan lokasi untuk akurasi');
      return;
    }
    setState(() {
      _locationLabel = 'Koordinat ${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}';
    });
  }

  Future<void> _loadLastRead() async {
    final lastRead = await LastReadService.instance.getLastRead();
    if (!mounted) return;
    setState(() => _lastRead = lastRead);
  }

  Future<void> _loadBookmarkKeys() async {
    final keys = await BookmarkService.instance.getKeys();
    if (!mounted) return;
    setState(() => _bookmarkKeys = keys);
  }

  Future<void> _loadDailyVerse() async {
    setState(() => _isDailyVerseLoading = true);
    final now = DateTime.now();
    final dayIndex =
        now.difference(DateTime(now.year, 1, 1)).inDays;
    final surah = (dayIndex % 114) + 1;
    final verseCount = quran.getVerseCount(surah);
    final ayah = (dayIndex % verseCount) + 1;
    final arabic = quran.getVerse(surah, ayah);
    String translation = '';
    try {
      translation = await _resolveTranslation(
        _quranSettings.value.translation,
        surah,
        ayah,
      );
    } catch (_) {
      translation = '';
    }
    if (!mounted) return;
    setState(() {
      _dailyVerse = DailyVerse(
        surah: surah,
        ayah: ayah,
        arabic: arabic,
        translation: translation,
      );
      _isDailyVerseLoading = false;
    });
  }

  bool _isDailyVerseBookmarked(DailyVerse verse) {
    return _bookmarkKeys.contains('${verse.surah}:${verse.ayah}');
  }

  Future<void> _toggleDailyVerseBookmark(DailyVerse verse) async {
    final messenger = ScaffoldMessenger.of(context);
    final wasBookmarked = _isDailyVerseBookmarked(verse);
    await BookmarkService.instance.toggleBookmark(
      surah: verse.surah,
      ayah: verse.ayah,
    );
    await _loadBookmarkKeys();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          wasBookmarked ? 'Bookmark dihapus.' : 'Bookmark disimpan.',
        ),
      ),
    );
  }

  Future<String> _resolveTranslation(
    TranslationSource source,
    int surah,
    int ayah,
  ) async {
    if (TranslationAssetService.instance.requiresAsset(source)) {
      final map = await TranslationAssetService.instance.load(source);
      return _sanitizeTranslation(map['$surah:$ayah'] ?? '');
    }
    if (source == TranslationSource.enSaheeh) {
      return _sanitizeTranslation(
        quran.getVerseTranslation(
          surah,
          ayah,
          translation: quran.Translation.enSaheeh,
        ),
      );
    }
    final verseKey = '$surah:$ayah';
    return _sanitizeTranslation(
      AlQuran.translation(
        _translationType(source),
        verseKey,
      ).text,
    );
  }

  TranslationType _translationType(TranslationSource source) {
    switch (source) {
      case TranslationSource.idKemenag:
      case TranslationSource.idKingFahad:
      case TranslationSource.idSabiq:
        return TranslationType.idIndonesianIslamicAffairsMinistry;
      case TranslationSource.enAbdelHaleem:
      case TranslationSource.enSaheeh:
        return TranslationType.enMASAbdelHaleem;
    }
  }

  String _sanitizeTranslation(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationHeader(context),
            const PrayerTimesSummaryCard(),
            const SizedBox(height: 16),
            _buildContinueReadingCard(context),
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
            const SizedBox(height: 20),
            Text("Hari Ini", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildDailyHighlightCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationHeader(BuildContext context) {
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
                _locationLabel,
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

  Widget _buildContinueReadingCard(BuildContext context) {
    final lastRead = _lastRead;
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
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                  ).then((_) => _loadLastRead());
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
                ).then((_) => _loadLastRead());
              },
              child: const Text("Lanjut"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyHighlightCard(BuildContext context) {
    final verse = _dailyVerse;
    final isLoading = _isDailyVerseLoading;
    final isBookmarked =
        verse != null && _isDailyVerseBookmarked(verse);
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

class DailyVerse {
  final int surah;
  final int ayah;
  final String arabic;
  final String translation;

  const DailyVerse({
    required this.surah,
    required this.ayah,
    required this.arabic,
    required this.translation,
  });
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
