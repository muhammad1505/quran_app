import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedTranslation = 'id';
  String _selectedQari = 'alafasy'; // Default ID for Mishary Rashid Alafasy
  bool _enableNotifications = true;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTranslation = prefs.getString('translation') ?? 'id';
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
            subtitle: Text(
              _selectedTranslation == 'id'
                  ? 'Bahasa Indonesia'
                  : 'English (Saheeh)',
            ),
            leading: const Icon(Icons.translate),
            onTap: () {
              _showTranslationDialog();
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
                groupValue: _selectedTranslation,
                onChanged: (val) {
                  setState(() => _selectedTranslation = val.toString());
                  _saveSetting('translation', val);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                setState(() => _selectedTranslation = 'id');
                _saveSetting('translation', 'id');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text("English (Saheeh)"),
              leading: Radio<String>(
                value: 'en',
                groupValue: _selectedTranslation,
                onChanged: (val) {
                  setState(() => _selectedTranslation = val.toString());
                  _saveSetting('translation', val);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                setState(() => _selectedTranslation = 'en');
                _saveSetting('translation', 'en');
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
        groupValue: _selectedQari,
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
