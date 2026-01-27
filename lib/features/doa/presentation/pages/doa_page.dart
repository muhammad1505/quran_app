import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'package:quran_app/core/services/asmaul_husna_service.dart';
import 'package:quran_app/core/services/doa_favorite_service.dart';
import 'package:quran_app/core/services/tts_service.dart';
import 'package:quran_app/features/asmaul_husna/presentation/pages/asmaul_detail_page.dart';

class DoaPage extends StatefulWidget {
  const DoaPage({super.key});

  @override
  State<DoaPage> createState() => _DoaPageState();
}

class _DoaPageState extends State<DoaPage> {
  final List<DoaItem> _doas = const [
    DoaItem(
      id: 'sapu_jagat',
      title: 'Doa Sapu Jagat',
      arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      latin: 'Rabbana atina fid-dunya hasanah wa fil-akhirati hasanah wa qina \'adzaban-nar.',
      translation: 'Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di akhirat dan peliharalah kami dari siksa neraka.',
      category: 'Harian',
      source: 'QS. Al-Baqarah: 201',
    ),
    DoaItem(
      id: 'orang_tua',
      title: 'Doa untuk Orang Tua',
      arabic: 'رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
      latin: 'Rabbighfir li wa liwalidayya warhamhuma kama rabbayani shaghira.',
      translation: 'Ya Tuhanku, ampunilah dosaku dan dosa kedua orang tuaku, dan sayangilah keduanya sebagaimana mereka menyayangiku di waktu kecil.',
      category: 'Keluarga',
      source: 'QS. Al-Isra: 24',
    ),
    DoaItem(
      id: 'selamat',
      title: 'Doa Selamat',
      arabic: 'اللَّهُمَّ إِنَّا نَسْأَلُكَ سَلَامَةً فِي الدِّينِ وَعَافِيَةً فِي الْجَسَدِ وَزِيَادَةً فِي الْعِلْمِ وَبَرَكَةً فِي الرِّزْقِ',
      latin: 'Allahumma inna nas\'aluka salamatan fid-din wa \'afiyatan fil-jasad wa ziyadatan fil-\'ilmi wa barakatan fir-rizqi.',
      translation: 'Ya Allah, kami memohon kepada-Mu keselamatan dalam agama, kesehatan jasmani, bertambahnya ilmu, dan keberkahan dalam rezeki.',
      category: 'Harian',
    ),
    DoaItem(
      id: 'niat_wudhu',
      title: 'Niat Wudhu',
      arabic: 'نَوَيْتُ الْوُضُوْءَ لِرَفْعِ الْحَدَثِ الْأَصْغَرِ فَرْضًا لِلَّهِ تَعَالَى',
      latin: 'Nawaitul wudhu\'a liraf\'il hadatsil asghari fardhan lillahi ta\'ala.',
      translation: 'Aku niat berwudhu untuk menghilangkan hadas kecil, fardhu karena Allah Ta\'ala.',
      category: 'Sholat',
    ),
    DoaItem(
      id: 'setelah_wudhu',
      title: 'Doa Setelah Wudhu',
      arabic: 'أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
      latin: 'Asyhadu alla ilaha illallah wahdahu la syarika lah wa asyhadu anna Muhammadan \'abduhu wa rasuluh.',
      translation: 'Aku bersaksi bahwa tidak ada Tuhan selain Allah Yang Maha Esa, tidak ada sekutu bagi-Nya, dan aku bersaksi bahwa Muhammad adalah hamba dan utusan-Nya.',
      category: 'Sholat',
      source: 'HR. Muslim',
    ),
    DoaItem(
      id: 'pagi',
      title: 'Doa Pagi',
      arabic: 'اَللّٰهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا',
      latin: 'Allahumma bika asbahna wa bika amsayna.',
      translation:
          'Ya Allah, dengan-Mu kami memasuki pagi dan dengan-Mu kami memasuki petang.',
      category: 'Pagi',
      source: 'HR. Abu Dawud',
    ),
    DoaItem(
      id: 'petang',
      title: 'Doa Petang',
      arabic: 'اَللّٰهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا',
      latin: 'Allahumma bika amsayna wa bika asbahna.',
      translation:
          'Ya Allah, dengan-Mu kami memasuki petang dan dengan-Mu kami memasuki pagi.',
      category: 'Malam',
      source: 'HR. Abu Dawud',
    ),
    DoaItem(
      id: 'masuk_masjid',
      title: 'Doa Masuk Masjid',
      arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
      latin: 'Allahummaftah li abwaba rahmatik.',
      translation: 'Ya Allah, bukakanlah untukku pintu-pintu rahmat-Mu.',
      category: 'Masjid',
      source: 'HR. Muslim',
    ),
    DoaItem(
      id: 'keluar_masjid',
      title: 'Doa Keluar Masjid',
      arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
      latin: 'Allahumma inni as\'aluka min fadhlik.',
      translation: 'Ya Allah, sesungguhnya aku memohon keutamaan dari-Mu.',
      category: 'Masjid',
      source: 'HR. Muslim',
    ),
    DoaItem(
      id: 'sebelum_makan',
      title: 'Doa Sebelum Makan',
      arabic: 'بِسْمِ اللَّهِ',
      latin: 'Bismillah.',
      translation: 'Dengan nama Allah.',
      category: 'Makan',
    ),
    DoaItem(
      id: 'sesudah_makan',
      title: 'Doa Sesudah Makan',
      arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا وَرَزَقَنِيهِ',
      latin: 'Alhamdu lillahil-ladzi ath\'amani hadza wa razaqanih.',
      translation:
          'Segala puji bagi Allah yang telah memberi makan ini dan memberinya rezeki kepadaku.',
      category: 'Makan',
    ),
    DoaItem(
      id: 'sebelum_tidur',
      title: 'Doa Sebelum Tidur',
      arabic: 'بِاسْمِكَ اللَّهُمَّ أَحْيَا وَأَمُوتُ',
      latin: 'Bismikallahumma ahya wa amut.',
      translation: 'Dengan nama-Mu ya Allah aku hidup dan aku mati.',
      category: 'Malam',
    ),
    DoaItem(
      id: 'bangun_tidur',
      title: 'Doa Bangun Tidur',
      arabic:
          'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      latin:
          'Alhamdu lillahil-ladzi ahyana ba\'da ma amatana wa ilaihin nusyur.',
      translation:
          'Segala puji bagi Allah yang menghidupkan kami setelah mematikan kami, dan kepada-Nya kebangkitan.',
      category: 'Pagi',
    ),
    DoaItem(
      id: 'masuk_rumah',
      title: 'Doa Masuk Rumah',
      arabic:
          'بِسْمِ اللَّهِ وَلَجْنَا وَبِسْمِ اللَّهِ خَرَجْنَا وَعَلَى رَبِّنَا تَوَكَّلْنَا',
      latin:
          'Bismillahi walajna wa bismillahi kharajna wa \'ala rabbina tawakkalna.',
      translation:
          'Dengan nama Allah kami masuk, dengan nama Allah kami keluar, dan kepada Tuhan kami bertawakal.',
      category: 'Rumah',
    ),
    DoaItem(
      id: 'keluar_rumah',
      title: 'Doa Keluar Rumah',
      arabic:
          'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      latin:
          'Bismillahi tawakkaltu \'alallah, la hawla wa la quwwata illa billah.',
      translation:
          'Dengan nama Allah aku bertawakal kepada Allah, tiada daya dan kekuatan kecuali dengan Allah.',
      category: 'Rumah',
    ),
    DoaItem(
      id: 'naik_kendaraan',
      title: 'Doa Naik Kendaraan',
      arabic:
          'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ',
      latin:
          'Subhanalladzi sakhkhara lana hadza wa ma kunna lahu muqrinin wa inna ila rabbina lamunqalibun.',
      translation:
          'Maha suci Allah yang telah menundukkan ini bagi kami, padahal kami sebelumnya tidak mampu menguasainya, dan kepada Tuhan kami akan kembali.',
      category: 'Perjalanan',
    ),
    DoaItem(
      id: 'masuk_kamar_mandi',
      title: 'Doa Masuk Kamar Mandi',
      arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ',
      latin: 'Allahumma inni a\'udzu bika minal khubutsi wal khaba\'its.',
      translation: 'Ya Allah, aku berlindung kepada-Mu dari setan laki-laki dan perempuan.',
      category: 'Kebersihan',
    ),
    DoaItem(
      id: 'keluar_kamar_mandi',
      title: 'Doa Keluar Kamar Mandi',
      arabic: 'غُفْرَانَكَ',
      latin: 'Ghufranaka.',
      translation: 'Aku memohon ampunan-Mu.',
      category: 'Kebersihan',
    ),
    DoaItem(
      id: 'ilmu',
      title: 'Doa Memohon Ilmu',
      arabic: 'رَبِّ زِدْنِي عِلْمًا',
      latin: 'Rabbi zidni \'ilma.',
      translation: 'Ya Rabb, tambahkanlah aku ilmu.',
      category: 'Belajar',
    ),
    DoaItem(
      id: 'sakit',
      title: 'Doa Kesembuhan',
      arabic: 'اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَأْسَ اشْفِ أَنْتَ الشَّافِي',
      latin: 'Allahumma rabban-nas adzhibil ba\'sa isyfi antas syafi.',
      translation:
          'Ya Allah, Tuhan manusia, hilangkanlah penyakit dan sembuhkanlah; Engkau adalah Maha Penyembuh.',
      category: 'Sakit',
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

  late final List<_DzikirProgress> _dzikirProgress;

  String _selectedCategory = 'Semua';
  Set<String> _favoriteIds = {};
  bool _isAsmaulPlayingAll = false;
  bool _stopAsmaulRequested = false;

  @override
  void initState() {
    super.initState();
    _dzikirProgress =
        List.generate(_dzikirItems.length, (_) => const _DzikirProgress());
    _loadFavorites();
  }

  @override
  void dispose() {
    _stopAsmaulRequested = true;
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favorites = await DoaFavoriteService.instance.getFavorites();
    if (!mounted) return;
    setState(() => _favoriteIds = favorites);
  }

  bool _isFavorite(DoaItem doa) => _favoriteIds.contains(doa.id);

  Future<void> _toggleFavorite(DoaItem doa) async {
    final messenger = ScaffoldMessenger.of(context);
    final updated = await DoaFavoriteService.instance.toggle(doa.id);
    if (!mounted) return;
    setState(() => _favoriteIds = updated);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          updated.contains(doa.id)
              ? 'Disimpan ke favorit.'
              : 'Dihapus dari favorit.',
        ),
      ),
    );
  }

  List<String> get _categories {
    final unique = _doas.map((e) => e.category).toSet().toList()..sort();
    return ['Semua', ...unique];
  }

  List<DoaItem> get _filteredDoas {
    if (_selectedCategory == 'Semua') return _doas;
    return _doas.where((doa) => doa.category == _selectedCategory).toList();
  }

  int get _completedDzikir =>
      _dzikirProgress.where((item) => item.completed).length;

  Future<void> _toggleAsmaulPlayAll(List<AsmaulHusnaItem> items) async {
    if (_isAsmaulPlayingAll) {
      _stopAsmaulRequested = true;
      await TtsService.instance.stop();
      if (mounted) {
        setState(() => _isAsmaulPlayingAll = false);
      }
      return;
    }
    setState(() {
      _isAsmaulPlayingAll = true;
      _stopAsmaulRequested = false;
    });
    for (final item in items) {
      if (_stopAsmaulRequested) break;
      final text = item.meaningId.isNotEmpty
          ? '${item.transliteration}. ${item.meaningId}'
          : item.transliteration;
      await TtsService.instance.speak(text, language: 'id-ID');
    }
    if (mounted) {
      setState(() => _isAsmaulPlayingAll = false);
    }
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

  Widget _buildDoaCard(BuildContext context, DoaItem doa) {
    final isFavorite = _isFavorite(doa);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DoaDetailPage(doa: doa)),
          );
        },
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
                    onPressed: () => _toggleFavorite(doa),
                    icon: Icon(
                      isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      size: 18,
                    ),
                    label: Text(isFavorite ? 'Favorit' : 'Simpan'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      Share.share(_doaShareText(doa));
                    },
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Bagikan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDzikirTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text('$_completedDzikir/${_dzikirItems.length} selesai'),
          ],
        ),
        const SizedBox(height: 12),
        ..._dzikirItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final progress = _dzikirProgress[index];
          return _DzikirCard(
            item: item,
            progress: progress,
            onChanged: (updated) {
              setState(() => _dzikirProgress[index] = updated);
            },
          );
        }),
      ],
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
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text(
                  'Asmaul Husna',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _toggleAsmaulPlayAll(items),
                  icon: Icon(
                    _isAsmaulPlayingAll
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    _isAsmaulPlayingAll ? 'Hentikan' : 'Putar semua',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AsmaulDetailPage(item: item),
                      ),
                    );
                  },
                  title: Text(item.transliteration),
                  subtitle: Text(item.meaningId),
                  trailing: Text(
                    item.arabic,
                    style: GoogleFonts.amiri(fontSize: 22),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class DoaItem {
  final String id;
  final String title;
  final String arabic;
  final String latin;
  final String translation;
  final String category;
  final String source;

  const DoaItem({
    required this.id,
    required this.title,
    required this.arabic,
    this.latin = '',
    required this.translation,
    required this.category,
    this.source = '',
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

class DoaDetailPage extends StatelessWidget {
  final DoaItem doa;

  const DoaDetailPage({super.key, required this.doa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doa.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            doa.arabic,
            textAlign: TextAlign.right,
            style: GoogleFonts.amiri(fontSize: 32, height: 1.8),
          ),
          if (doa.latin.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              doa.latin,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            doa.translation,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (doa.source.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Sumber: ${doa.source}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final text = doa.latin.isNotEmpty
                        ? doa.latin
                        : doa.translation;
                    await TtsService.instance.speak(
                      text,
                      language: 'id-ID',
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Audio'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Share.share(_doaShareText(doa));
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Bagikan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DzikirCard extends StatelessWidget {
  final _DzikirItem item;
  final _DzikirProgress progress;
  final ValueChanged<_DzikirProgress> onChanged;

  const _DzikirCard({
    required this.item,
    required this.progress,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final current = progress.count;
    final percent = (current / item.target).clamp(0.0, 1.0);
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
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Checkbox(
                  value: progress.completed,
                  onChanged: (value) {
                    onChanged(progress.copyWith(completed: value ?? false));
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.arabic,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(fontSize: 24, height: 1.8),
            ),
            const SizedBox(height: 6),
            Text(item.translation),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: percent),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('$current / ${item.target}'),
                const Spacer(),
                IconButton(
                  onPressed: current > 0
                      ? () {
                          final next = current - 1;
                          onChanged(
                            progress.copyWith(
                              count: next,
                              completed: next >= item.target,
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  onPressed: () {
                    final next = current + 1;
                    onChanged(
                      progress.copyWith(
                        count: next,
                        completed: next >= item.target,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
                TextButton(
                  onPressed: () {
                    onChanged(progress.copyWith(count: 0, completed: false));
                  },
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

class _DzikirProgress {
  final int count;
  final bool completed;

  const _DzikirProgress({this.count = 0, this.completed = false});

  _DzikirProgress copyWith({int? count, bool? completed}) {
    return _DzikirProgress(
      count: count ?? this.count,
      completed: completed ?? this.completed,
    );
  }
}

String _doaShareText(DoaItem doa) {
  final buffer = StringBuffer()
    ..writeln(doa.title)
    ..writeln()
    ..writeln(doa.arabic);
  if (doa.latin.isNotEmpty) {
    buffer.writeln(doa.latin);
  }
  buffer
    ..writeln()
    ..writeln(doa.translation);
  if (doa.source.isNotEmpty) {
    buffer.writeln('Sumber: ${doa.source}');
  }
  return buffer.toString().trim();
}
