import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/core/settings/audio_settings.dart';
import 'package:quran_app/core/settings/prayer_settings.dart';
import 'package:quran_app/core/settings/quran_settings.dart';
import 'package:quran_app/features/quran/presentation/pages/murotal_download_page.dart';
import 'package:quran_app/core/services/prayer_notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _enableNotifications = true;
  bool _manualLocationEnabled = false;
  String? _manualLocationName;
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
      _manualLocationEnabled =
          prefs.getBool('manual_location_enabled') ?? false;
      _manualLocationName = prefs.getString('manual_location_name');
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
              unawaited(_syncPrayerNotifications(val));
            },
          ),
          ListTile(
            title: const Text("Test Notifikasi"),
            subtitle: const Text("Kirim notifikasi uji dalam 5 detik"),
            leading: const Icon(Icons.notifications_active),
            onTap: () {
              unawaited(PrayerNotificationService.instance
                  .scheduleTestNotification());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Test notifikasi dijadwalkan."),
                ),
              );
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
          ListTile(
            title: const Text("Ukuran Teks"),
            subtitle: const Text("Arab & terjemahan"),
            leading: const Icon(Icons.text_fields),
            onTap: _showTextSizeSheet,
          ),
          ListTile(
            title: const Text("Font Arab"),
            subtitle: Text(_quranSettings.value.arabicFontFamily.label),
            leading: const Icon(Icons.font_download_outlined),
            onTap: _showArabicFontSheet,
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
          ListTile(
            title: const Text("Kecepatan Audio"),
            subtitle:
                Text("${_audioSettings.value.playbackSpeed.toStringAsFixed(2)}x"),
            leading: const Icon(Icons.speed),
            onTap: _showAudioSpeedSheet,
          ),
          ListTile(
            title: const Text("Murotal Offline"),
            subtitle: const Text("Kelola unduhan audio per surah"),
            leading: const Icon(Icons.cloud_download_outlined),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MurotalDownloadPage()),
              );
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
          SwitchListTile(
            title: const Text("Repeat Ayat"),
            subtitle: const Text("Ulangi audio saat diputar"),
            value: _audioSettings.value.repeatOne,
            onChanged: (val) {
              _audioSettings.updateRepeatOne(val);
            },
          ),
          const Divider(),
          _buildSectionHeader("Jadwal Sholat"),
          ListTile(
            title: const Text("Lokasi"),
            subtitle: Text(
              _manualLocationEnabled && _manualLocationName != null
                  ? _manualLocationName!
                  : "Otomatis (GPS)",
            ),
            leading: const Icon(Icons.location_on_outlined),
            onTap: _showManualLocationDialog,
          ),
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
            _buildSelectTile(
              title: TranslationSource.idKemenag.label,
              selected:
                  _quranSettings.value.translation == TranslationSource.idKemenag,
              onTap: () {
                _quranSettings.updateTranslation(TranslationSource.idKemenag);
                Navigator.pop(ctx);
              },
            ),
            _buildSelectTile(
              title: TranslationSource.idKingFahad.label,
              selected: _quranSettings.value.translation ==
                  TranslationSource.idKingFahad,
              onTap: () {
                _quranSettings.updateTranslation(TranslationSource.idKingFahad);
                Navigator.pop(ctx);
              },
            ),
            _buildSelectTile(
              title: TranslationSource.idSabiq.label,
              selected:
                  _quranSettings.value.translation == TranslationSource.idSabiq,
              onTap: () {
                _quranSettings.updateTranslation(TranslationSource.idSabiq);
                Navigator.pop(ctx);
              },
            ),
            _buildSelectTile(
              title: TranslationSource.enAbdelHaleem.label,
              selected: _quranSettings.value.translation ==
                  TranslationSource.enAbdelHaleem,
              onTap: () {
                _quranSettings.updateTranslation(
                    TranslationSource.enAbdelHaleem);
                Navigator.pop(ctx);
              },
            ),
            _buildSelectTile(
              title: TranslationSource.enSaheeh.label,
              selected:
                  _quranSettings.value.translation == TranslationSource.enSaheeh,
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
            _buildSelectTile(
              title: "Mishary Rashid Alafasy",
              selected: _audioSettings.value.qariId == 'alafasy',
              onTap: () {
                _audioSettings.updateQari('alafasy');
                Navigator.pop(ctx);
              },
            ),
            _buildSelectTile(
              title: "Abdul Basit (Murattal)",
              selected: _audioSettings.value.qariId == 'abdulbasit',
              onTap: () {
                _audioSettings.updateQari('abdulbasit');
                Navigator.pop(ctx);
              },
            ),
            _buildSelectTile(
              title: "Abdullah Basfar",
              selected: _audioSettings.value.qariId == 'basfar',
              onTap: () {
                _audioSettings.updateQari('basfar');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTextSizeSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ukuran Teks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildSlider(
                  label: 'Ukuran Arab',
                  value: _quranSettings.value.arabicFontSize,
                  min: 26,
                  max: 38,
                  onChanged: (value) =>
                      _quranSettings.setArabicFontSize(value),
                ),
                _buildSlider(
                  label: 'Ukuran Terjemahan',
                  value: _quranSettings.value.translationFontSize,
                  min: 12,
                  max: 20,
                  onChanged: (value) =>
                      _quranSettings.setTranslationFontSize(value),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showArabicFontSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Pilih Font Arab'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              ...ArabicFontFamily.values.map(
                (font) => _buildSelectTile(
                  title: font.label,
                  selected: _quranSettings.value.arabicFontFamily == font,
                  onTap: () {
                    _quranSettings.setArabicFontFamily(font);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAudioSpeedSheet() {
    const speeds = [0.75, 1.0, 1.25, 1.5];
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Kecepatan Audio'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              ...speeds.map(
                (speed) => _buildSelectTile(
                  title: '${speed.toStringAsFixed(2)}x',
                  selected: _audioSettings.value.playbackSpeed == speed,
                  onTap: () {
                    _audioSettings.updatePlaybackSpeed(speed);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showManualLocationDialog() {
    final controller =
        TextEditingController(text: _manualLocationName ?? '');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lokasi Manual'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Contoh: Yogyakarta',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('manual_location_enabled', false);
              if (!mounted) return;
              setState(() {
                _manualLocationEnabled = false;
                _manualLocationName = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Gunakan Otomatis'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final input = controller.text.trim();
              if (input.isEmpty) return;
              try {
                final locations = await locationFromAddress(input);
                if (locations.isEmpty) throw Exception('Lokasi tidak ditemukan');
                final location = locations.first;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('manual_location_enabled', true);
                await prefs.setString('manual_location_name', input);
                await prefs.setDouble('last_lat', location.latitude);
                await prefs.setDouble('last_lng', location.longitude);
                if (!mounted) return;
                setState(() {
                  _manualLocationEnabled = true;
                  _manualLocationName = input;
                });
                Navigator.pop(context);
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal menemukan lokasi.')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label),
              const Spacer(),
              Text(value.toStringAsFixed(0)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectTile({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: selected
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
      onTap: onTap,
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
            return _buildSelectTile(
              title: prayerMethodLabel(method),
              selected: _prayerSettings.value.method == method,
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
            return _buildSelectTile(
              title: prayerMadhabLabel(madhab),
              selected: _prayerSettings.value.madhab == madhab,
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

  Future<void> _syncPrayerNotifications(bool enabled) async {
    if (!enabled) {
      await PrayerNotificationService.instance.cancelAll();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('last_lat');
    final lng = prefs.getDouble('last_lng');
    if (lat == null || lng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Buka halaman Jadwal Sholat terlebih dahulu untuk menentukan lokasi.",
            ),
          ),
        );
      }
      return;
    }
    final params = _prayerSettings.buildParameters();
    final coords = Coordinates(lat, lng);
    final today = PrayerTimes.today(coords, params);
    final tomorrow = PrayerTimes(
      coords,
      DateComponents.from(DateTime.now().add(const Duration(days: 1))),
      params,
    );
    await PrayerNotificationService.instance.schedulePrayerTimes(
      today,
      tomorrow,
    );
  }
}
