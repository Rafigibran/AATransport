// Simple return page shown by SakuRupiah after checkout. verify_jwt = false.
import { corsHeaders } from '../_shared/sakurupiah.ts';

Deno.serve((req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  const html = `<!doctype html>
<html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>A&A Transport - Pembayaran Diproses</title></head>
<body style="font-family:system-ui;text-align:center;padding:48px 24px">
<h2>Pembayaran sedang diproses</h2>
<p>Silakan kembali ke aplikasi A&A Transport dan tekan tombol <b>Cek Status Pembayaran</b> di halaman booking kamu.</p>
</body></html>`;
  return new Response(html, { headers: { 'Content-Type': 'text/html; charset=utf-8' } });
});
