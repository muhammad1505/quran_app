import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrayerGuidePage extends StatelessWidget {
  const PrayerGuidePage({super.key});

  final List<Map<String, String>> guides = const [
    {
      "step": "1. Niat",
      "desc":
          "Berniat di dalam hati untuk melaksanakan sholat karena Allah Ta'ala.",
    },
    {
      "step": "2. Takbiratul Ihram",
      "desc":
          "Mengangkat kedua tangan sejajar telinga/bahu sambil mengucapkan 'Allahu Akbar'.",
    },
    {
      "step": "3. Membaca Iftitah (Sunnah)",
      "desc": "Membaca doa iftitah setelah takbiratul ihram.",
    },
    {
      "step": "4. Membaca Al-Fatihah",
      "desc": "Wajib membaca surat Al-Fatihah di setiap rakaat.",
    },
    {
      "step": "5. Ruku'",
      "desc":
          "Membungkukkan badan hingga punggung rata, tangan memegang lutut.",
    },
    {
      "step": "6. I'tidal",
      "desc": "Bangkit dari ruku' kembali ke posisi berdiri tegak.",
    },
    {
      "step": "7. Sujud",
      "desc":
          "Meletakkan dahi, hidung, kedua telapak tangan, lutut, dan ujung kaki di lantai.",
    },
    {
      "step": "8. Duduk Diantara Dua Sujud",
      "desc": "Duduk iftirasy setelah sujud pertama.",
    },
    {
      "step": "9. Tasyahud & Salam",
      "desc": "Membaca tasyahud akhir dan mengucap salam ke kanan dan kiri.",
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
