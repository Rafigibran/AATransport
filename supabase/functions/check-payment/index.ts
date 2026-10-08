// Checks a payment status directly with SakuRupiah and syncs it to the database.
// Called from the Flutter app and admin panel:
//   supabase.functions.invoke('check-payment', body: { booking_id })
//
// A successful payment is terminal: a stale provider response can never
// downgrade it, and a check can never resurrect a cancelled booking.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import {
  corsHeaders,
  firstData,
  jsonResponse,
  sakuConfig,
  shouldApplyPaymentStatus,
} from '../_shared/sakurupiah.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const { booking_id } = await req.json();
    if (!booking_id) return jsonResponse({ error: 'booking_id wajib diisi' }, 400);

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const userClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
    });
    const admin = createClient(supabaseUrl, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const { data: authData } = await userClient.auth.getUser();
    let isAdmin = false;
    if (authData.user) {
      const { data: profile } = await admin
        .from('profiles')
        .select('role')
        .eq('id', authData.user.id)
        .maybeSingle();
      isAdmin = profile?.role === 'admin';
    }

    // Admins may check any booking; regular users only their own (RLS).
    const bookingClient = isAdmin ? admin : userClient;
    const { data: booking, error } = await bookingClient
      .from('bookings')
      .select('id, sakurupiah_trx_id, payment_status, status, payment_expired_at')
      .eq('id', booking_id)
      .single();
    if (error || !booking) return jsonResponse({ error: 'Booking tidak ditemukan' }, 404);
    if (!booking.sakurupiah_trx_id) {
      return jsonResponse({ status: booking.payment_status, booking_status: booking.status });
    }

    const { apiId, apiKey, baseUrl } = sakuConfig();
    if (!apiId || !apiKey) {
      return jsonResponse({ error: 'SAKURUPIAH_API_ID / SAKURUPIAH_API_KEY belum diatur' }, 500);
    }

    const form = new URLSearchParams();
    form.set('api_id', apiId);
    form.set('method', 'status');
    form.set('trx_id', booking.sakurupiah_trx_id);

    const res = await fetch(`${baseUrl}/status-transaction.php`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: form.toString(),
    });
    const payload = await res.json().catch(() => null);
    const status: string | undefined = firstData(payload).status ?? payload?.data?.status;
    if (!status || !['pending', 'berhasil', 'expired'].includes(status)) {
      return jsonResponse({ error: payload?.message ?? 'Gagal cek status', detail: payload }, 502);
    }

    const applyStatus = shouldApplyPaymentStatus(booking.payment_status, status) &&
      booking.status !== 'cancelled';

    if (applyStatus) {
      const { error: paymentErr } = await admin
        .from('payments')
        .update({ status })
        .eq('trx_id', booking.sakurupiah_trx_id);
      if (paymentErr) return jsonResponse({ error: paymentErr.message }, 500);

      const bookingPatch = status === 'berhasil'
        ? { payment_status: 'berhasil', status: 'confirmed' }
        : status === 'expired'
        ? { payment_status: 'expired', status: 'expired' }
        : { payment_status: 'pending' };
      const { error: bookingErr } = await admin
        .from('bookings')
        .update(bookingPatch)
        .eq('id', booking.id);
      if (bookingErr) return jsonResponse({ error: bookingErr.message }, 500);
    }

    const effectiveStatus = applyStatus ? status : booking.payment_status;
    return jsonResponse({
      status: effectiveStatus,
      booking_status: effectiveStatus === 'berhasil'
        ? 'confirmed'
        : effectiveStatus === 'expired'
        ? 'expired'
        : booking.status,
    });
  } catch (e) {
    return jsonResponse({
      error: e instanceof Error ? e.message : 'Server error',
    }, 500);
  }
});
