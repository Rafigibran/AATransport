# Hipo - Check-in to Comfort

Aplikasi booking hotel **frontend only** menggunakan Flutter, dibuat berdasarkan referensi desain Hipo.

## Cara Menjalankan

```bash
flutter pub get
flutter run
```

Sudah diverifikasi dengan `flutter analyze`, `flutter test`, dan `flutter build web` (Flutter 3.24.3).

## Fitur UI

- Splash Screen
- Onboarding (3 halaman)
- Auth: Register, Login, Forgot Password, OTP Verification, Reset Password
- Home: Search hotel, Popular Hotel, Offer List
- Hotel Details: Facilities, Description, Photos, Location, Rating & Reviews
- Booking Flow: Booking Info, Calendar Picker, Payment Method, Add New Card, Guest Info, Review Summary, Payment Success
- My Booking: Upcoming / Completed / Cancelled, E-Receipt
- Favourites
- Add Review
- Profile & Logout dialog

> Catatan: Ini hanya frontend. Semua data masih mock/dummy di `lib/data/mock_data.dart`. Gambar hotel menggunakan network image dari Unsplash (butuh koneksi internet saat run).

## Struktur

```
lib/
  main.dart
  theme/app_theme.dart
  models/hotel.dart
  data/mock_data.dart
  widgets/
  screens/
    auth/
    home/
    booking/
    profile/
```
