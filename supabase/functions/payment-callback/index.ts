// SakuRupiah callback (webhook). Configure `verify_jwt = false` for this function
// in supabase/config.toml — authenticity is verified with the callback HMAC signature.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { hmacSha256Hex, jsonResponse, sakuConfig } from '../_shared/sakurupiah.ts';

Deno.serve(async (req) => {
  try {
    const raw = await req.text();
    const { apiKey } = sakuConfig();
    if (!apiKey) return jsonResponse({ success: false, message: 'API key belum diatur' }, 500);

    const callbackSignature = req.headers.get('x-callback-signature') ?? '';
    const expected = await hmacSha256Hex(apiKey, raw);
    if (callbackSignature !== expected) {
      return jsonResponse({ success: false, message: 'Invalid signature' }, 401);
    }
    if (req.headers.get('x-callback-event') !== 'payment_status') {
      return jsonResponse({ success: false, message: 'Unrecognized callback event' }, 400);
    }

    const data = JSON.parse(raw);
    const trxId: string | undefined = data.trx_id;
    const merchantRef: string | undefined = data.merchant_ref;
    const status: string = data.status; // pending | berhasil | expired
    if (!merchantRef && !trxId) return jsonResponse({ success: false, message: 'merchant_ref/trx_id kosong' }, 400);

    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

    let query = admin.from('payments').update({ status, callback_payload: data }).select('id, booking_id').limit(1);
    query = merchantRef ? query.eq('merchant_ref', merchantRef) : query.eq('trx_id', trxId!);
    const { data: payments, error } = await query;
    if (error) return jsonResponse({ success: false, message: error.message }, 500);
    const payment = payments?.[0];
    if (!payment) return jsonResponse({ success: false, message: 'Payment tidak ditemukan' }, 404);

    if (status === 'berhasil') {
      await admin.from('bookings').update({ payment_status: 'berhasil', status: 'confirmed' }).eq('id', payment.booking_id);
    } else if (status === 'expired') {
      await admin.from('bookings').update({ payment_status: 'expired', status: 'expired' }).eq('id', payment.booking_id);
    } else {
      await admin.from('bookings').update({ payment_status: 'pending' }).eq('id', payment.booking_id);
    }

    return jsonResponse({ success: true, message: `Payment status ${status}` });
  } catch (e) {
    return jsonResponse({ success: false, message: e instanceof Error ? e.message : 'Server error' }, 500);
  }
});
