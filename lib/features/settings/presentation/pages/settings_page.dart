import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/core/settings/audio_settings.dart';
import 'package:quran_app/core/settings/prayer_settings.dart';
import 'package:quran_app/core/settings/quran_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _enableNotifications = true;
  final QuranSettingsController _quranSettings =
      QuranSettingsController.instance;
  final AudioSettingsController _audioSettings =
      AudioSettingsController.instance;
  final PrayerSettingsController _prayerSettings =
      PrayerSettingsController.instance;

  @override
  void initState() {
    super.initState();
    _quranSettings.addListener(_onSettingsChanged);
    _audioSettings.addListener(_onSettingsChanged);
    _prayerSettings.addListener(_onSettingsChanged);
    _loadSettings();
  }

  @override
  void dispose() {
    _quranSettings.removeListener(_onSettingsChanged);
    _audioSettings.removeListener(_onSettingsChanged);
    _prayerSettings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSettings() async {
    await _quranSettings.load();
    await _audioSettings.load();
    await _prayerSettings.load();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableNotifications = prefs.getBool('notifications') ?? true;
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
            subtitle: Text(_quranSettings.value.translation.label),
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
            subtitle: Text(_getQariName(_audioSettings.value.qariId)),
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
                    value: _audioSettings.value.volume,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) {
                      _audioSettings.updateVolume(val);
                    },
                    onChangeEnd: (val) {
                      _audioSettings.updateVolume(val);
                    },
                  ),
                ),
                const Icon(Icons.volume_up, color: Colors.grey),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader("Jadwal Sholat"),
          ListTile(
            title: const Text("Metode Perhitungan"),
            subtitle: Text(prayerMethodLabel(_prayerSettings.value.method)),
            leading: const Icon(Icons.calculate),
            onTap: () => _showPrayerMethodDialog(),
          ),
          ListTile(
            title: const Text("Madhab"),
            subtitle: Text(prayerMadhabLabel(_prayerSettings.value.madhab)),
            leading: const Icon(Icons.menu_book),
            onTap: () => _showMadhabDialog(),
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
      case 'abdulbasit':
        return "Abdul Basit (Murattal)";
      case 'basfar':
        return "Abdullah Basfar";
      default:
        return "Mishary Rashid Alafasy";
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
              title: Text(TranslationSource.idKemenag.label),
              leading: Radio<String>(
                value: TranslationSource.idKemenag.name,
                // ignore: deprecated_member_use
                groupValue:
                    _quranSettings.value.translation.name,
                // ignore: deprecated_member_use
                onChanged: (val) {
                  _quranSettings.updateTranslation(TranslationSource.idKemenag);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                _quranSettings.updateTranslation(TranslationSource.idKemenag);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(TranslationSource.enAbdelHaleem.label),
              leading: Radio<String>(
                value: TranslationSource.enAbdelHaleem.name,
                // ignore: deprecated_member_use
                groupValue: _quranSettings.value.translation.name,
                // ignore: deprecated_member_use
                onChanged: (val) {
                  _quranSettings.updateTranslation(
                      TranslationSource.enAbdelHaleem);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                _quranSettings.updateTranslation(
                    TranslationSource.enAbdelHaleem);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(TranslationSource.enSaheeh.label),
              leading: Radio<String>(
                value: TranslationSource.enSaheeh.name,
                // ignore: deprecated_member_use
                groupValue: _quranSettings.value.translation.name,
                // ignore: deprecated_member_use
                onChanged: (val) {
                  _quranSettings.updateTranslation(TranslationSource.enSaheeh);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                _quranSettings.updateTranslation(TranslationSource.enSaheeh);
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
            _buildQariItem('abdulbasit', "Abdul Basit (Murattal)"),
            _buildQariItem('basfar', "Abdullah Basfar"),
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
        groupValue: _audioSettings.value.qariId,
        // ignore: deprecated_member_use
        onChanged: (val) {
          _audioSettings.updateQari(val.toString());
          Navigator.pop(context);
        },
      ),
      onTap: () {
        _audioSettings.updateQari(id);
        Navigator.pop(context);
      },
    );
  }

  void _showPrayerMethodDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Metode Perhitungan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PrayerCalculationMethod.values.map((method) {
            return ListTile(
              title: Text(prayerMethodLabel(method)),
              leading: Radio<String>(
                value: method.name,
                // ignore: deprecated_member_use
                groupValue: _prayerSettings.value.method.name,
                // ignore: deprecated_member_use
                onChanged: (val) {
                  _prayerSettings.updateMethod(method);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                _prayerSettings.updateMethod(method);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMadhabDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pilih Madhab"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PrayerMadhab.values.map((madhab) {
            return ListTile(
              title: Text(prayerMadhabLabel(madhab)),
              leading: Radio<String>(
                value: madhab.name,
                // ignore: deprecated_member_use
                groupValue: _prayerSettings.value.madhab.name,
                // ignore: deprecated_member_use
                onChanged: (val) {
                  _prayerSettings.updateMadhab(madhab);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                _prayerSettings.updateMadhab(madhab);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
