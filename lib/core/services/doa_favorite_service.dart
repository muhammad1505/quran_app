import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class DoaFavoriteService {
  static const _storageKey = 'doa_favorites';

  Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => e.toString()).toSet();
  }

  Future<Set<String>> toggle(String id) async {
    final favorites = await getFavorites();
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    await _save(favorites);
    return favorites;
  }

  Future<void> _save(Set<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(favorites.toList()));
  }
}
