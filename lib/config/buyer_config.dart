// lib/config/buyer_config.dart
//
// ═══════════════════════════════════════════════════════════════
// BUYER CONFIGURATION — Centralized dynamic platform controls.
// No coding knowledge needed to edit this file.
// ═══════════════════════════════════════════════════════════════

abstract final class BuyerConfig {
  // ── Database Credentials ──
  //
  // SECURITY: never commit real values here to a public repository —
  // this project was pushed to a public GitHub repo once already with a
  // real Supabase URL/key sitting in these two constants.
  //
  // The placeholders below are safe to commit. Provide your real
  // project's values one of two ways:
  //
  //   1. Simplest — replace the two placeholder strings below directly
  //      with your Supabase project's URL and anon key. Fine for a
  //      PRIVATE repo, or once you're done developing and just building
  //      a release APK/IPA locally.
  //
  //   2. Keep secrets out of source entirely (recommended whenever this
  //      repo — or any fork/copy of it — might be public) — pass them
  //      at build/run time instead, and leave the placeholders as-is:
  //        flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  //                     --dart-define=SUPABASE_ANON_KEY=xxxxx
  //      (the same two flags work with `flutter build` too)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL_HERE',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY_HERE',
  );

  // ── Dynamic License Key (The paid client's key) ──
  static const String dynamicActivationKey = 'SOPHIA-SOUND-999';

  // ── Developer Sandbox Bypass ──
  // Removed "const" so the compiler doesn't trigger "dead code" warnings during testing.
  static String? testBypassRole; // ◄ 'owner', 'partner', 'client', 'staff', or null

  // ── Support & After-Sales Customization Constants ──
  static const String supportEmail   = 'your-support@email.com';
  static const String supportWebsite = 'https://your-agency-website.com';

  // ── Build-Time Job Lock (Single-Client Mode) ──
  static const String? lockedJobId = null;

  // ── Dynamic Payment Engine ──
  static const Map<String, bool> enabledPaymentMethods = {
    'stripe_auto': false,         
    'paypal_auto': false,         
    'manual_cash_ledger': true,   
    'manual_bank_ledger': true,   
  };

  static const double platformFeePercentage = 5.0; 

  // ── Monetization & "Upgrade to Pro" Redirects ──
  static const Map<String, dynamic> proUpgradeSettings = {
    'show_to_owner': true,        
    'show_to_partner': true,      
    'button_label': 'Launch Your Own App',
    'subtitle': 'Get your own customized white-label practice and keep 100% of your earnings.',
    'redirect_url': 'https://codecanyon.net/your-listing', 
  };

  // ── Support Screen Settings Map ──
  static const Map<String, dynamic> supportScreenSettings = {
    'show_custom_features_banner': true,
    'button_label': 'Request Custom Feature',
    'subtitle': 'Need a custom payment method, integration, or custom design? Contact our dev team.',
    'support_email': supportEmail,
    'support_website': supportWebsite,
  };
}