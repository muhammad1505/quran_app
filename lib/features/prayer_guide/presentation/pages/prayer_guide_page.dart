import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrayerGuidePage extends StatelessWidget {
  const PrayerGuidePage({super.key});

  final List<Map<String, String>> guides = const [
    {
      "step": "1. Persiapan & Syarat Sholat",
      "desc":
          "Pastikan suci dari hadas/najis, berwudhu, pakaian & tempat suci, menutup aurat, masuk waktu, dan menghadap kiblat.",
    },
    {
      "step": "2. Niat",
      "desc":
          "Niat di dalam hati sesuai jenis sholat (fardu/sunnah, jumlah rakaat, imam/makmum/munfarid).",
    },
    {
      "step": "3. Takbiratul Ihram",
      "desc":
          "Angkat tangan sejajar telinga/bahu sambil mengucapkan: Allahu Akbar.",
    },
    {
      "step": "4. Doa Iftitah (Sunnah)",
      "desc": "Membaca doa iftitah setelah takbiratul ihram.",
    },
    {
      "step": "5. Ta'awudz & Basmalah",
      "desc":
          "Membaca ta'awudz dan basmalah sebelum Al-Fatihah (terutama ketika sholat sendiri).",
    },
    {
      "step": "6. Membaca Al-Fatihah",
      "desc":
          "Wajib membaca Al-Fatihah di setiap rakaat dengan tartil dan khusyuk.",
    },
    {
      "step": "7. Membaca Surat/ Ayat",
      "desc":
          "Pada rakaat pertama dan kedua, baca surat/ayat tambahan setelah Al-Fatihah.",
    },
    {
      "step": "8. Ruku'",
      "desc":
          "Bungkukkan badan hingga punggung rata, tangan memegang lutut, baca: Subhana Rabbiyal 'Azim (min. 3x).",
    },
    {
      "step": "9. I'tidal",
      "desc":
          "Bangkit dari ruku' sambil membaca: Sami'allahu liman hamidah, Rabbana lakal hamd.",
    },
    {
      "step": "10. Sujud Pertama",
      "desc":
          "Letakkan dahi, hidung, kedua telapak tangan, lutut, dan ujung kaki di lantai, baca: Subhana Rabbiyal A'la (min. 3x).",
    },
    {
      "step": "11. Duduk di Antara Dua Sujud",
      "desc":
          "Duduk iftirasy, baca: Rabbighfirli warhamni wajburni warfa'ni warzuqni wahdini wa 'afini wa'fu 'anni.",
    },
    {
      "step": "12. Sujud Kedua",
      "desc":
          "Sujud kembali dengan bacaan yang sama seperti sujud pertama.",
    },
    {
      "step": "13. Rakaat Berikutnya",
      "desc":
          "Bangkit ke rakaat berikut, ulangi bacaan Al-Fatihah dan surat (rakaat 1-2), lalu ruku', i'tidal, sujud, duduk, sujud.",
    },
    {
      "step": "14. Tasyahud Awal (Rakaat 2)",
      "desc":
          "Pada sholat 3 atau 4 rakaat, setelah rakaat kedua duduk tasyahud awal: At-tahiyyatu lillahi... disertai shalawat.",
    },
    {
      "step": "15. Tasyahud Akhir & Doa",
      "desc":
          "Pada rakaat terakhir, duduk tasyahud akhir, membaca shalawat Nabi dan doa sebelum salam.",
    },
    {
      "step": "16. Salam",
      "desc":
          "Akhiri sholat dengan menoleh ke kanan dan kiri sambil mengucapkan: Assalamu'alaikum warahmatullah.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tuntunan Sholat")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: guides.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.1),
              child: Text(
                "${index + 1}",
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            title: Text(
              guides[index]['step']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              guides[index]['desc']!,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
