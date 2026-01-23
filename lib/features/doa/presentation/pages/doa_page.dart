import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoaPage extends StatelessWidget {
  const DoaPage({super.key});

  final List<Map<String, String>> doas = const [
    {
      "title": "Doa Sebelum Tidur",
      "arabic": "بِسْمِكَ اللّهُمَّ اَحْيَا وَ بِسْمِكَ اَمُوْتُ",
      "translation":
          "Dengan nama-Mu ya Allah aku hidup dan dengan nama-Mu aku mati.",
    },
    {
      "title": "Doa Bangun Tidur",
      "arabic":
          "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ",
      "translation":
          "Segala puji bagi Allah, yang telah membangunkan kami setelah menidurkan kami dan kepada-Nya lah kami dibangkitkan.",
    },
    {
      "title": "Doa Masuk Masjid",
      "arabic": "اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ",
      "translation": "Ya Allah, bukalah untukku pintu-pintu rahmat-Mu.",
    },
    {
      "title": "Doa Keluar Masjid",
      "arabic": "اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ",
      "translation": "Ya Allah, sesungguhnya aku memohon keutamaan dari-Mu.",
    },
    {
      "title": "Doa Sebelum Makan",
      "arabic":
          "اللَّهُمَّ بَارِكْ لَنَا فِيمَا رَزَقْتَنَا وَقِنَا عَذَابَ النَّارِ",
      "translation":
          "Ya Allah, berkahilah kami dalam rezeki yang telah Engkau berikan kepada kami dan peliharalah kami dari siksa api neraka.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kumpulan Doa")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: doas.length,
        itemBuilder: (context, index) {
          final doa = doas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                doa['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: Icon(Icons.stars, color: Theme.of(context).primaryColor),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        doa['arabic']!,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(fontSize: 24, height: 2.0),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        doa['translation']!,
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
