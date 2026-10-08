// Creates a SakuRupiah invoice for a booking and stores the payment attempt.
// Called from the Flutter app with the user's Supabase JWT:
//   supabase.functions.invoke('create-payment', body: { booking_id, method_code })
//
// Safety rules implemented here:
// - only the booking owner (through RLS) or an admin path can create it;
// - cancelled/completed/already-paid bookings cannot receive a new invoice;
// - an existing invoice is re-used only when it is for the same channel,
//   still pending, has payment data, and has not reached its expiry;
// - every new attempt gets a new merchant_ref (SakuRupiah requires a unique
//   reference for every new transaction);
// - channel amount limits are checked before calling the provider;
// - every database write is checked, because an invoice without a synced
//   booking would leave check-payment unable to find its transaction.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import {
  corsHeaders,
  createInvoiceSignature,
  firstData,
  formatIdr,
  jsonResponse,
  sakurupiahChannels,
  sakuConfig,
} from '../_shared/sakurupiah.ts';

function newMerchantRef(bookingId: string): string {
  const compactBooking = String(bookingId).replaceAll('-', '').slice(0, 16);
  const random = crypto.randomUUID().replaceAll('-', '').slice(0, 12);
  return `AAT-${compactBooking}-${random}`;
}

function isExpired(expiredAt: string | null | undefined): boolean {
  if (!expiredAt) return false;
  const time = new Date(expiredAt).getTime();
  return Number.isFinite(time) && time <= Date.now();
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const { booking_id, method_code } = await req.json();
    if (!booking_id || !method_code) {
      return jsonResponse({ error: 'booking_id dan method_code wajib diisi' }, 400);
    }

    const channel = sakurupiahChannels[String(method_code)];
    if (!channel) {
      return jsonResponse({ error: `Channel pembayaran ${method_code} tidak dikenal atau tidak aktif di aplikasi` }, 400);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const authHeader = req.headers.get('Authorization') ?? '';

    // Verify the caller and load their booking (RLS applies).
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData.user) {
      return jsonResponse({ error: 'Tidak terautentikasi' }, 401);
    }

    const { data: booking, error: bookingErr } = await userClient
      .from('bookings')
      .select('*, cars(name, price_per_day)')
      .eq('id', booking_id)
      .single();
    if (bookingErr || !booking) {
      return jsonResponse({ error: 'Booking tidak ditemukan' }, 404);
    }
    if (booking.payment_status === 'berhasil') {
      return jsonResponse({ error: 'Booking ini sudah dibayar' }, 400);
    }
    if (!['pending_payment', 'confirmed'].includes(String(booking.status)) ||
        !['pending', 'expired', 'failed'].includes(String(booking.payment_status))) {
      return jsonResponse({
        error: `Booking berstatus ${booking.status}/${booking.payment_status} tidak dapat dibuatkan pembayaran baru`,
      }, 400);
    }

    const amount = Math.round(Number(booking.total));
    if (!Number.isFinite(amount) || amount <= 0) {
      return jsonResponse({ error: 'Total booking tidak valid' }, 400);
    }
    if (amount < channel.min || amount > channel.max) {
      return jsonResponse({
        error: `Channel ${channel.name} hanya mendukung pembayaran ${formatIdr(channel.min)} - ${formatIdr(channel.max)}. Pilih channel lain.`,
      }, 400);
    }

    const admin = createClient(supabaseUrl, serviceKey);

    // Re-use an existing attempt only when it is genuinely the same live
    // invoice. Expired invoices and channel changes always start a new
    // attempt with a new merchant reference.
    const { data: existing, error: existingErr } = await admin
      .from('payments')
      .select('*')
      .eq('booking_id', booking_id)
      .eq('method_code', method_code)
      .eq('status', 'pending')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (existingErr) return jsonResponse({ error: existingErr.message }, 500);

    if (
      existing &&
      (existing.checkout_url || existing.payment_no || existing.qr_string) &&
      !isExpired(existing.expired_at)
    ) {
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
    if (!apiId || !apiKey) {
      return jsonResponse({
        error: 'SAKURUPIAH_API_ID / SAKURUPIAH_API_KEY belum diatur di Edge Function secrets',
      }, 500);
    }

    const merchantRef = newMerchantRef(String(booking.id));
    const signature = await createInvoiceSignature(
      apiId,
      String(method_code),
      merchantRef,
      amount,
      apiKey,
    );

    const form = new URLSearchParams();
    form.set('api_id', apiId);
    form.set('method', String(method_code));
    form.set('name', booking.customer_name ?? '');
    form.set('email', booking.customer_email ?? '');
    form.set('phone', booking.customer_phone ?? '');
    form.set('amount', String(amount));
    form.set('merchant_fee', merchantFee);
    form.set('merchant_ref', merchantRef);
    form.set('expired', '24');

    // Keep invoice line items arithmetically consistent with the invoice
    // amount. The rental line covers days x units; snapshot tax/fee columns
    // (migration 005) become separate lines when an admin has enabled them.
    const rentalQty = Math.max(1, Number(booking.days ?? 1)) *
      Math.max(1, Number(booking.units ?? 1));
    const dailyPrice = Number(booking.cars?.price_per_day ?? 0);
    const rentalLinePrice = dailyPrice > 0
      ? dailyPrice
      : Math.max(0, amount - Number(booking.tax ?? 0) - Number(booking.fee ?? 0));
    form.append('produk[]', booking.cars?.name ?? 'Sewa Mobil A&A Transport');
    form.append('qty[]', String(rentalQty));
    form.append('harga[]', String(rentalLinePrice));
    if (Number(booking.tax ?? 0) > 0) {
      form.append('produk[]', 'Pajak A&A Transport');
      form.append('qty[]', '1');
      form.append('harga[]', String(Math.round(Number(booking.tax))));
    }
    if (Number(booking.fee ?? 0) > 0) {
      form.append('produk[]', 'Biaya layanan A&A Transport');
      form.append('qty[]', '1');
      form.append('harga[]', String(Math.round(Number(booking.fee))));
    }

    form.set('callback_url', `${supabaseUrl}/functions/v1/payment-callback`);
    form.set('return_url', `${supabaseUrl}/functions/v1/payment-return`);
    form.set('signature', signature);

    const res = await fetch(`${baseUrl}/create.php`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: form.toString(),
    });
    const payload = await res.json().catch(() => null);
    if (!res.ok || !payload || String(payload.status) !== '200') {
      return jsonResponse({
        error: payload?.message ?? 'Gagal membuat invoice SakuRupiah',
        detail: payload,
      }, 502);
    }

    const data = firstData(payload);
    const expiredAt = data.expired
      ? new Date(String(data.expired).replace(' ', 'T')).toISOString()
      : null;

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

    const { error: bookingUpdateErr } = await admin.from('bookings').update({
      payment_method_code: method_code,
      payment_status: 'pending',
      status: booking.status === 'confirmed' ? 'confirmed' : 'pending_payment',
      merchant_ref: merchantRef,
      sakurupiah_trx_id: data.trx_id ?? null,
      checkout_url: data.checkout_url ?? null,
      payment_no: data.payment_no != null ? String(data.payment_no) : null,
      qr_string: data.qr ?? null,
      payment_expired_at: expiredAt,
    }).eq('id', booking.id);
    if (bookingUpdateErr) {
      return jsonResponse({
        error: `Invoice dibuat tetapi booking gagal disinkronkan: ${bookingUpdateErr.message}`,
      }, 500);
    }

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
    return jsonResponse({
      error: e instanceof Error ? e.message : 'Server error',
    }, 500);
  }
});
