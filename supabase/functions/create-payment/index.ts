// Creates a SakuRupiah invoice for a booking and stores the payment.
// Called from the Flutter app with the user's Supabase JWT:
//   supabase.functions.invoke('create-payment', body: { booking_id, method_code })
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders, createInvoiceSignature, firstData, jsonResponse, sakuConfig } from '../_shared/sakurupiah.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const { booking_id, method_code } = await req.json();
    if (!booking_id || !method_code) return jsonResponse({ error: 'booking_id dan method_code wajib diisi' }, 400);

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const authHeader = req.headers.get('Authorization') ?? '';

    // Verify the caller and load their booking (RLS applies).
    const userClient = createClient(supabaseUrl, anonKey, { global: { headers: { Authorization: authHeader } } });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData.user) return jsonResponse({ error: 'Tidak terautentikasi' }, 401);

    const { data: booking, error: bookingErr } = await userClient
      .from('bookings')
      .select('*, hotels(name, price_per_night)')
      .eq('id', booking_id)
      .single();
    if (bookingErr || !booking) return jsonResponse({ error: 'Booking tidak ditemukan' }, 404);
    if (booking.payment_status === 'berhasil') return jsonResponse({ error: 'Booking ini sudah dibayar' }, 400);

    const admin = createClient(supabaseUrl, serviceKey);

    // Re-use an existing pending payment/checkout if one exists.
    const { data: existing } = await admin
      .from('payments')
      .select('*')
      .eq('booking_id', booking_id)
      .eq('status', 'pending')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (existing?.checkout_url || existing?.payment_no || existing?.qr_string) {
      return jsonResponse({
        trx_id: existing.trx_id,
        merchant_ref: existing.merchant_ref,
        checkout_url: existing.checkout_url,
        payment_no: existing.payment_no,
        qr_string: existing.qr_string,
        expired_at: existing.expired_at,
        method_code: existing.method_code,
        reused: true,
      });
    }

    const { apiId, apiKey, baseUrl, merchantFee } = sakuConfig();
    if (!apiId || !apiKey) return jsonResponse({ error: 'SAKURUPIAH_API_ID / SAKURUPIAH_API_KEY belum diatur di Edge Function secrets' }, 500);

    const amount = Math.round(Number(booking.total));
    const merchantRef = `HIPO-${String(booking.id).replaceAll('-', '').slice(0, 24)}`;
    const signature = await createInvoiceSignature(apiId, method_code, merchantRef, amount, apiKey);

    const form = new URLSearchParams();
    form.set('api_id', apiId);
    form.set('method', method_code);
    form.set('name', booking.guest_name ?? '');
    form.set('email', booking.guest_email ?? '');
    form.set('phone', booking.guest_phone ?? '');
    form.set('amount', String(amount));
    form.set('merchant_fee', merchantFee);
    form.set('merchant_ref', merchantRef);
    form.set('expired', '24');
    form.append('produk[]', booking.hotels?.name ?? 'Hotel Booking');
    form.append('qty[]', String(booking.nights ?? 1));
    form.append('harga[]', String(booking.hotels?.price_per_night ?? amount));
    form.set('callback_url', `${supabaseUrl}/functions/v1/payment-callback`);
    form.set('return_url', `${supabaseUrl}/functions/v1/payment-return`);
    form.set('signature', signature);

    const res = await fetch(`${baseUrl}/create.php`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/x-www-form-urlencoded' },
      body: form.toString(),
    });
    const payload = await res.json().catch(() => null);
    if (!res.ok || !payload || String(payload.status) !== '200') {
      return jsonResponse({ error: payload?.message ?? 'Gagal membuat invoice SakuRupiah', detail: payload }, 502);
    }

    const data = firstData(payload);
    const expiredAt = data.expired ? new Date(String(data.expired).replace(' ', 'T')).toISOString() : null;

    const { error: payErr } = await admin.from('payments').insert({
      booking_id: booking.id,
      user_id: userData.user.id,
      method_code,
      trx_id: data.trx_id ?? null,
      merchant_ref: merchantRef,
      amount,
      status: 'pending',
      checkout_url: data.checkout_url ?? null,
      payment_no: data.payment_no != null ? String(data.payment_no) : null,
      qr_string: data.qr ?? null,
      expired_at: expiredAt,
    });
    if (payErr) return jsonResponse({ error: payErr.message }, 500);

    await admin.from('bookings').update({
      payment_method_code: method_code,
      payment_status: 'pending',
      merchant_ref: merchantRef,
      sakurupiah_trx_id: data.trx_id ?? null,
      checkout_url: data.checkout_url ?? null,
      payment_no: data.payment_no != null ? String(data.payment_no) : null,
      qr_string: data.qr ?? null,
      payment_expired_at: expiredAt,
    }).eq('id', booking.id);

    return jsonResponse({
      trx_id: data.trx_id ?? null,
      merchant_ref: merchantRef,
      checkout_url: data.checkout_url ?? null,
      payment_no: data.payment_no != null ? String(data.payment_no) : null,
      qr_string: data.qr ?? null,
      expired_at: expiredAt,
      method_code,
      via: data.via ?? method_code,
    });
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Server error' }, 500);
  }
});
