# A&A Transport — Panduan Logo (ringkas)

Logo terpilih: **Berbagi**. Dokumen ini untuk pemakaian sehari-hari. Untuk skrin pakai file RGB di `svg/` dan `png/`; untuk cetak vektor pakai SVG yang sama dan sebutkan kode CMYK/Pantone di bawah ke percetakan.

## 1. Logo

- **Ide**: Dua A dihubungkan satu palang/rute yang sama: A&A, dua layanan (dengan sopir dan lepas kunci), satu armada.
- **Versi resmi**:
  - Utama (horizontal): `svg/aatransport-lockup-horizontal-color.svg`
  - Bertumpuk: `svg/aatransport-lockup-stacked-color.svg`
  - Simbol saja: `svg/aatransport-symbol-color.svg` (untuk ikon aplikasi, avatar, favicon besar)
  - Wordmark saja: `svg/aatransport-wordmark-color.svg`
  - Satu warna dan reversed ada di nama file yang sama dengan akhiran `-black`, `-white`, `-mono-3e7bfa`, `-ink`. Untuk latar gelap utamakan `aatransport-symbol-white-thinned.svg` (sudah ditipiskan 3% agar tidak terlihat lebih gemuk dari versi hitam).
- **Ukuran kecil**: di bawah 32 px jangan pakai simbol biasa — pakai potongan ukuran kecil `svg/aatransport-symbol-small.svg` atau file favicon/app-icon hasil ekspor (counter segitiganya sudah dibuka dan kakinya ditipiskan untuk ukuran kecil).

## 2. Ruang aman (clear space)

Jaga zona kosong **selebar tinggi palang penghubung simbol** di semua sisi logo (pada simbol, palang itu setebal 24 dari 160 tinggi simbol, kira-kira 15% tinggi simbol). Zona ini diskala mengikuti logo, jangan pakai jarak tetap (mis. selalu 20 px). Tidak boleh ada teks, tepi halaman, logo lain, atau elemen ramai di zona ini.

## 3. Ukuran minimum

| Versi | Layar | Cetak |
|---|---|---|
| Lockup horizontal | lebar 120 px (di bawah itu pakai simbol saja) | lebar 32 mm |
| Lockup bertumpuk | lebar 96 px | lebar 25 mm |
| Simbol biasa | 32 px (di bawah itu pakai versi kecil/favicon) | 8 mm |
| Simbol kecil / favicon | 16 px | 5 mm |

Tagline "TRAVEL IN COMFORT" hanya untuk lockup besar (lebar horizontal 240 px ke atas). Di bawah itu pakai lockup tanpa tagline atau simbol saja — file master lockup memang memuat tagline, jadi untuk pemakaian kecil pakai simbol.

## 4. Warna

| Nama | HEX | RGB | CMYK | Pantone (perkiraan) | Pakai untuk |
|---|---|---|---|---|---|
| A&A Blue | #3E7BFA | 62 123 250 | 75 51 0 2 | 2727 C* | Simbol, "A&A" pada wordmark, ubin ikon aplikasi, aksen utama |
| Deep Blue | #2F5FE0 | 47 95 224 | 79 58 0 12 | 2145 C* | Versi satu warna saat butuh kontras lebih kuat, tautan/aksen gelap |
| Ink | #1B1D28 | 27 29 40 | 33 27 0 84 | Black 7 C* | Kata "Transport", teks, versi tinta satu warna |
| Comfort Grey | #8A8F9E | 138 143 158 | — | — | Hanya tagline dan teks pendukung, jangan untuk simbol |
| Cloud | #F6F8FF | 246 248 255 | — | — | Latar terang aplikasi bila butuh latar selain putih |

*Pantone adalah perkiraan dari nilai HEX — cocokkan dengan buku Pantone fisik sebelum cetak premium/spot.

Kontras terukur: A&A Blue di atas putih 3,88 : 1 dan putih di atas A&A Blue 3,88 : 1 (cukup untuk logo/teks besar 3 : 1); Deep Blue di atas putih 5,48 : 1; Ink di atas putih 16,76 : 1.

**Pasangan logo/latar yang disetujui**: warna penuh di atas putih atau Cloud; putih (thinned) di atas A&A Blue, Deep Blue, atau Ink; hitam di atas putih; mono A&A Blue di atas putih. Di atas foto, pakai versi putih di area foto yang tenang dan gelap merata, atau letakkan lockup putih di ubin A&A Blue — jangan letakkan logo warna penuh di atas foto ramai.

## 5. Tipografi

- Wordmark di file master sudah **diouline** (bukan teks hidup) dari Liberation Sans Bold, dengan "A&A" biru dan "Transport" tinta meniru splash screen aplikasi; tagline Liberation Sans Regular dengan spasi huruf lebar. Kamu tidak perlu font untuk menampilkan logo.
- Untuk teks merek sehari-hari (judul dan isi di aplikasi/dokumen): pakai keluarga sans yang sama dengan aplikasi saat ini. Bila butuh font yang bisa ditanam dan lisensinya jelas, Liberation Sans (SIL Open Font License 1.1) aman untuk penggunaan komersial termasuk logo — simpan berkas lisensinya bersama font. Maksimal dua keluarga huruf di seluruh identitas.
- Jangan mengetik ulang wordmark dengan font lain dan menyebutnya logo. Pakai file master.

## 6. Jangan lakukan ini

Jangan regangkan atau gepengkan; jangan ganti warna di luar palet; jangan putar atau miringkan; jangan tambah bayangan, outline, gradien, atau efek; jangan susun ulang atau ubah jarak simbol dan wordmark di lockup; jangan letakkan di latar ramai tanpa ubin/wadah; jangan gambar ulang, jangan pakai emoji atau gambar mobil sebagai pengganti simbol; jangan pakai simbol biasa di bawah 32 px (pakai versi kecil).

## 7. File mana untuk apa

- Ikon aplikasi Android/iOS: `web-icons/icon-512.png` (atau `svg/aatransport-symbol-color-app-icon.svg` — simbol putih di ubin biru sudut membulat) lalu buat ukuran platform dari file 1024 di `png/`.
- Favicon situs/admin panel: seluruh isi `web-icons/` (`favicon.ico`, `favicon.svg`, PNG 16/32/48, apple-touch-icon, `site.webmanifest`, `head-snippet.html`).
- Header situs, dokumen, dan presentasi: lockup horizontal SVG (atau PNG 1024 transparan bila aplikasi tidak mendukung SVG).
- Stiker pintu mobil / signage: lockup horizontal atau bertumpuk versi putih di atas potongan warna A&A Blue, atau hitam satu warna untuk potong vinyl. Minta percetakan memakai nilai CMYK di atas.
- Media sosial: `aatransport-symbol-color-square.svg` (simbol di kanvas persegi) atau app-icon.

## 8. Catatan serah terima

- Master vektor: folder `svg/`. Tidak ada teks hidup, raster, filter, atau gradien di file master. Lockup memang punya banyak titik jangkar karena hurufnya hasil outline font — itu normal untuk wordmark diouline dan bukan cacat.
- Tes yang dijalankan: audit SVG (simbol 100/100), lembar pratinjau ukuran 64/32/16 px gaya `preview_sheet` (tersimpan `preview-final.html`), render PNG 512/1024 dan pemeriksaan visual semua lockup, ekspor favicon lengkap. Slide PNG board presentasi tidak bisa dibuat di mesin ini (tidak ada peramban Chromium untuk tangkapan HTML) — board tersedia sebagai HTML yang bisa dibuka di peramban: `board/aatransport-presentation-board.html`.
- Masih harus dilakukan pemilik merek sebelum peluncuran resmi: cek merek dagang (DJKI/database merek) dan pencarian gambar terbalik untuk simbol AA berpalang ini, serta cocokkan Pantone dengan contoh fisik bila mencetak spot. Hasil desain ini tidak menjamin kebebasan merek.
- Konsep yang tidak dipilih (Rute A, Ampersand Rute) tersimpan di folder konsep proyek dan tetap milik proyek ini untuk arsip; jangan campur pemakaiannya dengan Berbagi.

Sumber / cara membangun ulang: `source/build_kit.py` (geometri simbol digambar sebagai path; wordmark diouline dari Liberation Sans dengan fontTools). Brief: `../brief.md`.
