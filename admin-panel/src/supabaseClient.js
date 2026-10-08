import { createClient } from '@supabase/supabase-js';

// Publishable key is a public client key; data is protected by Supabase RLS
// and the `role = 'admin'` policies. Override with Vite env vars if needed:
// VITE_SUPABASE_URL / VITE_SUPABASE_PUBLISHABLE_KEY
const supabaseUrl =
  import.meta.env.VITE_SUPABASE_URL || 'https://jbowxiolzbbacfyatvoh.supabase.co';
const supabasePublishableKey =
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
  'sb_publishable_6NdcA68oU6B0vctCx7jTPA_XxUNmo0b';

export const SUPABASE_URL = supabaseUrl;
export const supabase = createClient(supabaseUrl, supabasePublishableKey);
