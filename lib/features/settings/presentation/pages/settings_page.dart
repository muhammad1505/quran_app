import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/core/settings/audio_settings.dart';
import 'package:quran_app/core/settings/prayer_settings.dart';
import 'package:quran_app/core/settings/quran_settings.dart';
import 'package:quran_app/core/settings/theme_settings.dart';
import 'package:quran_app/core/services/auth_service.dart';
import 'package:quran_app/core/services/backup_service.dart';
import 'package:quran_app/features/offline/presentation/pages/offline_manager_page.dart';
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
  bool _isBackupRunning = false;
  bool _isRestoreRunning = false;
  final QuranSettingsController _quranSettings =
      QuranSettingsController.instance;
  final AudioSettingsController _audioSettings =
      AudioSettingsController.instance;
  final PrayerSettingsController _prayerSettings =
      PrayerSettingsController.instance;
  final ThemeSettingsController _themeSettings =
      ThemeSettingsController.instance;

  @override
  void initState() {
    super.initState();
    _quranSettings.addListener(_onSettingsChanged);
    _audioSettings.addListener(_onSettingsChanged);
    _prayerSettings.addListener(_onSettingsChanged);
    _themeSettings.addListener(_onSettingsChanged);
    _loadSettings();
  }

  @override
  void dispose() {
    _quranSettings.removeListener(_onSettingsChanged);
    _audioSettings.removeListener(_onSettingsChanged);
    _prayerSettings.removeListener(_onSettingsChanged);
    _themeSettings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshPrayerNotifications() async {
    await _syncPrayerNotifications(_enableNotifications);
  }

  Future<void> _loadSettings() async {
    await _quranSettings.load();
    await _audioSettings.load();
    await _prayerSettings.load();
    await _themeSettings.load();
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
          _buildAccountSection(),
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
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final success = await PrayerNotificationService.instance
                  .scheduleTestNotification();
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? "Test notifikasi dijadwalkan."
                        : "Izin notifikasi belum diberikan.",
                  ),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader("Tampilan"),
          ListTile(
            title: const Text("Tema"),
            subtitle: Text(_themeModeLabel(_themeSettings.value.mode)),
            leading: const Icon(Icons.brightness_6_outlined),
            onTap: _showThemeDialog,
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
            title: const Text("Sumber Tafsir"),
            subtitle: Text(_quranSettings.value.tafsirSource.label),
            leading: const Icon(Icons.menu_book_outlined),
            onTap: _showTafsirSourceDialog,
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
          SwitchListTile(
            title: const Text("Auto-play Ayat Berikutnya"),
            subtitle: const Text("Lanjutkan otomatis ke ayat berikutnya"),
            value: _audioSettings.value.autoPlayNextAyah,
            onChanged: (val) {
              _audioSettings.updateAutoPlayNextAyah(val);
            },
          ),
          const Divider(),
          _buildSectionHeader("Offline"),
          ListTile(
            title: const Text("Unduhan Offline"),
            subtitle: const Text("Kelola audio, terjemahan, dan tafsir"),
            leading: const Icon(Icons.download_for_offline),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfflineManagerPage(),
                ),
              );
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
          ListTile(
            title: const Text("Koreksi Menit"),
            subtitle: Text(
              _prayerSettings.value.correctionMinutes == 0
                  ? 'Tidak ada koreksi'
                  : '${_prayerSettings.value.correctionMinutes > 0 ? '+' : ''}${_prayerSettings.value.correctionMinutes} menit',
            ),
            leading: const Icon(Icons.tune),
            onTap: _showCorrectionSheet,
          ),
          ListTile(
            title: const Text("Notifikasi per Waktu"),
            subtitle: const Text("Atur pengingat setiap sholat"),
            leading: const Icon(Icons.notifications_active_outlined),
            onTap: _showPrayerNotificationSheet,
          ),
          ListTile(
            title: const Text("Suara Adzan"),
            subtitle: Text(_prayerSettings.value.adzanSound.label),
            leading: const Icon(Icons.volume_up_outlined),
            onTap: _showAdzanSheet,
          ),
          SwitchListTile(
            title: const Text("Mode Silent Saat Sholat"),
            subtitle: const Text("Matikan suara notifikasi"),
            value: _prayerSettings.value.silentMode,
            onChanged: (value) async {
              await _prayerSettings.setSilentMode(value);
              await _refreshPrayerNotifications();
            },
          ),
          const Divider(),
          _buildSectionHeader("Tentang"),
          const ListTile(
            title: Text("Versi Aplikasi"),
            subtitle: Text("1.0.0 (Release)"),
            leading: Icon(Icons.info_outline),
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

  Widget _buildAccountSection() {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? AuthService.instance.currentUser;
        final isLoggedIn = user != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Akun & Backup'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(
                  isLoggedIn
                      ? (user.displayName ?? 'Akun Google')
                      : 'Belum login',
                ),
                subtitle: Text(
                  isLoggedIn
                      ? (user.email ?? 'Login dengan Google')
                      : 'Masuk untuk backup data & pengaturan',
                ),
                trailing: isLoggedIn
                    ? TextButton(
                        onPressed: _isBackupRunning || _isRestoreRunning
                            ? null
                            : () async {
                                final messenger =
                                    ScaffoldMessenger.of(context);
                                try {
                                  await AuthService.instance.signOut();
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Berhasil logout.'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Logout gagal: $e'),
                                    ),
                                  );
                                }
                              },
                        child: const Text('Keluar'),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await AuthService.instance.signInWithGoogle();
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Login berhasil.'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(content: Text('Login gagal: $e')),
                            );
                          }
                        },
                        child: const Text('Login Google'),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: const Text('Backup sekarang'),
                subtitle: const Text('Simpan bookmark & pengaturan ke akun'),
                trailing: _isBackupRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                enabled: isLoggedIn && !_isBackupRunning && !_isRestoreRunning,
                onTap: !isLoggedIn || _isBackupRunning || _isRestoreRunning
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isBackupRunning = true);
                        try {
                          await BackupService.instance.backupNow();
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Backup berhasil.')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text('Backup gagal: $e')),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isBackupRunning = false);
                          }
                        }
                      },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text('Pulihkan backup'),
                subtitle: const Text('Ambil data terakhir dari cloud'),
                trailing: _isRestoreRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                enabled: isLoggedIn && !_isBackupRunning && !_isRestoreRunning,
                onTap: !isLoggedIn || _isBackupRunning || _isRestoreRunning
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Pulihkan Backup'),
                            content: const Text(
                              'Data lokal akan diganti dengan data dari cloud. Lanjutkan?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Pulihkan'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        setState(() => _isRestoreRunning = true);
                        try {
                          final restored =
                              await BackupService.instance.restoreLatest();
                          if (!mounted) return;
                          await _loadSettings();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                restored
                                    ? 'Restore berhasil.'
                                    : 'Belum ada data backup.',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text('Restore gagal: $e')),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isRestoreRunning = false);
                          }
                        }
                      },
              ),
            ),
            const Divider(),
          ],
        );
      },
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

  void _showCorrectionSheet() {
    var temp = _prayerSettings.value.correctionMinutes.toDouble();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Koreksi Menit',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      temp == 0
                          ? '0 menit'
                          : '${temp > 0 ? '+' : ''}${temp.toInt()} menit',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Slider(
                      value: temp,
                      min: -30,
                      max: 30,
                      divisions: 60,
                      label: temp.toInt().toString(),
                      onChanged: (value) {
                        setSheetState(() => temp = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          await _prayerSettings
                              .updateCorrectionMinutes(temp.toInt());
                          if (!mounted) return;
                          navigator.pop();
                          await _refreshPrayerNotifications();
                        },
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPrayerNotificationSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Notifikasi per Waktu')),
              SwitchListTile(
                title: const Text('Subuh'),
                value: _prayerSettings.value.notifyFajr,
                onChanged: (value) async {
                  await _prayerSettings.setNotificationEnabled(
                    Prayer.fajr,
                    value,
                  );
                  await _refreshPrayerNotifications();
                },
              ),
              SwitchListTile(
                title: const Text('Dzuhur'),
                value: _prayerSettings.value.notifyDhuhr,
                onChanged: (value) async {
                  await _prayerSettings.setNotificationEnabled(
                    Prayer.dhuhr,
                    value,
                  );
                  await _refreshPrayerNotifications();
                },
              ),
              SwitchListTile(
                title: const Text('Ashar'),
                value: _prayerSettings.value.notifyAsr,
                onChanged: (value) async {
                  await _prayerSettings.setNotificationEnabled(
                    Prayer.asr,
                    value,
                  );
                  await _refreshPrayerNotifications();
                },
              ),
              SwitchListTile(
                title: const Text('Maghrib'),
                value: _prayerSettings.value.notifyMaghrib,
                onChanged: (value) async {
                  await _prayerSettings.setNotificationEnabled(
                    Prayer.maghrib,
                    value,
                  );
                  await _refreshPrayerNotifications();
                },
              ),
              SwitchListTile(
                title: const Text('Isya'),
                value: _prayerSettings.value.notifyIsha,
                onChanged: (value) async {
                  await _prayerSettings.setNotificationEnabled(
                    Prayer.isha,
                    value,
                  );
                  await _refreshPrayerNotifications();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showAdzanSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Pilih Suara Adzan')),
              RadioGroup<AdzanSound>(
                groupValue: _prayerSettings.value.adzanSound,
                onChanged: (value) async {
                  if (value == null) return;
                  final navigator = Navigator.of(context);
                  await _prayerSettings.setAdzanSound(value);
                  if (!mounted) return;
                  navigator.pop();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AdzanSound.values
                      .map(
                        (sound) => RadioListTile<AdzanSound>(
                          value: sound,
                          title: Text(sound.label),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _themeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return "Terang";
      case AppThemeMode.dark:
        return "Gelap";
      case AppThemeMode.sepia:
        return "Sepia";
    }
  }

  void _showThemeDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Pilih Tema"),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              RadioGroup<AppThemeMode>(
                groupValue: _themeSettings.value.mode,
                onChanged: (value) {
                  if (value == null) return;
                  _themeSettings.setThemeMode(value);
                  Navigator.pop(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AppThemeMode.values
                      .map(
                        (mode) => RadioListTile<AppThemeMode>(
                          value: mode,
                          title: Text(_themeModeLabel(mode)),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  void _showTafsirSourceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sumber Tafsir"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TafsirSource.values.map((source) {
            return _buildSelectTile(
              title: source.label,
              selected: _quranSettings.value.tafsirSource == source,
              onTap: () {
                _quranSettings.setTafsirSource(source);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
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
              final navigator = Navigator.of(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('manual_location_enabled', false);
              if (!mounted) return;
              setState(() {
                _manualLocationEnabled = false;
                _manualLocationName = null;
              });
              navigator.pop();
            },
            child: const Text('Gunakan Otomatis'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
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
                navigator.pop();
              } catch (_) {
                if (!mounted) return;
                messenger.showSnackBar(
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
    final permissionGranted =
        await PrayerNotificationService.instance.requestPermissions();
    if (!permissionGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Izin notifikasi belum diberikan."),
          ),
        );
      }
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
      _prayerSettings.value,
    );
  }
}
