// lib/engine/config/data_config.dart
// ═══════════════════════════════════════════════════════════════
// DATA CONFIG — The ONE flag that controls where data comes from.
//
// true  = mock data   ← ALL building phases (Phases 0–9)
// false = Supabase    ← Phase 10 ONLY
//
// DO NOT change this to false until Phase 10.
// Changing it early will break everything — Supabase is not
// wired up yet and the app will crash on launch.
// ═══════════════════════════════════════════════════════════════

abstract final class DataConfig {
  static const bool useMockData = true;
}
