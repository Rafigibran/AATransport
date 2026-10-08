# Admin Panel A&A Transport — Panduan Setup

Website admin panel ada di folder `admin-panel/` dan dibuat dengan **ReactJS (Vite + React + @supabase/supabase-js)**.
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
npm install
npm run dev
# buka http://localhost:5173
```

Build production:

```bash
npm run build
# hasil static production ada di folder admin-panel/dist/
```

Deploy statis (pilih salah satu):

- **GitHub Pages / Netlify / Vercel:** deploy hasil build dari folder `dist/`
  (atau atur root/build command: `npm run build`, publish directory: `dist`).
- Konfigurasi Supabase ada di `admin-panel/src/supabaseClient.js` dan bisa
  dioverride dengan env `VITE_SUPABASE_URL` / `VITE_SUPABASE_PUBLISHABLE_KEY`
  (publishable key aman untuk client karena data dilindungi RLS + role admin).

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

## Troubleshooting: login ditolak padahal sudah menjalankan SQL

Penyebab paling umum: SQL `update profiles` dijalankan **sebelum** akun
terdaftar (0 baris berubah), baris profil belum ada, atau huruf besar/kecil
email berbeda. Jalankan file `supabase/migrations/202610080003_fix_admin.sql`
di SQL Editor: file itu menampilkan daftar profil, membuat baris profil dari
`auth.users` bila belum ada, dan mengatur `role = 'admin'` tanpa peka huruf.
Pastikan juga project Supabase yang dibuka benar: `jbowxiolzbbacfyatvoh`.
Setelah itu logout/login ulang di admin panel.
