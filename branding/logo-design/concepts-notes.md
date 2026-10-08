# A&A Transport — Catatan checkpoint konsep logo
Tanggal: 2026-10-08. Brief lengkap: `brief.md`. Ini ronde konsep hitam (greyscale) sesuai workflow skill logo-design: bentuk dinilai dulu, warna setelah arah dipilih.

## File konsep (simbol, tanpa teks hidup)
- A Rute A: `concepts/concept-a-rute-a.svg` — audit 100/100, tanpa isu.
- B Berbagi: `concepts/concept-b-berbagi.svg` — audit 100/100 setelah penyetelan sudut kaki dalam ke 75 derajat (dari 74,6).
- C Ampersand Rute: `concepts/concept-c-ampersand.svg` — audit 99/100; satu-satunya catatan INFO adalah stroke monoline yang memang disengaja di tahap konsep dan harus diexpand menjadi outline fill di file master final (atau didokumentasikan sebagai varian stroke).
- Lockup (`concepts/concept-*-lockup.svg`) masih memakai teks hidup Arial/Helvetica hanya untuk eksplorasi checkpoint. Wordmark final wajib diouline/digambar ulang sebelum disebut master — sudah ditandai di `<title>` tiap file lockup.

## Hasil tes (preview_sheet + concept_sheet + render PNG 512, dilihat langsung)
- Skala: A terbaca sebagai A di 16 px (detail rute menyatu, huruf tetap utuh — perilaku yang benar untuk detail kecil). B di 16 px menjadi gumpalan AA yang padat; jika B dipilih perlu versi ukuran-kecil yang disederhanakan (mis. satu A atau AA tanpa palang penghubung). C tetap terbaca sebagai & di 16 px berkat stroke tebal, lubang atas mulai menutup — perlu dibuka sedikit jika dipilih.
- Satu warna: ketiganya lolos hitam di atas putih (memang dibangun hitam dulu). Versi reversed belum dibuat — masuk kit setelah arah dipilih, termasuk penipisan 2-5% untuk irradiation bila perlu.
- Huruf: A terbaca A pada pandangan pertama; B terbaca AA; C terbaca &.
- Shelf/library: kategori travel-transport di library referensi hanya 4 logo (Airbnb, Google Maps pin, Maps.me, GetYourGuide). Tidak ada yang memakai monogram A rute, AA berpalang sama, atau & monoline — ketiganya jelas berbeda dari pin peta dan siluet mobil yang dihindari. Pengecekan merek dagang resmi (DJKI/database merek + reverse image search) tetap harus dilakukan user sebelum peluncuran; tidak ada jaminan clearance dari proses ini.
- Iterasi yang dilakukan: A dicoba 6 versi (slice rute putih gugur karena kaki kiri menjadi serpihan melayang; rute menonjol besar gugur karena terbaca tanda centang; versi final memakai palang yang menembus kaki kanan dan keluar sebagai belah ketupat rute 45 derajat). B dicoba 4 versi (dua A tinggi-sempit gugur; kaki ditipiskan dan palang diturunkan agar counter segitiga membesar). C dicoba 2 versi (diskalakan 1,22x agar mengisi kanvas; diagonal disetel ke 60 derajat).

## Risiko jujur per konsep
- A: tonjolan belah ketupat di kaki kanan bisa terbaca sebagai tanda centang/tag pada pandangan sekilas pertama. Jika dipilih, putaran final akan memperjelasnya sebagai rute berangkat (atau melunakkannya) lalu dites lagi.
- B: paling literal (hanya inisial) dan paling lebar untuk ikon; di ukuran sangat kecil paling lemah.
- C: paling elegan dan ramah (paling "nyaman"), tapi sendirian tidak mengatakan "A" atau transport — butuh lockup nama di awal sampai publik belajar. Stroke harus diouline.

## Rekomendasi
A — Rute A. Alasan: satu-satunya yang tetap utuh di 16 px sebagai ikon aplikasi, siluet segitiga kokoh = terpercaya, dan detail rute 45 derajat adalah satu detail ownable tanpa menggambar mobil. C adalah pilihan kedua bila ingin rasa lebih hangat/premium.

## Langkah berikutnya (hanya setelah user memilih)
Kit lengkap untuk arah terpilih: refinement akhir + versi ukuran kecil, warna selaras aplikasi (#3E7BFA / #2F5FE0 / #1B1D28, diuji kontras & satu warna), lockup horizontal + bertumpuk + wordmark diouline, varian hitam/putih/mono, favicon + app icon + web manifest, presentation board dengan mockup relevan (ikon aplikasi, stiker pintu mobil, kartu, splash screen), dan panduan pemakaian satu halaman.
