# Repository Guidelines

## Struktur Proyek & Organisasi Modul
- `lib/` berisi source Flutter; titik masuk utama di `lib/main.dart`.
- Fitur dikelompokkan di `lib/features/` (contoh: `quran`, `prayer_times`, `qibla`, `doa`, `settings`), UI ada di `presentation/`.
- Komponen bersama dan tema ada di `lib/core/` (`core/theme`, `core/widgets`).
- Aset (gambar, font, dll.) ada di `assets/` dan dideklarasikan di `pubspec.yaml`.
- Test berada di `test/` (saat ini `test/widget_test.dart`).
- Berkas khusus Android ada di `android/`.

## Perintah Build, Test, dan Development
- `flutter pub get` — pasang dependensi.
- `flutter run` — jalankan aplikasi di device/emulator.
- `flutter analyze` — analisis statis dengan `flutter_lints`.
- `flutter test` — jalankan seluruh test.
- `flutter build apk --debug` — build APK debug (dipakai di CI).
- `flutter create .` — hanya jika folder platform hilang, scaffold ulang.

## Gaya Kode & Konvensi Penamaan
- Ikuti gaya standar Dart/Flutter: indentasi 2 spasi dan format `dart format`.
- Nama file/folder gunakan `lower_snake_case` (mis. `quran_page.dart`).
- Class `UpperCamelCase`; method/variable `lowerCamelCase`.
- Tetap pakai struktur feature-first di `lib/features/<fitur>/presentation/...`.

## Panduan Testing
- Gunakan `flutter_test` untuk widget test; `bloc_test` dan `mocktail` tersedia untuk unit test/mocking.
- Nama file test mengikuti pola `*_test.dart` di folder `test/`.
- Belum ada target coverage; tambahkan test untuk alur UI dan logika baru.

## Fitur Al-Qur'an & Pengaturan Terjemahan
- Terjemahan Al-Qur'an wajib mendukung Bahasa Indonesia (ID) dan Inggris (EN).
- Pengaturan bahasa terjemahan ditempatkan di `lib/features/settings/`.
- Tambahkan opsi: pilihan bahasa terjemahan, tampilan tajwid, teks latin, dan terjemahan per kata.
- Pastikan perubahan bahasa memengaruhi halaman `lib/features/quran/`.

## Panduan Commit & Pull Request
- Pola commit yang dipakai: `Feat: ...`, `Fix: ...`, `Revert: ...`.
- Buat commit kecil dan deskriptif (satu perubahan logis per commit).
- PR wajib berisi ringkasan, hasil test (perintah + output), dan screenshot untuk perubahan UI.

## Catatan CI/CD
- Workflow GitHub Actions dijelaskan di `CI_INSTRUCTIONS.md`. Ikuti saat menyiapkan CI di fork atau repo baru.
