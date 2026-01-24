import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrayerGuidePage extends StatelessWidget {
  const PrayerGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = _steps;
    return Scaffold(
      appBar: AppBar(title: const Text("Tuntunan Sholat")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.12),
                child: Text(
                  "${step.number}",
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
              title: Text(
                step.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                step.summary,
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              children: [
                if (step.illustration != PrayerIllustrationType.none)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PrayerIllustration(type: step.illustration),
                  ),
                _Section(
                  title: "Penjelasan",
                  body: step.detail,
                ),
                if (step.arabic.isNotEmpty)
                  _ArabicSection(
                    arabic: step.arabic,
                    latin: step.latin,
                    meaning: step.meaning,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PrayerStep {
  final int number;
  final String title;
  final String summary;
  final String detail;
  final String arabic;
  final String latin;
  final String meaning;
  final PrayerIllustrationType illustration;

  const PrayerStep({
    required this.number,
    required this.title,
    required this.summary,
    required this.detail,
    this.arabic = '',
    this.latin = '',
    this.meaning = '',
    this.illustration = PrayerIllustrationType.none,
  });
}

const List<PrayerStep> _steps = [
  PrayerStep(
    number: 1,
    title: "Persiapan & Syarat Sholat",
    summary:
        "Wajib suci, menutup aurat, masuk waktu, dan menghadap kiblat.",
    detail:
        "Pastikan wudhu, badan/pakaian/tempat suci dari najis, aurat tertutup, niat sholat sesuai waktunya, serta menghadap kiblat. Gunakan pakaian bersih dan rapi agar khusyuk.",
  ),
  PrayerStep(
    number: 2,
    title: "Niat",
    summary: "Niat di dalam hati sesuai jenis sholat.",
    detail:
        "Niat dilakukan di dalam hati ketika takbiratul ihram. Sesuaikan dengan jenis sholat (fardu/sunnah), jumlah rakaat, serta status (imam/makmum/munfarid).",
  ),
  PrayerStep(
    number: 3,
    title: "Takbiratul Ihram",
    summary: "Angkat tangan sejajar telinga/bahu dan bertakbir.",
    detail:
        "Berdiri tegak (bagi yang mampu), angkat tangan sejajar telinga atau bahu, lalu bertakbir. Setelah takbir, tangan disedekapkan di dada/perut.",
    arabic: "اللَّهُ أَكْبَرُ",
    latin: "Allahu Akbar.",
    meaning: "Allah Mahabesar.",
    illustration: PrayerIllustrationType.takbir,
  ),
  PrayerStep(
    number: 4,
    title: "Doa Iftitah (Sunnah)",
    summary: "Dibaca setelah takbiratul ihram.",
    detail:
        "Doa iftitah sunnah, bisa dipilih salah satu yang diajarkan. Bacaan berikut adalah yang paling umum.",
    arabic:
        "سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالَى جَدُّكَ وَلَا إِلَهَ غَيْرُكَ",
    latin:
        "Subhanakallahumma wa bihamdika wa tabarakasmuka wa ta'ala jadduka wa la ilaha ghairuka.",
    meaning:
        "Mahasuci Engkau ya Allah, dengan memuji-Mu; Maha berkah nama-Mu, Maha tinggi kemuliaan-Mu, dan tiada Tuhan selain Engkau.",
  ),
  PrayerStep(
    number: 5,
    title: "Ta'awudz & Basmalah",
    summary: "Dibaca sebelum Al-Fatihah.",
    detail:
        "Membaca ta'awudz untuk memohon perlindungan dari setan, lalu basmalah sebelum Al-Fatihah (terutama saat sholat sendiri).",
    arabic:
        "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ\nبِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
    latin:
        "A'udzu billahi minasy-syaitanir-rajim.\nBismillahir-rahmanir-rahim.",
    meaning:
        "Aku berlindung kepada Allah dari godaan setan yang terkutuk.\nDengan nama Allah Yang Maha Pengasih, Maha Penyayang.",
  ),
  PrayerStep(
    number: 6,
    title: "Membaca Al-Fatihah",
    summary: "Wajib di setiap rakaat.",
    detail:
        "Bacalah Al-Fatihah dengan tartil dan khusyuk. Berikut bacaan lengkapnya.",
    arabic:
        "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ\nالرَّحْمَٰنِ الرَّحِيمِ\nمَالِكِ يَوْمِ الدِّينِ\nإِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ\nاهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ\nصِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ",
    latin:
        "Bismillahir-rahmanir-rahim.\nAlhamdu lillahi rabbil 'alamin.\nAr-rahmanir-rahim.\nMaliki yaumid-din.\nIyyaka na'budu wa iyyaka nasta'in.\nIhdinas-siratal-mustaqim.\nSiratal-ladzina an'amta 'alaihim ghairil-maghdhubi 'alaihim wa lad-dallin.",
    meaning:
        "Dengan nama Allah Yang Maha Pengasih, Maha Penyayang.\nSegala puji bagi Allah, Tuhan seluruh alam.\nYang Maha Pengasih, Maha Penyayang.\nPemilik hari pembalasan.\nHanya kepada Engkaulah kami menyembah dan hanya kepada Engkaulah kami mohon pertolongan.\nTunjukilah kami jalan yang lurus.\n(Yaitu) jalan orang-orang yang telah Engkau beri nikmat; bukan (jalan) mereka yang dimurkai, dan bukan (pula jalan) mereka yang sesat.",
    illustration: PrayerIllustrationType.standing,
  ),
  PrayerStep(
    number: 7,
    title: "Membaca Surat/ Ayat",
    summary: "Tambahan setelah Al-Fatihah (rakaat 1-2).",
    detail:
        "Pada rakaat pertama dan kedua, baca surat/ayat lain setelah Al-Fatihah (misalnya Al-Ikhlas atau ayat pendek).",
  ),
  PrayerStep(
    number: 8,
    title: "Ruku'",
    summary: "Bungkuk hingga punggung rata.",
    detail:
        "Letakkan kedua telapak tangan di atas lutut, punggung rata, kepala sejajar punggung. Tahan dengan tuma'ninah.",
    arabic: "سُبْحَانَ رَبِّيَ الْعَظِيمِ",
    latin: "Subhana Rabbiyal 'Azim. (3x atau lebih)",
    meaning: "Mahasuci Tuhanku Yang Maha Agung.",
    illustration: PrayerIllustrationType.ruku,
  ),
  PrayerStep(
    number: 9,
    title: "I'tidal",
    summary: "Bangkit tegak dari ruku'.",
    detail:
        "Angkat badan dari ruku' hingga berdiri tegak (tuma'ninah).",
    arabic: "سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ\nرَبَّنَا وَلَكَ الْحَمْدُ",
    latin: "Sami'allahu liman hamidah. Rabbana wa lakal hamd.",
    meaning: "Allah mendengar orang yang memuji-Nya. Wahai Tuhan kami, bagi-Mu segala puji.",
    illustration: PrayerIllustrationType.standing,
  ),
  PrayerStep(
    number: 10,
    title: "Sujud Pertama",
    summary: "Letakkan 7 anggota sujud.",
    detail:
        "Letakkan dahi dan hidung, kedua telapak tangan, kedua lutut, serta ujung kedua kaki. Tuma'ninah.",
    arabic: "سُبْحَانَ رَبِّيَ الْأَعْلَى",
    latin: "Subhana Rabbiyal A'la. (3x atau lebih)",
    meaning: "Mahasuci Tuhanku Yang Maha Tinggi.",
    illustration: PrayerIllustrationType.sujud,
  ),
  PrayerStep(
    number: 11,
    title: "Duduk di Antara Dua Sujud",
    summary: "Duduk iftirasy dan berdoa.",
    detail:
        "Duduk di atas kaki kiri (iftirasy), kaki kanan ditegakkan. Tuma'ninah sebelum sujud berikutnya.",
    arabic:
        "رَبِّ اغْفِرْ لِي وَارْحَمْنِي وَاجْبُرْنِي وَارْفَعْنِي وَارْزُقْنِي وَاهْدِنِي وَعَافِنِي وَاعْفُ عَنِّي",
    latin:
        "Rabbighfirli warhamni wajburni warfa'ni warzuqni wahdini wa 'afini wa'fu 'anni.",
    meaning:
        "Ya Rabb, ampunilah aku, rahmatilah aku, cukupkan aku, angkat derajatku, berilah rezeki, beri petunjuk, sehatkan, dan maafkan aku.",
    illustration: PrayerIllustrationType.sitting,
  ),
  PrayerStep(
    number: 12,
    title: "Sujud Kedua",
    summary: "Sujud kembali seperti sujud pertama.",
    detail:
        "Lakukan sujud kedua dengan bacaan yang sama dan tuma'ninah.",
    arabic: "سُبْحَانَ رَبِّيَ الْأَعْلَى",
    latin: "Subhana Rabbiyal A'la. (3x atau lebih)",
    meaning: "Mahasuci Tuhanku Yang Maha Tinggi.",
    illustration: PrayerIllustrationType.sujud,
  ),
  PrayerStep(
    number: 13,
    title: "Rakaat Berikutnya",
    summary: "Ulangi bacaan sesuai rakaat.",
    detail:
        "Bangkit ke rakaat berikutnya, ulangi Al-Fatihah dan surat (pada rakaat 1-2), lalu ruku', i'tidal, sujud, duduk di antara dua sujud, sujud.",
  ),
  PrayerStep(
    number: 14,
    title: "Tasyahud Awal",
    summary: "Duduk setelah rakaat kedua.",
    detail:
        "Pada sholat 3 atau 4 rakaat, setelah rakaat kedua duduk tasyahud awal dengan tuma'ninah.",
    arabic:
        "التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ السَّلَامُ عَلَيْنَا وَعَلَىٰ عِبَادِ اللَّهِ الصَّالِحِينَ أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ",
    latin:
        "At-tahiyyatu lillahi was-salawatu wat-tayyibat. Assalamu 'alaika ayyuhan-nabiyyu wa rahmatullahi wa barakatuh. Assalamu 'alaina wa 'ala 'ibadillahis-salihin. Asyhadu an la ilaha illallah wa asyhadu anna Muhammadan 'abduhu wa rasuluh.",
    meaning:
        "Segala penghormatan, shalawat, dan kebaikan hanya bagi Allah... Aku bersaksi tiada Tuhan selain Allah dan Muhammad adalah hamba serta utusan-Nya.",
    illustration: PrayerIllustrationType.tasyahud,
  ),
  PrayerStep(
    number: 15,
    title: "Tasyahud Akhir & Shalawat",
    summary: "Duduk akhir pada rakaat terakhir.",
    detail:
        "Pada rakaat terakhir, duduk tasyahud akhir (tawarruk). Setelah tasyahud, lanjutkan shalawat dan doa sebelum salam.",
    arabic:
        "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ\nاللَّهُمَّ بَارِكْ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ\nاللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَذَابِ جَهَنَّمَ وَمِنْ عَذَابِ الْقَبْرِ وَمِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ وَمِنْ شَرِّ فِتْنَةِ الْمَسِيحِ الدَّجَّالِ",
    latin:
        "Allahumma salli 'ala Muhammad wa 'ala ali Muhammad kama sallaita 'ala Ibrahim wa 'ala ali Ibrahim innaka hamidum majid.\nAllahumma barik 'ala Muhammad wa 'ala ali Muhammad kama barakta 'ala Ibrahim wa 'ala ali Ibrahim innaka hamidum majid.\nAllahumma inni a'udzu bika min 'adzabi jahannam wa min 'adzabil-qabr wa min fitnatil-mahya wal-mamat wa min sharri fitnatil-masihid-dajjal.",
    meaning:
        "Ya Allah, limpahkan shalawat dan keberkahan kepada Muhammad dan keluarga Muhammad sebagaimana Engkau limpahkan kepada Ibrahim dan keluarga Ibrahim. Ya Allah, aku berlindung kepada-Mu dari azab neraka, azab kubur, fitnah hidup dan mati, serta fitnah Al-Masih Ad-Dajjal.",
    illustration: PrayerIllustrationType.tasyahud,
  ),
  PrayerStep(
    number: 16,
    title: "Salam",
    summary: "Menoleh ke kanan dan kiri.",
    detail:
        "Akhiri sholat dengan menoleh ke kanan dan kiri sambil mengucapkan salam.",
    arabic: "السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ",
    latin: "Assalamu'alaikum warahmatullah.",
    meaning: "Semoga keselamatan dan rahmat Allah tercurah kepada kalian.",
    illustration: PrayerIllustrationType.salam,
  ),
];

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.poppins(fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ArabicSection extends StatelessWidget {
  final String arabic;
  final String latin;
  final String meaning;

  const _ArabicSection({
    required this.arabic,
    required this.latin,
    required this.meaning,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bacaan",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          arabic,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.amiri(fontSize: 18, height: 1.8),
        ),
        if (latin.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            latin,
            style: GoogleFonts.poppins(fontSize: 12, height: 1.5),
          ),
        ],
        if (meaning.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            "Arti: $meaning",
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
        ],
      ],
    );
  }
}

enum PrayerIllustrationType {
  none,
  standing,
  takbir,
  ruku,
  sujud,
  sitting,
  tasyahud,
  salam,
}

class PrayerIllustration extends StatelessWidget {
  final PrayerIllustrationType type;

  const PrayerIllustration({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    if (type == PrayerIllustrationType.none) {
      return const SizedBox.shrink();
    }
    final assetPath = _assetPath(type);
    if (assetPath != null) {
      final fallback = CustomPaint(
        size: const Size(160, 120),
        painter: _PrayerIllustrationPainter(
          type: type,
          color: Theme.of(context).primaryColor,
        ),
      );
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            assetPath,
            height: 220,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => fallback,
          ),
        ),
      );
    }
    final color = Theme.of(context).primaryColor;
    return Center(
      child: CustomPaint(
        size: const Size(160, 120),
        painter: _PrayerIllustrationPainter(type: type, color: color),
      ),
    );
  }

  String? _assetPath(PrayerIllustrationType type) {
    switch (type) {
      case PrayerIllustrationType.takbir:
        return 'assets/illustrations/panduan_sholat_nolabel_01.png';
      case PrayerIllustrationType.standing:
        return 'assets/illustrations/panduan_sholat_nolabel_02.png';
      case PrayerIllustrationType.ruku:
        return 'assets/illustrations/panduan_sholat_nolabel_05.png';
      case PrayerIllustrationType.sujud:
        return 'assets/illustrations/panduan_sholat_nolabel_06.png';
      case PrayerIllustrationType.sitting:
        return 'assets/illustrations/panduan_sholat_nolabel_07.png';
      case PrayerIllustrationType.salam:
        return 'assets/illustrations/panduan_sholat_nolabel_08.png';
      case PrayerIllustrationType.tasyahud:
        return 'assets/illustrations/panduan_sholat_nolabel_09.png';
      case PrayerIllustrationType.none:
        return null;
    }
  }
}

class _PrayerIllustrationPainter extends CustomPainter {
  final PrayerIllustrationType type;
  final Color color;

  const _PrayerIllustrationPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (type) {
      case PrayerIllustrationType.standing:
        _drawStanding(canvas, size, paint);
        break;
      case PrayerIllustrationType.takbir:
        _drawTakbir(canvas, size, paint);
        break;
      case PrayerIllustrationType.ruku:
        _drawRuku(canvas, size, paint);
        break;
      case PrayerIllustrationType.sujud:
        _drawSujud(canvas, size, paint);
        break;
      case PrayerIllustrationType.sitting:
        _drawSitting(canvas, size, paint);
        break;
      case PrayerIllustrationType.tasyahud:
      case PrayerIllustrationType.salam:
        _drawSitting(canvas, size, paint);
        break;
      case PrayerIllustrationType.none:
        break;
    }
  }

  void _drawStanding(Canvas canvas, Size size, Paint paint) {
    final headCenter = Offset(size.width * 0.5, size.height * 0.2);
    canvas.drawCircle(headCenter, 12, paint);
    final bodyTop = Offset(size.width * 0.5, size.height * 0.32);
    final bodyBottom = Offset(size.width * 0.5, size.height * 0.75);
    canvas.drawLine(bodyTop, bodyBottom, paint);
    final armLeft = Offset(size.width * 0.4, size.height * 0.45);
    final armRight = Offset(size.width * 0.6, size.height * 0.45);
    canvas.drawLine(armLeft, armRight, paint);
    canvas.drawLine(
        bodyBottom, Offset(size.width * 0.4, size.height * 0.95), paint);
    canvas.drawLine(
        bodyBottom, Offset(size.width * 0.6, size.height * 0.95), paint);
  }

  void _drawTakbir(Canvas canvas, Size size, Paint paint) {
    final headCenter = Offset(size.width * 0.5, size.height * 0.2);
    canvas.drawCircle(headCenter, 12, paint);
    final bodyTop = Offset(size.width * 0.5, size.height * 0.32);
    final bodyBottom = Offset(size.width * 0.5, size.height * 0.75);
    canvas.drawLine(bodyTop, bodyBottom, paint);
    final armLeft = Offset(size.width * 0.4, size.height * 0.28);
    final armRight = Offset(size.width * 0.6, size.height * 0.28);
    canvas.drawLine(bodyTop, armLeft, paint);
    canvas.drawLine(bodyTop, armRight, paint);
    canvas.drawLine(
        bodyBottom, Offset(size.width * 0.4, size.height * 0.95), paint);
    canvas.drawLine(
        bodyBottom, Offset(size.width * 0.6, size.height * 0.95), paint);
  }

  void _drawRuku(Canvas canvas, Size size, Paint paint) {
    final headCenter = Offset(size.width * 0.35, size.height * 0.35);
    canvas.drawCircle(headCenter, 10, paint);
    final backStart = Offset(size.width * 0.45, size.height * 0.35);
    final backEnd = Offset(size.width * 0.75, size.height * 0.35);
    canvas.drawLine(backStart, backEnd, paint);
    final legsTop = Offset(size.width * 0.6, size.height * 0.35);
    canvas.drawLine(
        legsTop, Offset(size.width * 0.55, size.height * 0.92), paint);
    canvas.drawLine(
        legsTop, Offset(size.width * 0.65, size.height * 0.92), paint);
    canvas.drawLine(
        backEnd, Offset(size.width * 0.85, size.height * 0.45), paint);
  }

  void _drawSujud(Canvas canvas, Size size, Paint paint) {
    final headCenter = Offset(size.width * 0.65, size.height * 0.75);
    canvas.drawCircle(headCenter, 10, paint);
    final bodyStart = Offset(size.width * 0.35, size.height * 0.6);
    final bodyEnd = Offset(size.width * 0.65, size.height * 0.7);
    canvas.drawLine(bodyStart, bodyEnd, paint);
    canvas.drawLine(
        bodyStart, Offset(size.width * 0.25, size.height * 0.85), paint);
    canvas.drawLine(
        bodyStart, Offset(size.width * 0.4, size.height * 0.95), paint);
    canvas.drawLine(
        bodyEnd, Offset(size.width * 0.8, size.height * 0.95), paint);
  }

  void _drawSitting(Canvas canvas, Size size, Paint paint) {
    final headCenter = Offset(size.width * 0.5, size.height * 0.25);
    canvas.drawCircle(headCenter, 12, paint);
    final bodyTop = Offset(size.width * 0.5, size.height * 0.37);
    final bodyBottom = Offset(size.width * 0.5, size.height * 0.65);
    canvas.drawLine(bodyTop, bodyBottom, paint);
    canvas.drawLine(
        bodyBottom, Offset(size.width * 0.35, size.height * 0.85), paint);
    canvas.drawLine(
        bodyBottom, Offset(size.width * 0.65, size.height * 0.75), paint);
    canvas.drawLine(
        Offset(size.width * 0.35, size.height * 0.85),
        Offset(size.width * 0.25, size.height * 0.9),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
