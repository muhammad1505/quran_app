import 'dart:convert';

import 'package:flutter/services.dart';

class AsmaulHusnaItem {
  final int number;
  final String arabic;
  final String transliteration;
  final String meaningEn;

  const AsmaulHusnaItem({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.meaningEn,
  });
}

class AsmaulHusnaService {
  AsmaulHusnaService._();

  static final AsmaulHusnaService instance = AsmaulHusnaService._();

  Future<List<AsmaulHusnaItem>>? _loadFuture;

  Future<List<AsmaulHusnaItem>> load() {
    _loadFuture ??= _loadFromAssets();
    return _loadFuture!;
  }

  Future<List<AsmaulHusnaItem>> _loadFromAssets() async {
    final jsonString = await rootBundle.loadString('assets/asmaul_husna.json');
    final data = jsonDecode(jsonString) as List<dynamic>;
    return data
        .map((item) => AsmaulHusnaItem(
              number: item['number'] as int? ?? 0,
              arabic: item['arabic'] as String? ?? '',
              transliteration: item['transliteration'] as String? ?? '',
              meaningEn: item['meaning_en'] as String? ?? '',
            ))
        .toList();
  }
}
