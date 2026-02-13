import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran/quran.dart' as quran;

import 'package:quran_app/core/services/last_read_service.dart';
import 'package:quran_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:quran_app/features/quran/presentation/pages/quran_page.dart';
import 'package:quran_app/features/prayer_times/presentation/pages/prayer_times_page.dart';
import 'package:quran_app/features/prayer_times/presentation/widgets/prayer_times_summary_card.dart';
import 'package:quran_app/features/qibla/presentation/pages/qibla_page.dart';
import 'package:quran_app/features/doa/presentation/pages/doa_page.dart';
import 'package:quran_app/features/prayer_guide/presentation/pages/prayer_guide_page.dart';
import 'package:quran_app/features/settings/presentation/pages/settings_page.dart';
import 'package:quran_app/features/asmaul_husna/presentation/pages/asmaul_husna_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
                  Text("Aksi Cepat",
                      style: Theme.of(context).textTheme.titleMedium),
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
                      _buildMenuIcon(
                          context, Icons.access_time_filled, "Jadwal", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const Scaffold(body: PrayerTimesPage()),
                          ),
                        );
                      }),
                      _buildMenuIcon(context, Icons.explore, "Kiblat", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QiblaPage()),
                        );
                      }),
                      _buildMenuIcon(
                          context, Icons.volunteer_activism, "Doa", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DoaPage()),
                        );
                      }),
                      _buildMenuIcon(context, Icons.mosque, "Sholat", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrayerGuidePage()),
                        );
                      }),
                      _buildMenuIcon(context, Icons.auto_awesome, "Asmaul", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AsmaulHusnaPage()),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("Hari Ini",
                      style: Theme.of(context).textTheme.titleMedium),
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
    final surahName = hasLastRead ? quran.getSurahName(lastRead.surah) : '';
    final totalVerses = hasLastRead ? quran.getVerseCount(lastRead.surah) : 0;
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
                final cubit = context.read<HomeCubit>();
                final page = !hasLastRead
                    ? const QuranPage()
                    : SurahDetailPage(
                        surahNumber: lastRead.surah,
                        initialVerse: lastRead.ayah,
                      );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => page),
                ).then((_) {
                  if (mounted) {
                    cubit.refreshLastRead();
                  }
                });
              },
              child: const Text("Lanjut"),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDailyVerseBookmark(DailyVerse verse, bool isBookmarked) {
    context.read<HomeCubit>().toggleDailyVerseBookmark(verse).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBookmarked ? 'Bookmark dihapus.' : 'Bookmark disimpan.',
          ),
        ),
      );
    });
  }

  Widget _buildDailyHighlightCard(BuildContext context, HomeLoaded state) {
    final verse = state.dailyVerse;
    final isLoading = state.isDailyVerseLoading;
    final isBookmarked =
        verse != null && state.bookmarkKeys.contains('${verse.surah}:${verse.ayah}');

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
                  onPressed:
                      verse == null ? null : () => _toggleDailyVerseBookmark(verse, isBookmarked),
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
              color: Theme.of(context).colorScheme.primary.withAlpha(26),
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
