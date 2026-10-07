# Hipo - Check-in to Comfort

Aplikasi booking hotel menggunakan Flutter dengan backend **Supabase** dan
pembayaran **SakuRupiah**. Semua fitur sudah berfungsi (bukan mock lagi).

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
- Home: cari hotel, Popular Hotel, Offer List (data dari Supabase)
- Hotel Details: fasilitas, deskripsi, foto, lokasi, rating & reviews dari database
- Favourite per user
- Booking Flow: pilih tanggal, tamu/kamar, tipe kamar, metode pembayaran
  SakuRupiah (QRIS, VA bank, e-wallet, Alfamart/Indomaret), info tamu,
  review summary dalam Rupiah
- Pembayaran: checkout SakuRupiah via Edge Function, nomor VA/QR,
  cek status pembayaran, webhook callback mengonfirmasi booking
- My Booking: Upcoming / Completed / Cancelled, batalkan booking, E-Receipt
- Add Review (rating hotel terupdate otomatis)
- Metode pembayaran tersimpan (channel favorit, tanpa data kartu)
- Profile: edit nama/no. HP, Logout

## Struktur

```
lib/
  main.dart
  config/supabase_config.dart
  theme/app_theme.dart
  models/hotel.dart
  services/app_services.dart
  utils/format.dart
  widgets/
  screens/
    auth/
    home/
    booking/
    profile/
supabase/
  migrations/     SQL skema + RLS + seed hotel (Rupiah)
  functions/      create-payment, payment-callback, check-payment, payment-return
```
