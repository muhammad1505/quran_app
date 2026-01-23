import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BookmarkItem {
  final int surah;
  final int ayah;
  final String? note;
  final String? folderId;
  final DateTime createdAt;

  const BookmarkItem({
    required this.surah,
    required this.ayah,
    this.note,
    this.folderId,
    required this.createdAt,
  });

  String get key => '$surah:$ayah';

  BookmarkItem copyWith({String? note, String? folderId}) {
    return BookmarkItem(
      surah: surah,
      ayah: ayah,
      note: note,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surah': surah,
      'ayah': ayah,
      'note': note,
      'folder_id': folderId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static BookmarkItem fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      note: json['note'] as String?,
      folderId: json['folder_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class BookmarkFolder {
  final String id;
  final String name;
  final DateTime createdAt;

  const BookmarkFolder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static BookmarkFolder fromJson(Map<String, dynamic> json) {
    return BookmarkFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class BookmarkService {
  BookmarkService._();

  static final BookmarkService instance = BookmarkService._();
  static const _storageKey = 'bookmarks';
  static const _folderKey = 'bookmark_folders';

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
    String? folderId,
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
    if (index == -1 && folderId != null) {
      list[0] = list[0].copyWith(folderId: folderId);
    }
    await _save(list);
  }

  Future<void> saveNote({
    required int surah,
    required int ayah,
    required String note,
    String? folderId,
  }) async {
    final list = await getAll();
    final key = '$surah:$ayah';
    final index = list.indexWhere((item) => item.key == key);
    if (index >= 0) {
      list[index] = list[index].copyWith(note: note, folderId: folderId);
    } else {
      list.insert(
        0,
        BookmarkItem(
          surah: surah,
          ayah: ayah,
          note: note,
          folderId: folderId,
          createdAt: DateTime.now(),
        ),
      );
    }
    await _save(list);
  }

  Future<void> assignFolder({
    required int surah,
    required int ayah,
    required String? folderId,
  }) async {
    final list = await getAll();
    final index = list.indexWhere((item) => item.key == '$surah:$ayah');
    if (index >= 0) {
      list[index] = list[index].copyWith(folderId: folderId);
      await _save(list);
    }
  }

  Future<List<BookmarkFolder>> getFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_folderKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => BookmarkFolder.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BookmarkFolder> addFolder(String name) async {
    final folders = await getFolders();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final folder = BookmarkFolder(
      id: id,
      name: name,
      createdAt: DateTime.now(),
    );
    folders.add(folder);
    await _saveFolders(folders);
    return folder;
  }

  Future<void> deleteFolder(String id) async {
    final folders = await getFolders();
    folders.removeWhere((folder) => folder.id == id);
    await _saveFolders(folders);
    final bookmarks = await getAll();
    final updated = bookmarks
        .map((item) =>
            item.folderId == id ? item.copyWith(folderId: null) : item)
        .toList();
    await _save(updated);
  }

  Future<void> _save(List<BookmarkItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(list.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _saveFolders(List<BookmarkFolder> folders) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(folders.map((folder) => folder.toJson()).toList());
    await prefs.setString(_folderKey, encoded);
  }
}
