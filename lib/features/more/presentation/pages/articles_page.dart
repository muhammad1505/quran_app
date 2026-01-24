import 'package:flutter/material.dart';

class ArticlesPage extends StatelessWidget {
  const ArticlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final articles = _articles;
    return Scaffold(
      appBar: AppBar(title: const Text('Artikel Panduan')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(article.title),
              subtitle: Text(article.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailPage(article: article),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ArticleDetailPage extends StatelessWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            article.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(article.body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class Article {
  final String title;
  final String subtitle;
  final String body;

  const Article({
    required this.title,
    required this.subtitle,
    required this.body,
  });
}

const List<Article> _articles = [
  Article(
    title: 'Panduan Wudhu',
    subtitle: 'Langkah wudhu yang benar dan rapi',
    body:
        '1. Niat wudhu di dalam hati.\n2. Membasuh wajah tiga kali.\n3. Membasuh kedua tangan hingga siku tiga kali.\n4. Mengusap sebagian kepala.\n5. Membersihkan kedua telinga.\n6. Membasuh kedua kaki hingga mata kaki tiga kali.\n\nPastikan tertib sesuai urutan dan membaca doa setelah wudhu.',
  ),
  Article(
    title: 'Panduan Tayammum',
    subtitle: 'Pengganti wudhu saat tidak ada air',
    body:
        '1. Niat tayammum.\n2. Tepukkan kedua telapak tangan pada debu suci.\n3. Usapkan ke wajah.\n4. Tepuk kembali lalu usapkan ke kedua tangan hingga pergelangan.\n\nTayammum dilakukan ketika tidak ada air atau tidak bisa menggunakan air.',
  ),
  Article(
    title: 'Adab di Masjid',
    subtitle: 'Etika saat beribadah di masjid',
    body:
        'Datang dalam keadaan suci, menjaga kebersihan, mendahulukan kaki kanan, memperbanyak dzikir, dan menjaga ketenangan. Hindari berbicara keras atau mengganggu jamaah lain.',
  ),
];
