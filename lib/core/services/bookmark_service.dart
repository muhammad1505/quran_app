import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BookmarkItem {
  final int surah;
  final int ayah;
  final String? note;
  final DateTime createdAt;

  const BookmarkItem({
    required this.surah,
    required this.ayah,
    this.note,
    required this.createdAt,
  });

  String get key => '$surah:$ayah';

  BookmarkItem copyWith({String? note}) {
    return BookmarkItem(
      surah: surah,
      ayah: ayah,
      note: note,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surah': surah,
      'ayah': ayah,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static BookmarkItem fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class BookmarkService {
  BookmarkService._();

  static final BookmarkService instance = BookmarkService._();
  static const _storageKey = 'bookmarks';

  Future<List<BookmarkItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => BookmarkItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> getKeys() async {
    final list = await getAll();
    return list.map((e) => e.key).toSet();
  }

  Future<void> toggleBookmark({
    required int surah,
    required int ayah,
  }) async {
    final list = await getAll();
    final key = '$surah:$ayah';
    final index = list.indexWhere((item) => item.key == key);
    if (index >= 0) {
      list.removeAt(index);
    } else {
      list.insert(
        0,
        BookmarkItem(surah: surah, ayah: ayah, createdAt: DateTime.now()),
      );
    }
    await _save(list);
  }

  Future<void> saveNote({
    required int surah,
    required int ayah,
    required String note,
  }) async {
    final list = await getAll();
    final key = '$surah:$ayah';
    final index = list.indexWhere((item) => item.key == key);
    if (index >= 0) {
      list[index] = list[index].copyWith(note: note);
    } else {
      list.insert(
        0,
        BookmarkItem(
          surah: surah,
          ayah: ayah,
          note: note,
          createdAt: DateTime.now(),
        ),
      );
    }
    await _save(list);
  }

  Future<void> _save(List<BookmarkItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(list.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
