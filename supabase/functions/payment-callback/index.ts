// SakuRupiah callback (webhook). Configure `verify_jwt = false` for this function
// in supabase/config.toml — authenticity is verified with the callback HMAC signature.
//
// State rules:
// - a successful payment is terminal and can never be downgraded by a late
//   pending/expired callback;
// - a success callback can never resurrect a cancelled booking;
// - every payment/booking write is checked before reporting success.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import {
  hmacSha256Hex,
  jsonResponse,
  safeEqual,
  sakuConfig,
  shouldApplyPaymentStatus,
} from '../_shared/sakurupiah.ts';

Deno.serve(async (req) => {
  try {
    const raw = await req.text();
    const { apiKey } = sakuConfig();
    if (!apiKey) {
      return jsonResponse({ success: false, message: 'API key belum diatur' }, 500);
    }

    const callbackSignature = req.headers.get('x-callback-signature') ?? '';
    const expected = await hmacSha256Hex(apiKey, raw);
    if (!safeEqual(callbackSignature, expected)) {
      return jsonResponse({ success: false, message: 'Invalid signature' }, 401);
    }
    if (req.headers.get('x-callback-event') !== 'payment_status') {
      return jsonResponse({ success: false, message: 'Unrecognized callback event' }, 400);
    }

    const data = JSON.parse(raw);
    const trxId: string | undefined = data.trx_id;
    const merchantRef: string | undefined = data.merchant_ref;
    const status: string = data.status; // pending | berhasil | expired
    if (!['pending', 'berhasil', 'expired'].includes(status)) {
      return jsonResponse({ success: false, message: 'Status callback tidak dikenal' }, 400);
    }
    if (!merchantRef && !trxId) {
      return jsonResponse({ success: false, message: 'merchant_ref/trx_id kosong' }, 400);
    }

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    let selectQuery = admin
      .from('payments')
      .select('id, booking_id, status')
      .limit(1);
    selectQuery = merchantRef
      ? selectQuery.eq('merchant_ref', merchantRef)
      : selectQuery.eq('trx_id', trxId!);
    const { data: existingPayments, error: findErr } = await selectQuery;
    if (findErr) return jsonResponse({ success: false, message: findErr.message }, 500);
    const existingPayment = existingPayments?.[0];
    if (!existingPayment) {
      return jsonResponse({ success: false, message: 'Payment tidak ditemukan' }, 404);
    }

    const { data: booking, error: bookingFindErr } = await admin
      .from('bookings')
      .select('id, status, payment_status')
      .eq('id', existingPayment.booking_id)
      .single();
    if (bookingFindErr || !booking) {
      return jsonResponse({ success: false, message: 'Booking tidak ditemukan' }, 404);
    }

    const applyPaymentUpdate = shouldApplyPaymentStatus(existingPayment.status, status);
    const applyBookingUpdate = shouldApplyPaymentStatus(booking.payment_status, status) &&
      booking.status !== 'cancelled';

    if (applyPaymentUpdate) {
      const { error: paymentErr } = await admin
        .from('payments')
        .update({ status, callback_payload: data })
        .eq('id', existingPayment.id);
      if (paymentErr) {
        return jsonResponse({ success: false, message: paymentErr.message }, 500);
      }
    }

    if (applyBookingUpdate) {
      const bookingPatch = status === 'berhasil'
        ? { payment_status: 'berhasil', status: 'confirmed' }
        : status === 'expired'
        ? { payment_status: 'expired', status: 'expired' }
        : { payment_status: 'pending' };
      const { error: bookingErr } = await admin
        .from('bookings')
        .update(bookingPatch)
        .eq('id', booking.id);
      if (bookingErr) {
        return jsonResponse({ success: false, message: bookingErr.message }, 500);
      }
    }

    return jsonResponse({
      success: true,
      message: applyBookingUpdate
        ? `Payment status ${status}`
        : `Callback ${status} diterima tetapi status terminal/lokal dipertahankan`,
    });
  } catch (e) {
    return jsonResponse({
      success: false,
      message: e instanceof Error ? e.message : 'Server error',
    }, 500);
  }
});
