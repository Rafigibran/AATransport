// Checks a payment status directly with SakuRupiah and syncs it to the database.
// Called from the Flutter app: supabase.functions.invoke('check-payment', body: { booking_id })
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders, firstData, jsonResponse, sakuConfig } from '../_shared/sakurupiah.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const { booking_id } = await req.json();
    if (!booking_id) return jsonResponse({ error: 'booking_id wajib diisi' }, 400);

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const userClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
    });
    const { data: booking, error } = await userClient
      .from('bookings')
      .select('id, sakurupiah_trx_id, payment_status, status')
      .eq('id', booking_id)
      .single();
    if (error || !booking) return jsonResponse({ error: 'Booking tidak ditemukan' }, 404);
    if (!booking.sakurupiah_trx_id) return jsonResponse({ status: booking.payment_status, booking_status: booking.status });

    const { apiId, apiKey, baseUrl } = sakuConfig();
    if (!apiId || !apiKey) return jsonResponse({ error: 'SAKURUPIAH_API_ID / SAKURUPIAH_API_KEY belum diatur' }, 500);

    const form = new URLSearchParams();
    form.set('api_id', apiId);
    form.set('method', 'status');
    form.set('trx_id', booking.sakurupiah_trx_id);

    const res = await fetch(`${baseUrl}/status-transaction.php`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/x-www-form-urlencoded' },
      body: form.toString(),
    });
    const payload = await res.json().catch(() => null);
    const status: string | undefined = firstData(payload).status ?? payload?.data?.status;
    if (!status) return jsonResponse({ error: payload?.message ?? 'Gagal cek status', detail: payload }, 502);

    const admin = createClient(supabaseUrl, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    await admin.from('payments').update({ status }).eq('trx_id', booking.sakurupiah_trx_id);
    if (status === 'berhasil') {
      await admin.from('bookings').update({ payment_status: 'berhasil', status: 'confirmed' }).eq('id', booking.id);
    } else if (status === 'expired') {
      await admin.from('bookings').update({ payment_status: 'expired', status: 'expired' }).eq('id', booking.id);
    }

    return jsonResponse({
      status,
      booking_status: status === 'berhasil' ? 'confirmed' : status === 'expired' ? 'expired' : booking.status,
    });
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Server error' }, 500);
  }
});
