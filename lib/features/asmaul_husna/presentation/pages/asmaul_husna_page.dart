import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quran_app/core/services/asmaul_husna_service.dart';

class AsmaulHusnaPage extends StatelessWidget {
  const AsmaulHusnaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Asmaul Husna")),
      body: FutureBuilder<List<AsmaulHusnaItem>>(
        future: AsmaulHusnaService.instance.load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                "Data Asmaul Husna tidak ditemukan",
                style: GoogleFonts.poppins(),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.number.toString(),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.arabic,
                            textAlign: TextAlign.left,
                            style: GoogleFonts.amiri(
                              fontSize: 24,
                              height: 1.6,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.transliteration,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (item.meaningEn.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.meaningEn,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
