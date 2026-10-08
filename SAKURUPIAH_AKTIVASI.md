# Aktivasi Payment Gateway SakuRupiah — Checklist

Status kode per 2026-10-08: Edge Functions sudah diverifikasi terhadap
dokumentasi resmi SakuRupiah (https://sakurupiah.id/developers/api-dokumentasi):

- `create-payment` → POST `{base}/create.php`, header `Authorization: Bearer <API_KEY>`,
  signature HMAC-SHA256 dari `api_id + method + merchant_ref + amount`. Sesuai.
- `check-payment` → POST `{base}/status-transaction.php` (`method=status`, `trx_id`). Sesuai.
- `payment-callback` → verifikasi `X-Callback-Signature` = HMAC-SHA256(body JSON mentah, API_KEY)
  dan header `X-Callback-Event: payment_status`. Sesuai.
- URL sandbox resmi memang dieja `https://sakurupiah.id/api-sanbox/` (bukan typo).
  Production: `https://sakurupiah.id/api/` (default di kode).

Yang masih harus dilakukan agar gateway benar-benar berfungsi:

## 1. Jalankan migration terbaru di Supabase SQL Editor

- `supabase/migrations/202610080005_app_settings.sql`
  (tabel `app_settings` untuk pajak/fee dari admin panel + kolom fee di `bookings`).
- `supabase/migrations/202610080006_security_booking_integrity.sql`
  (perhitungan booking server-side, kapasitas armada, dan penguncian status pembayaran).

## 2. Isi secrets Edge Functions (JANGAN taruh di kode / GitHub)

Di Dashboard Supabase project `jbowxiolzbbacfyatvoh` → Edge Functions → Secrets,
atau via CLI:

```bash
supabase link --project-ref jbowxiolzbbacfyatvoh
supabase secrets set SAKURUPIAH_API_ID=<API ID merchant> SAKURUPIAH_API_KEY=<API KEY merchant>
```

Tanpa ini, `create-payment` membalas error
"SAKURUPIAH_API_ID / SAKURUPIAH_API_KEY belum diatur di Edge Function secrets".

## 3. Deploy 4 Edge Functions

```bash
supabase functions deploy create-payment
supabase functions deploy check-payment
supabase functions deploy payment-callback
supabase functions deploy payment-return
```

`payment-callback` dan `payment-return` sudah diatur `verify_jwt = false`
di `supabase/config.toml` karena dipanggil SakuRupiah tanpa JWT.

## 4. Dashboard merchant SakuRupiah

- Callback URL tidak wajib diatur di dashboard: kode mengirim
  `callback_url` dan `return_url` di setiap request invoice.
- JANGAN aktifkan validasi/whitelist IP untuk mode production.
  Request berasal dari IP cloud Supabase yang tidak statis; whitelist
  akan membuat semua request invoice ditolak.

## 5. Uji end-to-end

1. Buat booking di aplikasi, pilih metode pembayaran (mis. QRIS).
2. Invoice harus muncul (QR / nomor VA / checkout URL).
3. Bayar, lalu tekan "Cek Status Pembayaran" — booking menjadi confirmed.
4. Cek baris baru di tabel `payments` dan status `bookings` di Supabase.

## Keamanan

API KEY sempat terkirim lewat chat. Setelah gateway aktif, buat/regenerasi
API KEY baru di dashboard merchant SakuRupiah lalu perbarui secret
`SAKURUPIAH_API_KEY` di Supabase, supaya key yang lama tidak lagi berlaku.
API ID tidak rahasia, tapi key adalah kredensial penuh akun merchant.

## Perbaikan retry invoice (sudah diterapkan di kode)

Percobaan pembayaran baru sekarang memakai `merchant_ref` unik per attempt.
Invoice yang masih pending, belum melewati masa berlaku, dan memakai channel
yang sama tetap dipakai ulang; invoice expired atau pergantian channel akan
membuat attempt baru.
