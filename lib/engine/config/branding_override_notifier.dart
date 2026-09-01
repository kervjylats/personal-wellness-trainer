// lib/engine/config/branding_override_notifier.dart
//
// BrandingOverrideNotifier lets the owner change their app's visual identity
// at runtime from the Branding settings screen.
//
// Changes watched by main.dart to immediately rebuild ThemeData and the
// app's title bar. Session-only in mock mode (resets on restart).
// Phase 10: persist to owner's Supabase profile / industry_config row.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class BrandingOverride {
  const BrandingOverride({
    this.businessName,
    this.primaryColorHex,
    this.currency,
  });

  /// If non-null, overrides IndustryConfig.appName.
  final String? businessName;

  /// If non-null, overrides IndustryConfig.primaryColor (hex string '#RRGGBB').
  final String? primaryColorHex;

  /// If non-null, overrides ConfigPayment.currencyDefault.
  final String? currency;

  BrandingOverride copyWith({
    String? businessName,
    String? primaryColorHex,
    String? currency,
  }) {
    return BrandingOverride(
      businessName:    businessName    ?? this.businessName,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      currency:        currency        ?? this.currency,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final brandingOverrideProvider =
    NotifierProvider<BrandingOverrideNotifier, BrandingOverride>(
  BrandingOverrideNotifier.new,
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class BrandingOverrideNotifier extends Notifier<BrandingOverride> {
  @override
  BrandingOverride build() => const BrandingOverride();

  void updateBusinessName(String name) {
    state = state.copyWith(businessName: name.trim().isEmpty ? null : name.trim());
  }

  void updatePrimaryColor(String hexColor) {
    state = state.copyWith(primaryColorHex: hexColor);
  }

  void updateCurrency(String symbol) {
    state = state.copyWith(currency: symbol.trim().isEmpty ? null : symbol.trim());
  }

  void reset() {
    state = const BrandingOverride();
  }
}
