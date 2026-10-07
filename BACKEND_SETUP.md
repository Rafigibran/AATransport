# Hipo Backend — Supabase + SakuRupiah

Aplikasi ini sudah terhubung ke Supabase (Auth, database, RLS, Storage) dan
pembayaran SakuRupiah melalui Supabase Edge Functions. API key SakuRupiah
**tidak pernah** ditaruh di aplikasi Flutter — hanya di secrets Edge Functions.

Project yang dipakai:

- Supabase URL: `https://jbowxiolzbbacfyatvoh.supabase.co`
- Flutter memakai publishable key (aman untuk client, data dilindungi RLS).
  Konfigurasinya ada di `lib/config/supabase_config.dart` dan bisa dioverride:

```bash
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxx
```

## 1. Buat tabel database

1. Buka Supabase Dashboard → **SQL Editor**
2. Copy seluruh isi file `supabase/migrations/202610080001_init_hipo.sql`
3. **Run**. File ini membuat tabel `profiles`, `hotels`, `hotel_photos`,
   `facilities`, `hotel_facilities`, `favourites`, `bookings`, `payments`,
   `reviews`, `saved_payment_methods`, lengkap dengan RLS, trigger profil
   otomatis saat user register, bucket Storage `hotel-images`, dan seed
   6 hotel dengan harga Rupiah.

## 2. Atur Auth

Di Supabase Dashboard → **Authentication**:

- Pastikan provider **Email** aktif.
- Untuk OTP reset password: buka **Email Templates → Reset Password** dan
  pastikan template menampilkan kode token, contoh tambahkan
  `Kode OTP kamu: {{ .Token }}` di isi email. Alur di aplikasi:
  Forgot Password → OTP → password baru.
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
terverifikasi (lihat dokumentasi: https://sakurupiah.id/developers/api-dokumentasi).
Jangan bagikan API KEY di chat atau commit ke repository.

Fungsi pembayaran:

| Function | Dipanggil oleh | Keterangan |
| --- | --- | --- |
| `create-payment` | Aplikasi (JWT user) | Membuat invoice SakuRupiah (HMAC signature), menyimpan pembayaran, mengembalikan checkout URL / nomor VA / QR |
| `payment-callback` | Webhook SakuRupiah | Verifikasi `X-Callback-Signature` (HMAC-SHA256 dari raw body dengan API key), mengupdate status booking menjadi confirmed/expired |
| `check-payment` | Aplikasi (JWT user) | Cek status transaksi ke SakuRupiah dan sinkronkan ke database |
| `payment-return` | Redirect setelah checkout | Halaman sederhana “kembali ke aplikasi” |

Di dashboard SakuRupiah, callback URL juga bisa diatur ke:

```
https://jbowxiolzbbacfyatvoh.supabase.co/functions/v1/payment-callback
```

(URL yang sama juga dikirim otomatis pada setiap pembuatan invoice.)

## 4. Alur fitur di aplikasi

| Fitur | Implementasi |
| --- | --- |
| Register/Login | Supabase Auth email + password, profil otomatis dibuat via trigger |
| Forgot password | Reset email + verifikasi OTP (`OtpType.recovery`) lalu update password |
| Daftar & cari hotel | Tabel `hotels` (+ foto/fasilitas), pencarian nama/lokasi |
| Favourite | Tabel `favourites` per user |
| Booking | Tanggal (date range picker), tamu/kamar, tipe kamar, metode pembayaran SakuRupiah |
| Pembayaran | Edge Function `create-payment` → buka checkout URL, atau bayar via nomor VA/QR yang ditampilkan |
| My Booking | Booking user dari database; tab Upcoming/Completed/Cancelled; batalkan booking; cek status pembayaran |
| E-Receipt | Detail booking & pembayaran dari database |
| Review | User menulis rating/komentar; rating hotel terupdate otomatis via trigger |
| Metode pembayaran tersimpan | Channel SakuRupiah favorit user (tanpa menyimpan data kartu apa pun) |
| Profil | Nama/no. HP bisa diedit, logout mengakhiri session Supabase |

Semua harga menggunakan Rupiah (`formatRupiah`, contoh `Rp1.500.000/malam`),
pajak & biaya layanan 10% dihitung di ringkasan booking.

## 5. Menjalankan aplikasi

```bash
flutter pub get
flutter run
```
