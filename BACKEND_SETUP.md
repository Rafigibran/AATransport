# A&A Transport Backend — Supabase + SakuRupiah

Aplikasi booking mobil ini terhubung ke Supabase (Auth, database, RLS, Storage)
dan pembayaran SakuRupiah melalui Supabase Edge Functions. API key SakuRupiah
**tidak pernah** ditaruh di aplikasi Flutter — hanya di secrets Edge Functions.

Package name aplikasi: `com.wizardnative.aatransport`

Project yang dipakai:

- Supabase URL: `https://jbowxiolzbbacfyatvoh.supabase.co`
- Flutter memakai publishable key (aman untuk client, data dilindungi RLS).
  Konfigurasinya ada di `lib/config/supabase_config.dart` dan bisa dioverride:

```bash
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxx
```

## 1. Buat tabel database

1. Buka Supabase Dashboard → **SQL Editor**
2. Copy seluruh isi file `supabase/migrations/202610080001_init_aatransport.sql`
3. **Run**. Setelah itu jalankan juga `supabase/migrations/202610080002_admin_panel.sql`
   untuk mengaktifkan website admin panel (role admin, policies kelola data,
   log admin — lihat `admin-panel/ADMIN_PANEL_SETUP.md`). File ini membuat tabel `profiles`, `cars`, `car_photos`,
   `features`, `car_features`, `favourites`, `bookings`, `payments`,
   `reviews`, `saved_payment_methods`, lengkap dengan RLS, trigger profil
   otomatis saat user register, bucket Storage `car-images`, dan seed
   6 mobil dengan harga sewa Rupiah per hari.

Catatan: jika kamu sebelumnya sudah menjalankan skema hotel versi lama,
jalankan SQL berikut di SQL Editor sebelum menjalankan file baru, supaya
tabel lama tidak bentrok:

```sql
drop table if exists public.hotel_facilities, public.hotel_photos, public.hotels,
  public.reviews, public.payments, public.bookings, public.favourites cascade;
```

(Skip langkah ini kalau database masih kosong.)

## 2. Atur Auth

Di Supabase Dashboard → **Authentication**:

- Pastikan provider **Email** aktif.
- Untuk OTP reset password: buka **Email Templates → Reset Password** dan
  pastikan template menampilkan kode token, contoh tambahkan
  `Kode OTP kamu: {{ .Token }}` di isi email.
- (Opsional) Matikan **Confirm email** saat development supaya register
  bisa langsung login. Untuk production sebaiknya tetap aktif.

## 3. Deploy Edge Functions pembayaran

Install [Supabase CLI](https://supabase.com/docs/guides/cli), lalu dari folder proyek:

```bash
supabase link --project-ref jbowxiolzbbacfyatvoh
supabase secrets set SAKURUPIAH_API_ID=<API_ID merchant kamu> SAKURUPIAH_API_KEY=<API_KEY merchant kamu>
# Opsional: mode sandbox untuk pengujian
supabase secrets set SAKURUPIAH_BASE_URL=https://sakurupiah.id/api-sanbox
# Opsional: 1 = fee ditanggung merchant, 2 = fee ditanggung pembeli
supabase secrets set SAKURUPIAH_MERCHANT_FEE=1
supabase functions deploy create-payment
supabase functions deploy check-payment
supabase functions deploy payment-callback
supabase functions deploy payment-return
```

API ID & API KEY didapat dari dashboard merchant SakuRupiah setelah akun
terverifikasi (dokumentasi: https://sakurupiah.id/developers/api-dokumentasi).
Jangan bagikan API KEY di chat atau commit ke repository.

Fungsi pembayaran:

| Function | Dipanggil oleh | Keterangan |
| --- | --- | --- |
| `create-payment` | Aplikasi (JWT user) | Membuat invoice SakuRupiah (HMAC signature) untuk booking mobil, mengembalikan checkout URL / nomor VA / QR |
| `payment-callback` | Webhook SakuRupiah | Verifikasi `X-Callback-Signature`, mengupdate status booking menjadi confirmed/expired |
| `check-payment` | Aplikasi (JWT user) | Cek status transaksi ke SakuRupiah dan sinkronkan ke database |
| `payment-return` | Redirect setelah checkout | Halaman sederhana “kembali ke aplikasi” |

## 4. Alur fitur di aplikasi

| Fitur | Implementasi |
| --- | --- |
| Register/Login | Supabase Auth email + password, profil otomatis via trigger |
| Daftar & cari mobil | Tabel `cars` (+ foto/fitur/spesifikasi), pencarian nama/lokasi |
| Favourite | Tabel `favourites` per user |
| Booking | Tanggal ambil/kembali, penumpang/mobil, jenis layanan, pembayaran SakuRupiah |
| My Booking | Booking user dari database; tab Upcoming/Completed/Cancelled; batalkan booking |
| E-Receipt | Detail booking & pembayaran dari database |
| Review | Rating/komentar; rating mobil terupdate otomatis via trigger |

Semua harga menggunakan Rupiah per hari (`Rp350.000/hari`), pajak & biaya
layanan 10% dihitung di ringkasan booking.

## 5. Menjalankan aplikasi

```bash
flutter pub get
flutter run
```
