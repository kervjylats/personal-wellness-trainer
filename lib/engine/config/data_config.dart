// lib/engine/config/data_config.dart
// ═══════════════════════════════════════════════════════════════
// DATA CONFIG — The ONE flag that controls where data comes from.
//
// true  = mock data   ← ALL building phases (Phases 0–9) and the default
// false = Supabase    ← Phase 10 (live backend)
//
// The flag is a build-time --dart-define, so the SAME source tree can
// produce either app without editing this file:
//
//   Mock (default — nothing to pass):
//     flutter build web
//
//   Live Supabase:
//     flutter build web --dart-define=USE_MOCK_DATA=false \
//                       --dart-define=SUPABASE_URL=https://xxx.supabase.co \
//                       --dart-define=SUPABASE_ANON_KEY=xxxxx
//
//   (Same flags work with `flutter run`; SUPABASE_URL/SUPABASE_ANON_KEY
//   are read by BuyerConfig — see lib/config/buyer_config.dart.)
//
// Because `bool.fromEnvironment` is still a const, both branches of
// every `DataConfig.useMockData ? MockX() : SupabaseX()` in the codebase
// compile as before and the unused one is tree-shaken at build time.
// ═══════════════════════════════════════════════════════════════

abstract final class DataConfig {
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );
}
