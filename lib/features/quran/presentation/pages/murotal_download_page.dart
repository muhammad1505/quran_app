import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;

import 'package:quran_app/core/services/audio_cache_service.dart';
import 'package:quran_app/core/settings/audio_settings.dart';

class MurotalDownloadPage extends StatefulWidget {
  const MurotalDownloadPage({super.key});

  @override
  State<MurotalDownloadPage> createState() => _MurotalDownloadPageState();
}

class _MurotalDownloadPageState extends State<MurotalDownloadPage> {
  final AudioSettingsController _audioSettings =
      AudioSettingsController.instance;
  String _selectedQariId = 'alafasy';
  Set<int> _downloadedSurahs = {};
  final Set<int> _busySurahs = {};
  bool _isLoading = true;
  bool _isBulkAction = false;

  @override
  void initState() {
    super.initState();
    _audioSettings.addListener(_syncQari);
    _audioSettings.load();
    _selectedQariId = _audioSettings.value.qariId;
    _loadDownloaded();
  }

  @override
  void dispose() {
    _audioSettings.removeListener(_syncQari);
    super.dispose();
  }

  void _syncQari() {
    if (_selectedQariId != _audioSettings.value.qariId) {
      setState(() => _selectedQariId = _audioSettings.value.qariId);
      _loadDownloaded();
    }
  }

  Future<void> _loadDownloaded() async {
    setState(() => _isLoading = true);
    final result = await AudioCacheService.instance
        .listDownloadedSurahs(_selectedQariId);
    if (mounted) {
      setState(() {
        _downloadedSurahs = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDownload(int surahNumber) async {
    if (_busySurahs.contains(surahNumber)) return;
    setState(() => _busySurahs.add(surahNumber));
    try {
      if (_downloadedSurahs.contains(surahNumber)) {
        await AudioCacheService.instance
            .deleteSurah(surahNumber, _selectedQariId);
        _downloadedSurahs.remove(surahNumber);
      } else {
        await AudioCacheService.instance
            .downloadSurah(surahNumber, _selectedQariId);
        _downloadedSurahs.add(surahNumber);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memproses audio: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busySurahs.remove(surahNumber));
      }
    }
  }

  Future<void> _confirmBulkAction({required bool download}) async {
    final action = download ? 'Unduh' : 'Hapus';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Semua Murotal'),
        content: Text(
          download
              ? 'Ini akan mengunduh semua surah untuk qari terpilih. Ukuran file cukup besar. Lanjutkan?'
              : 'Ini akan menghapus semua audio offline untuk qari terpilih. Lanjutkan?',
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
    setState(() => _isBulkAction = true);
    try {
      if (download) {
        for (var surah = 1; surah <= 114; surah++) {
          await AudioCacheService.instance
              .downloadSurah(surah, _selectedQariId);
        }
      } else {
        await AudioCacheService.instance.deleteAllForQari(_selectedQariId);
      }
      await _loadDownloaded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memproses audio: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBulkAction = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qaris = AudioCacheService.qaris;
    return Scaffold(
      appBar: AppBar(title: const Text('Murotal Offline')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedQariId,
                    decoration: const InputDecoration(
                      labelText: 'Qari',
                      border: OutlineInputBorder(),
                    ),
                    items: qaris
                        .map(
                          (qari) => DropdownMenuItem<String>(
                            value: qari.id,
                            child: Text(qari.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedQariId = value);
                      _audioSettings.updateQari(value);
                      _loadDownloaded();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _isBulkAction ? null : () => _confirmBulkAction(download: true),
                  icon: const Icon(Icons.download),
                  tooltip: 'Unduh semua',
                ),
                IconButton(
                  onPressed: _isBulkAction ? null : () => _confirmBulkAction(download: false),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Hapus semua',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: 114,
                    itemBuilder: (context, index) {
                      final surahNumber = index + 1;
                      final downloaded = _downloadedSurahs.contains(surahNumber);
                      final busy = _busySurahs.contains(surahNumber);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: downloaded
                                ? Theme.of(context).primaryColor
                                : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            child: Text(
                              surahNumber.toString(),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            quran.getSurahName(surahNumber),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            quran.getSurahNameArabic(surahNumber),
                            style: GoogleFonts.amiri(fontSize: 18),
                          ),
                          trailing: busy
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  icon: Icon(
                                    downloaded ? Icons.check_circle : Icons.download,
                                    color: downloaded
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[500],
                                  ),
                                  onPressed: () => _toggleDownload(surahNumber),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
