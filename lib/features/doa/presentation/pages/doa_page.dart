import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quran_app/core/services/asmaul_husna_service.dart';

class DoaPage extends StatefulWidget {
  const DoaPage({super.key});

  @override
  State<DoaPage> createState() => _DoaPageState();
}

class _DoaPageState extends State<DoaPage> {
  final List<_DoaItem> _doas = const [
    _DoaItem(
      title: 'Doa Pagi',
      arabic: 'اَللّٰهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا',
      translation: 'Ya Allah, dengan-Mu kami memasuki pagi dan dengan-Mu kami memasuki petang.',
      category: 'Pagi',
    ),
    _DoaItem(
      title: 'Doa Petang',
      arabic: 'اَللّٰهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا',
      translation: 'Ya Allah, dengan-Mu kami memasuki petang dan dengan-Mu kami memasuki pagi.',
      category: 'Malam',
    ),
    _DoaItem(
      title: 'Doa Masuk Masjid',
      arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
      translation: 'Ya Allah, bukakanlah untukku pintu-pintu rahmat-Mu.',
      category: 'Masjid',
    ),
    _DoaItem(
      title: 'Doa Keluar Masjid',
      arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
      translation: 'Ya Allah, sesungguhnya aku memohon keutamaan dari-Mu.',
      category: 'Masjid',
    ),
    _DoaItem(
      title: 'Doa Sebelum Makan',
      arabic: 'اللَّهُمَّ بَارِكْ لَنَا فِيمَا رَزَقْتَنَا',
      translation: 'Ya Allah, berkahilah rezeki yang Engkau berikan kepada kami.',
      category: 'Makan',
    ),
  ];

  final List<_DzikirItem> _dzikirItems = [
    _DzikirItem(
      title: 'Tasbih',
      arabic: 'سُبْحَانَ اللّٰهِ',
      translation: 'Maha Suci Allah',
      target: 33,
    ),
    _DzikirItem(
      title: 'Tahmid',
      arabic: 'الْحَمْدُ لِلّٰهِ',
      translation: 'Segala puji bagi Allah',
      target: 33,
    ),
    _DzikirItem(
      title: 'Takbir',
      arabic: 'اللّٰهُ أَكْبَرُ',
      translation: 'Allah Maha Besar',
      target: 34,
    ),
  ];

  String _selectedCategory = 'Semua';

  List<String> get _categories {
    final unique = _doas.map((e) => e.category).toSet().toList()..sort();
    return ['Semua', ...unique];
  }

  List<_DoaItem> get _filteredDoas {
    if (_selectedCategory == 'Semua') return _doas;
    return _doas.where((doa) => doa.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Doa & Dzikir'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Doa Harian'),
              Tab(text: 'Dzikir'),
              Tab(text: 'Asmaul'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDoaTab(context),
            _buildDzikirTab(context),
            _buildAsmaulTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDoaTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final selected = category == _selectedCategory;
              return ChoiceChip(
                label: Text(category),
                selected: selected,
                onSelected: (_) => setState(() => _selectedCategory = category),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ..._filteredDoas.map((doa) => _buildDoaCard(context, doa)),
      ],
    );
  }

  Widget _buildDoaCard(BuildContext context, _DoaItem doa) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    doa.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(doa.category)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              doa.arabic,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(fontSize: 26, height: 1.9),
            ),
            const SizedBox(height: 8),
            Text(
              doa.translation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Disimpan ke favorit.')),
                    );
                  },
                  icon: const Icon(Icons.bookmark_border, size: 18),
                  label: const Text('Simpan'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bagikan segera hadir.')),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Bagikan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDzikirTab(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dzikirItems.length,
      itemBuilder: (context, index) {
        final item = _dzikirItems[index];
        return _DzikirCard(item: item);
      },
    );
  }

  Widget _buildAsmaulTab(BuildContext context) {
    return FutureBuilder<List<AsmaulHusnaItem>>(
      future: AsmaulHusnaService.instance.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return Center(
            child: Text(
              'Data Asmaul Husna tidak ditemukan',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(item.transliteration),
                subtitle: Text(item.meaningId),
                trailing: Text(
                  item.arabic,
                  style: GoogleFonts.amiri(fontSize: 22),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DoaItem {
  final String title;
  final String arabic;
  final String translation;
  final String category;

  const _DoaItem({
    required this.title,
    required this.arabic,
    required this.translation,
    required this.category,
  });
}

class _DzikirItem {
  final String title;
  final String arabic;
  final String translation;
  final int target;

  _DzikirItem({
    required this.title,
    required this.arabic,
    required this.translation,
    required this.target,
  });
}

class _DzikirCard extends StatefulWidget {
  final _DzikirItem item;

  const _DzikirCard({required this.item});

  @override
  State<_DzikirCard> createState() => _DzikirCardState();
}

class _DzikirCardState extends State<_DzikirCard> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final progress = (_count / item.target).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              item.arabic,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(fontSize: 24, height: 1.8),
            ),
            const SizedBox(height: 6),
            Text(item.translation),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('$_count / ${item.target}'),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    if (_count > 0) {
                      setState(() => _count -= 1);
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _count += 1);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
                TextButton(
                  onPressed: () => setState(() => _count = 0),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
