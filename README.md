# A&A Transport — Aplikasi Booking Mobil

Aplikasi booking/sewa mobil menggunakan Flutter dengan backend **Supabase** dan
pembayaran **SakuRupiah**. Package name: `com.wizardnative.aatransport`.

## Cara Menjalankan

Siapkan dulu backend sesuai panduan di [BACKEND_SETUP.md](BACKEND_SETUP.md)
(jalankan SQL migration, atur Auth, deploy Edge Functions pembayaran), lalu:

```bash
flutter pub get
flutter run
```

## Fitur

- Splash Screen & Onboarding
- Auth Supabase: Register, Login, Forgot Password (OTP email), Reset Password
- Home: cari mobil, Mobil Populer, Pilihan Mobil (data dari Supabase)
- Detail Mobil: spesifikasi (kursi, transmisi, bahan bakar, bagasi), fitur,
  foto, lokasi penjemputan, rating & reviews dari database
- Mobil Favorit per user
- Booking Flow: pilih tanggal ambil/kembali, jumlah penumpang & mobil,
  jenis layanan (Dengan Sopir, Lepas Kunci, Antar/Jemput Bandara, Sewa Harian + BBM),
  info penyewa, review summary dalam Rupiah
- Pembayaran: checkout SakuRupiah via Edge Function, nomor VA/QR,
  cek status pembayaran, webhook callback mengonfirmasi booking
- My Booking: Upcoming / Completed / Cancelled, batalkan booking, E-Receipt
- Add Review (rating mobil terupdate otomatis)
- Metode pembayaran tersimpan (channel favorit, tanpa data kartu)
- Profile: edit nama/no. HP, Logout

## Struktur

```
lib/
  main.dart
  config/supabase_config.dart
  theme/app_theme.dart
  models/car.dart
  services/app_services.dart
  utils/format.dart
  widgets/
  screens/
    auth/
    home/
    booking/
    profile/
supabase/
  migrations/     SQL skema + RLS + seed mobil (Rupiah/hari)
  functions/      create-payment, payment-callback, check-payment, payment-return
```
