// Shared helpers for SakuRupiah integration.
// Secrets are read from Supabase Edge Function environment variables:
//   supabase secrets set SAKURUPIAH_API_ID=... SAKURUPIAH_API_KEY=...

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
};

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

export function sakuConfig() {
  const apiId = Deno.env.get('SAKURUPIAH_API_ID') ?? '';
  const apiKey = Deno.env.get('SAKURUPIAH_API_KEY') ?? '';
  // Production by default. For sandbox set SAKURUPIAH_BASE_URL=https://sakurupiah.id/api-sanbox
  const baseUrl = (Deno.env.get('SAKURUPIAH_BASE_URL') ?? 'https://sakurupiah.id/api').replace(/\/$/, '');
  const merchantFee = Deno.env.get('SAKURUPIAH_MERCHANT_FEE') ?? '1'; // 1 = merchant bears fee, 2 = customer
  return { apiId, apiKey, baseUrl, merchantFee };
}

export async function hmacSha256Hex(key: string, message: string): Promise<string> {
  const enc = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey('raw', enc.encode(key), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', cryptoKey, enc.encode(message));
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

export async function createInvoiceSignature(apiId: string, method: string, merchantRef: string, amount: number, apiKey: string): Promise<string> {
  return await hmacSha256Hex(apiKey, `${apiId}${method}${merchantRef}${amount}`);
}

/** SakuRupiah channels known to the A&A Transport app and their amount bounds (IDR). */
export const sakurupiahChannels: Record<string, { name: string; min: number; max: number }> = {
  QRISMU: { name: 'QRISMU', min: 500, max: 5_000_000 },
  QRIS2: { name: 'QRIS2', min: 100, max: 10_000_000 },
  QRIS: { name: 'QRIS', min: 500, max: 2_000_000 },
  QRISC: { name: 'QRIS (semua e-wallet)', min: 200, max: 20_000_000 },
  ShopeePay: { name: 'ShopeePay', min: 1_000, max: 2_000_000 },
  GOPAY: { name: 'GoPay', min: 500, max: 5_000_000 },
  BNCVA: { name: 'BNC Virtual Account', min: 10_000, max: 10_000_000 },
  SINARMAS: { name: 'Sinarmas Virtual Account', min: 10_000, max: 10_000_000 },
  BRIVA: { name: 'BRI Virtual Account', min: 10_000, max: 10_000_000 },
  BCAVA: { name: 'BCA Virtual Account', min: 10_000, max: 15_000_000 },
  DANAMON: { name: 'Danamon Virtual Account', min: 10_000, max: 15_000_000 },
  MUAMALAT: { name: 'Muamalat Virtual Account', min: 10_000, max: 15_000_000 },
  BSIVA: { name: 'BSI Virtual Account', min: 10_000, max: 20_000_000 },
  OCBC: { name: 'OCBC Virtual Account', min: 10_000, max: 10_000_000 },
  BAGVA: { name: 'BAG Virtual Account', min: 10_000, max: 15_000_000 },
  ALFAMART: { name: 'Alfamart', min: 10_000, max: 5_000_000 },
  INDOMARET: { name: 'Indomaret', min: 10_000, max: 2_500_000 },
};

export function formatIdr(value: number): string {
  return `Rp${Math.round(value).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')}`;
}

/** Constant-time string comparison for callback signatures. */
export function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

/** Whether a non-terminal payment update may overwrite the current status. */
export function shouldApplyPaymentStatus(current: string | null | undefined, next: string): boolean {
  if (current === 'berhasil') return false; // successful payment is terminal
  if (next === 'berhasil') return true;
  if (current === 'expired') return false;
  return next === 'pending' || next === 'expired';
}

/** Normalize SakuRupiah responses: `data` can be an array or an object. */
export function firstData(payload: any): Record<string, any> {
  if (!payload) return {};
  if (Array.isArray(payload.data)) return payload.data[0] ?? {};
  if (payload.data && typeof payload.data === 'object') return payload.data;
  return {};
}
