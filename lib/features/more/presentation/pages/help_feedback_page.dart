import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyText(String text) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Teks disalin.')),
    );
  }

  Future<void> _shareFeedback() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis pesan dulu ya.')),
      );
      return;
    }
    await Share.share('Masukan untuk Al-Quran Terjemahan:\n\n$message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan & Feedback')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'FAQ Singkat',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildFaqCard(
            context,
            title: 'Lokasi tidak terdeteksi?',
            body:
                'Pastikan izin lokasi aktif dan GPS menyala. Jika masih gagal, buka Jadwal Sholat sekali untuk menyimpan lokasi terakhir.',
          ),
          _buildFaqCard(
            context,
            title: 'Notifikasi adzan tidak muncul?',
            body:
                'Pastikan izin notifikasi aktif dan tidak dibatasi oleh mode hemat baterai. Coba tombol “Test Notifikasi” di Pengaturan.',
          ),
          _buildFaqCard(
            context,
            title: 'Audio tidak keluar?',
            body:
                'Cek volume media dan pastikan perangkat tidak dalam mode senyap. Coba pilih ulang qari di Pengaturan.',
          ),
          const SizedBox(height: 16),
          Text(
            'Kirim Masukan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ceritakan kendala atau saranmu'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    minLines: 4,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan di sini...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareFeedback,
                          icon: const Icon(Icons.send_outlined),
                          label: const Text('Kirim'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => _copyText(_controller.text),
                        child: const Text('Salin'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kontak',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('support@alquran-terjemahan.app'),
              subtitle: const Text('Email bantuan & feedback'),
              trailing: const Icon(Icons.copy),
              onTap: () => _copyText('support@alquran-terjemahan.app'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
