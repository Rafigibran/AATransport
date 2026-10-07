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

/** Normalize SakuRupiah responses: `data` can be an array or an object. */
export function firstData(payload: any): Record<string, any> {
  if (!payload) return {};
  if (Array.isArray(payload.data)) return payload.data[0] ?? {};
  if (payload.data && typeof payload.data === 'object') return payload.data;
  return {};
}
