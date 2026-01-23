import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/core/settings/quran_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedQari = 'alafasy'; // Default ID for Mishary Rashid Alafasy
  bool _enableNotifications = true;
  double _volume = 1.0;
  final QuranSettingsController _quranSettings =
      QuranSettingsController.instance;

  @override
  void initState() {
    super.initState();
    _quranSettings.addListener(_onSettingsChanged);
    _loadSettings();
  }

  @override
  void dispose() {
    _quranSettings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSettings() async {
    await _quranSettings.load();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedQari = prefs.getString('qari') ?? 'alafasy';
      _enableNotifications = prefs.getBool('notifications') ?? true;
      _volume = prefs.getDouble('volume') ?? 1.0;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) prefs.setString(key, value);
    if (value is bool) prefs.setBool(key, value);
    if (value is double) prefs.setDouble(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("Umum"),
          SwitchListTile(
            title: const Text("Notifikasi Adzan"),
            subtitle: const Text("Aktifkan pengingat waktu sholat"),
            value: _enableNotifications,
            // activeColor removed to use Theme primary color automatically and avoid deprecation warning
            onChanged: (val) {
              setState(() => _enableNotifications = val);
              _saveSetting('notifications', val);
            },
          ),
          const Divider(),
          _buildSectionHeader("Al-Quran & Audio"),
          ListTile(
            title: const Text("Terjemahan"),
            subtitle: Text(_translationLabel(_quranSettings.value.translation)),
            leading: const Icon(Icons.translate),
            onTap: () {
              _showTranslationDialog();
            },
          ),
          SwitchListTile(
            title: const Text("Transliterasi (Latin)"),
            subtitle: const Text("Tampilkan teks latin"),
            value: _quranSettings.value.showLatin,
            // ignore: deprecated_member_use
            activeColor: Theme.of(context).primaryColor,
            onChanged: (val) {
              _quranSettings.setShowLatin(val);
            },
          ),
          SwitchListTile(
            title: const Text("Tajwid"),
            subtitle: const Text("Tampilkan warna tajwid pada teks Arab"),
            value: _quranSettings.value.showTajwid,
            // ignore: deprecated_member_use
            activeColor: Theme.of(context).primaryColor,
            onChanged: (val) {
              _quranSettings.setShowTajwid(val);
            },
          ),
          SwitchListTile(
            title: const Text("Terjemahan Per Kata"),
            subtitle: const Text("Tampilkan arti per kata di bawah ayat"),
            value: _quranSettings.value.showWordByWord,
            // ignore: deprecated_member_use
            activeColor: Theme.of(context).primaryColor,
            onChanged: (val) {
              _quranSettings.setShowWordByWord(val);
            },
          ),
          ListTile(
            title: const Text("Qari (Pembaca)"),
            subtitle: Text(_getQariName(_selectedQari)),
            leading: const Icon(Icons.mic),
            onTap: () {
              _showQariDialog();
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.volume_down, color: Colors.grey),
                Expanded(
                  child: Slider(
                    value: _volume,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) {
                      setState(() => _volume = val);
                    },
                    onChangeEnd: (val) {
                      _saveSetting('volume', val);
                    },
                  ),
                ),
                const Icon(Icons.volume_up, color: Colors.grey),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader("Tentang"),
          ListTile(
            title: const Text("Versi Aplikasi"),
            subtitle: const Text("1.0.0 (Release)"),
            leading: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  String _getQariName(String id) {
    switch (id) {
      case 'alafasy':
        return "Mishary Rashid Alafasy";
      case 'sudais':
        return "Abdurrahmaan As-Sudais";
      case 'ghamadi':
        return "Saad Al-Ghamdi";
      default:
        return "Mishary Rashid Alafasy";
    }
  }

  String _translationLabel(TranslationLanguage language) {
    switch (language) {
      case TranslationLanguage.id:
        return "Bahasa Indonesia";
      case TranslationLanguage.en:
        return "English (Abdel Haleem)";
    }
  }

  void _showTranslationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pilih Terjemahan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Bahasa Indonesia"),
              leading: Radio<String>(
                value: 'id',
                // ignore: deprecated_member_use
                groupValue:
                    _quranSettings.value.translation == TranslationLanguage.id
                        ? 'id'
                        : 'en',
                // ignore: deprecated_member_use
                onChanged: (val) {
                  _quranSettings.updateTranslation(TranslationLanguage.id);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                _quranSettings.updateTranslation(TranslationLanguage.id);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text("English (Abdel Haleem)"),
              leading: Radio<String>(
                value: 'en',
                // ignore: deprecated_member_use
                groupValue:
                    _quranSettings.value.translation == TranslationLanguage.id
                        ? 'id'
                        : 'en',
                // ignore: deprecated_member_use
                onChanged: (val) {
                  _quranSettings.updateTranslation(TranslationLanguage.en);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                _quranSettings.updateTranslation(TranslationLanguage.en);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQariDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pilih Qari"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQariItem('alafasy', "Mishary Rashid Alafasy"),
            _buildQariItem('sudais', "Abdurrahmaan As-Sudais"),
            _buildQariItem('ghamadi', "Saad Al-Ghamdi"),
          ],
        ),
      ),
    );
  }

  Widget _buildQariItem(String id, String name) {
    return ListTile(
      title: Text(name),
      leading: Radio<String>(
        value: id,
        // ignore: deprecated_member_use
        groupValue: _selectedQari,
        // ignore: deprecated_member_use
        onChanged: (val) {
          setState(() => _selectedQari = val.toString());
          _saveSetting('qari', val);
          Navigator.pop(context);
        },
      ),
      onTap: () {
        setState(() => _selectedQari = id);
        _saveSetting('qari', id);
        Navigator.pop(context);
      },
    );
  }
}
