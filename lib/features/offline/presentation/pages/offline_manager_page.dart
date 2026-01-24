import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:quran_app/core/services/audio_cache_service.dart';
import 'package:quran_app/core/services/tafsir_service.dart';
import 'package:quran_app/core/services/translation_service.dart';
import 'package:quran_app/core/settings/audio_settings.dart';
import 'package:quran_app/core/settings/quran_settings.dart';
import 'package:quran_app/features/quran/presentation/pages/murotal_download_page.dart';

class OfflineManagerPage extends StatefulWidget {
  const OfflineManagerPage({super.key});

  @override
  State<OfflineManagerPage> createState() => _OfflineManagerPageState();
}

class _OfflineManagerPageState extends State<OfflineManagerPage> {
  final AudioSettingsController _audioSettings =
      AudioSettingsController.instance;
  int _downloadedCount = 0;
  String _audioSizeLabel = '-';
  bool _tafsirAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioSettings.addListener(_refresh);
    _audioSettings.load();
    _refresh();
  }

  @override
  void dispose() {
    _audioSettings.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    final qariId = _audioSettings.value.qariId;
    final downloaded =
        await AudioCacheService.instance.listDownloadedSurahs(qariId);
    final audioSize = await _calculateAudioSize(qariId);
    final tafsirReady = await TafsirService.instance.hasOfflineData();
    if (!mounted) return;
    setState(() {
      _downloadedCount = downloaded.length;
      _audioSizeLabel = _formatBytes(audioSize);
      _tafsirAvailable = tafsirReady;
      _isLoading = false;
    });
  }

  Future<int> _calculateAudioSize(String qariId) async {
    final dir = await getApplicationDocumentsDirectory();
    final qari = AudioCacheService.instance.qariById(qariId);
    final audioDir = Directory('${dir.path}/audio/${qari.audioSlug}');
    if (!audioDir.existsSync()) return 0;
    var total = 0;
    for (final entity in audioDir.listSync(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final translationInfo = _translationStatus();
    return Scaffold(
      appBar: AppBar(title: const Text('Unduhan Offline')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('Data Al-Qur\'an'),
                _statusTile(
                  title: 'Teks Al-Qur\'an',
                  subtitle: 'Tersedia offline',
                  available: true,
                ),
                _statusTile(
                  title: 'Terjemahan Kemenag (ID)',
                  subtitle: translationInfo.kemenag,
                  available: translationInfo.kemenagAvailable,
                ),
                _statusTile(
                  title: 'Terjemahan King Fahad (ID)',
                  subtitle: translationInfo.kingFahad,
                  available: translationInfo.kingFahadAvailable,
                ),
                _statusTile(
                  title: 'Terjemahan Sabiq (ID)',
                  subtitle: translationInfo.sabiq,
                  available: translationInfo.sabiqAvailable,
                ),
                _statusTile(
                  title: 'Terjemahan Inggris',
                  subtitle: 'Tersedia offline (bawaan paket)',
                  available: true,
                ),
                _statusTile(
                  title: 'Word-by-word',
                  subtitle: 'Tersedia offline',
                  available: true,
                ),
                _statusTile(
                  title: 'Tafsir Indonesia',
                  subtitle: _tafsirAvailable
                      ? 'Tersedia offline'
                      : 'Tambahkan assets/tafsir_id.json',
                  available: _tafsirAvailable,
                ),
                const SizedBox(height: 16),
                _sectionTitle('Audio Murotal'),
                Card(
                  child: ListTile(
                    title: Text(
                      'Qari: ${AudioCacheService.instance.qariById(_audioSettings.value.qariId).label}',
                    ),
                    subtitle: Text(
                      '$_downloadedCount/114 surah • $_audioSizeLabel',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MurotalDownloadPage(),
                        ),
                      ).then((_) => _refresh());
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _downloadedCount == 0
                      ? null
                      : () async {
                          await AudioCacheService.instance
                              .deleteAllForQari(_audioSettings.value.qariId);
                          await _refresh();
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus semua audio'),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _statusTile({
    required String title,
    required String subtitle,
    required bool available,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          available ? Icons.check_circle : Icons.info_outline,
          color: available ? Theme.of(context).primaryColor : Colors.grey,
        ),
      ),
    );
  }

  _TranslationStatus _translationStatus() {
    final kemenagAvailable = true;
    final kingFahadAvailable =
        TranslationAssetService.instance.requiresAsset(TranslationSource.idKingFahad);
    final sabiqAvailable =
        TranslationAssetService.instance.requiresAsset(TranslationSource.idSabiq);
    return _TranslationStatus(
      kemenag: kemenagAvailable ? 'Tersedia offline' : 'Perlu unduh',
      kingFahad: kingFahadAvailable ? 'Tersedia offline' : 'Tidak ditemukan',
      sabiq: sabiqAvailable ? 'Tersedia offline' : 'Tidak ditemukan',
      kemenagAvailable: kemenagAvailable,
      kingFahadAvailable: kingFahadAvailable,
      sabiqAvailable: sabiqAvailable,
    );
  }
}

class _TranslationStatus {
  final String kemenag;
  final String kingFahad;
  final String sabiq;
  final bool kemenagAvailable;
  final bool kingFahadAvailable;
  final bool sabiqAvailable;

  const _TranslationStatus({
    required this.kemenag,
    required this.kingFahad,
    required this.sabiq,
    required this.kemenagAvailable,
    required this.kingFahadAvailable,
    required this.sabiqAvailable,
  });
}
