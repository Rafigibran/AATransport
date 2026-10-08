# Admin Panel A&A Transport — Panduan Setup

Website admin panel ada di folder `admin-panel/` (HTML/CSS/JS statis, tanpa build).
Backend tetap Supabase yang sama dengan aplikasi Flutter, jadi semua perubahan
di panel langsung terbaca di aplikasi.

## Fitur panel

- Dashboard: pendapatan, total booking, mobil aktif, pelanggan, grafik pendapatan 7 hari, mobil rating tertinggi
- Mobil: tambah/edit/hapus/nonaktifkan mobil, harga per hari, spesifikasi (kursi/transmisi/bahan bakar/bagasi), foto galeri, fitur mobil
- Booking: filter status & pembayaran, detail booking, ubah status (pending/confirmed/completed/cancelled/expired), cek status SakuRupiah
- Kalender Rental: jadwal pengambilan mobil per bulan
- Pembayaran: daftar transaksi SakuRupiah, pendapatan, cek status, ekspor CSV
- Pelanggan: daftar user aplikasi, edit profil, jadikan admin/user
- Review: moderasi ulasan pelanggan (hapus review)
- Laporan: performa pendapatan per mobil + ekspor CSV (booking, pembayaran, mobil, pelanggan)
- Log Admin: riwayat aktivitas pengelola
- Pengaturan: info koneksi Supabase & panduan hak akses

## 1. Siapkan database admin

Di Supabase Dashboard → **SQL Editor**, jalankan berurutan:

1. `supabase/migrations/202610080001_init_aatransport.sql` (kalau belum)
2. `supabase/migrations/202610080002_admin_panel.sql` (menambah role admin, policies kelola data, tabel admin_logs)

## 2. Buat akun admin pertama

1. Register akun lewat aplikasi A&A Transport (atau Supabase Dashboard → Authentication → Add user).
2. Jalankan SQL ini di SQL Editor (ganti emailnya):

```sql
update public.profiles
set role = 'admin'
where email = 'email-admin-kamu@contoh.com';
```

3. Login ke admin panel dengan email & password tersebut. Akun non-admin
   akan otomatis ditolak.

## 3. Jalankan / deploy website

Lokal (untuk mencoba):

```bash
cd admin-panel
python3 -m http.server 8000
# buka http://localhost:8000
```

Deploy statis (pilih salah satu):

- **GitHub Pages / Netlify / Vercel:** publish folder `admin-panel/` apa adanya.
- Konfigurasi Supabase ada di `admin-panel/config.js` (publishable key, aman
  untuk client karena data dilindungi RLS + role admin).

## 4. Cek status pembayaran dari panel

Tombol **Cek Bayar** memanggil Edge Function `check-payment` yang sudah
diperbarui supaya admin bisa mengecek booking siapa pun (user biasa hanya
booking miliknya). Pastikan Edge Functions sudah di-deploy ulang:

```bash
supabase functions deploy check-payment
```

## Keamanan

- Jangan pernah menaruh `service_role key` atau API key SakuRupiah di website ini.
- Panel ini hanya memakai publishable key + login admin; semua akses tulis
  dibatasi Row Level Security (`public.is_admin()`).
- Berikan role admin hanya ke pengelola tepercaya.
