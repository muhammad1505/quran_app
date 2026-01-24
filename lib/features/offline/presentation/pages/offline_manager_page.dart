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
  int _tafsirCount = 0;
  String _tafsirSizeLabel = '-';
  bool _isTafsirDownloading = false;
  double _tafsirProgress = 0;
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
    final tafsirCache = await TafsirService.instance
        .getCacheInfo(QuranSettingsController.instance.value.tafsirSource);
    if (!mounted) return;
    setState(() {
      _downloadedCount = downloaded.length;
      _audioSizeLabel = _formatBytes(audioSize);
      _tafsirAvailable = tafsirReady;
      _tafsirCount = tafsirCache.count;
      _tafsirSizeLabel = _formatBytes(tafsirCache.bytes);
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
    final tafsirSource = QuranSettingsController.instance.value.tafsirSource;
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
                      ? 'Tersedia offline (lokal)'
                      : 'Sumber: ${tafsirSource.label}',
                  available: _tafsirAvailable,
                ),
                Card(
                  child: ListTile(
                    title: const Text('Cache Tafsir'),
                    subtitle: Text('$_tafsirCount/114 surah • $_tafsirSizeLabel'),
                    trailing: _isTafsirDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isTafsirDownloading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(value: _tafsirProgress),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isTafsirDownloading
                            ? null
                            : () => _downloadTafsirPack(tafsirSource),
                        icon: const Icon(Icons.download),
                        label: const Text('Unduh Tafsir'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isTafsirDownloading
                            ? null
                            : () => _clearTafsirCache(tafsirSource),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus Cache'),
                      ),
                    ),
                  ],
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
    const kemenagAvailable = true;
    final kingFahadAvailable =
        TranslationAssetService.instance.requiresAsset(TranslationSource.idKingFahad);
    final sabiqAvailable =
        TranslationAssetService.instance.requiresAsset(TranslationSource.idSabiq);
    return _TranslationStatus(
      kemenag: 'Tersedia offline',
      kingFahad: kingFahadAvailable ? 'Tersedia offline' : 'Tidak ditemukan',
      sabiq: sabiqAvailable ? 'Tersedia offline' : 'Tidak ditemukan',
      kemenagAvailable: kemenagAvailable,
      kingFahadAvailable: kingFahadAvailable,
      sabiqAvailable: sabiqAvailable,
    );
  }

  Future<void> _downloadTafsirPack(TafsirSource source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unduh Tafsir'),
        content: Text(
          'Ini akan mengunduh tafsir 114 surah dari ${source.label}. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _isTafsirDownloading = true;
      _tafsirProgress = 0;
    });
    try {
      for (var surah = 1; surah <= 114; surah++) {
        await TafsirService.instance.downloadSurah(source, surah);
        if (!mounted) return;
        setState(() {
          _tafsirProgress = surah / 114;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunduh tafsir: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTafsirDownloading = false);
        _refresh();
      }
    }
  }

  Future<void> _clearTafsirCache(TafsirSource source) async {
    await TafsirService.instance.clearCache(source);
    await _refresh();
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
