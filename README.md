
# Keuanganku

Aplikasi pencatatan keuangan berbasis Flutter untuk mencatat pemasukan dan pengeluaran, melihat ringkasan saldo, serta mengelola transaksi per akun pengguna.

## Fitur

- Login dan register pengguna
- Dashboard saldo, pemasukan, dan pengeluaran
- Input transaksi pemasukan/pengeluaran
- Edit dan hapus transaksi
- Tab profil pengguna dengan informasi akun
- Tampilan nominal dengan format ribuan agar lebih mudah dibaca
- QR transaksi untuk berbagi detail transaksi

## Tech Stack

- Flutter
- Dart
- MongoDB dengan `mongo_dart`
- `intl` untuk format tanggal dan nominal

## Struktur Singkat

- `lib/main.dart` - titik masuk aplikasi
- `lib/pages/` - halaman login, register, beranda, dan profil
- `lib/services/` - akses database dan service bisnis
- `lib/models/` - model data pengguna, kategori, dan transaksi
- `lib/theme/` - tema aplikasi

## Menjalankan Project

1. Pastikan Flutter sudah terpasang.
2. Jalankan instalasi dependency:

```bash
flutter pub get
```

3. Jalankan aplikasi:

```bash
flutter run
```

## Catatan

- Aplikasi ini menggunakan MongoDB sebagai sumber data.
- Jika Anda ingin memakai database sendiri, sesuaikan konfigurasi koneksi di `lib/services/database_service.dart`.
- Locale Indonesia sudah diinisialisasi di `main.dart` agar format tanggal seperti `dd MMMM yyyy` bisa berjalan dengan benar.

## Tampilan

- Tema gelap dengan aksen hijau untuk pemasukan dan merah untuk pengeluaran.
- Nominal ditampilkan dalam format mata uang Indonesia.

## Lisensi

Proyek ini dibuat untuk kebutuhan tugas praktikum.
