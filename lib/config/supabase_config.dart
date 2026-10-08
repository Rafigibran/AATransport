/// Supabase project configuration.
///
/// The publishable key is a public client key (safe to embed in the app);
/// data is protected by Row Level Security. Override at build time with:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jbowxiolzbbacfyatvoh.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_6NdcA68oU6B0vctCx7jTPA_XxUNmo0b',
  );
}
