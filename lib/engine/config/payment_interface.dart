// lib/engine/config/payment_interface.dart
//
// Abstract payment provider interface. Stripe, PayPal, and Manual all
// implement this. Finance module talks ONLY to this interface.
// Swapping providers requires changing one config value, not finance logic.
//
// In Phase 1-9 the ManualPaymentProvider is the only active implementation.
// Stripe and PayPal are wired in Phase 10 when real payments are needed.
//
// See Blueprint Section 8 — Payment Architecture.

import 'package:personal_wellness_trainer/core/utils/logger.dart';

// ── Payment Result ────────────────────────────────────────────────────────────

/// The result returned by every PaymentProvider operation.
class PaymentResult {
  const PaymentResult({
    required this.success,
    required this.provider,
    this.externalRef,
    this.errorMessage,
    this.metadata,
  });

  final bool success;

  /// The provider that processed this payment.
  /// Values: 'manual' | 'stripe' | 'paypal'
  final String provider;

  /// External reference from the payment provider (e.g. Stripe charge ID).
  /// Null for manual payments.
  final String? externalRef;

  final String? errorMessage;

  /// Any additional metadata from the provider.
  final Map<String, dynamic>? metadata;

  factory PaymentResult.failed(String provider, String message) {
    return PaymentResult(
      success: false,
      provider: provider,
      errorMessage: message,
    );
  }

  @override
  String toString() =>
      'PaymentResult(success: $success, provider: $provider, ref: $externalRef)';
}

// ── Abstract Interface ────────────────────────────────────────────────────────

abstract class PaymentProvider {
  /// The provider's identifier string.
  /// Values: 'manual' | 'stripe' | 'paypal'
  String get providerId;

  /// Human-readable display name.
  String get displayName;

  /// Whether this provider is currently configured and available.
  /// Manual is always available. Stripe/PayPal require config keys.
  bool get isAvailable;

  /// Processes a payment of [amount] in [currencySymbol].
  /// Returns a [PaymentResult] — never throws.
  Future<PaymentResult> charge({
    required double amount,
    required String currencySymbol,
    required String description,
    String? customerId,
    Map<String, dynamic>? metadata,
  });

  /// Issues a full or partial refund for the given [externalRef].
  Future<PaymentResult> refund({
    required String externalRef,
    required double amount,
    String? reason,
  });
}

// ── Manual Payment Provider ───────────────────────────────────────────────────

/// Manual payment provider — always available, no configuration required.
/// Records cash, bank transfer, and invoice payments manually.
/// This is the default and fallback provider. Cannot be disabled.
class ManualPaymentProvider implements PaymentProvider {
  const ManualPaymentProvider();

  static const String _tag = 'ManualPaymentProvider';

  @override
  String get providerId => 'manual';

  @override
  String get displayName => 'Manual';

  @override
  bool get isAvailable => true; // Always available — hardcoded engine rule.

  @override
  Future<PaymentResult> charge({
    required double amount,
    required String currencySymbol,
    required String description,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    // Manual payments are always recorded as successful immediately.
    // The owner confirms the payment happened outside the app.
    AppLogger.info(
      'ManualPaymentProvider: recorded payment of $currencySymbol$amount',
      tag: _tag,
    );
    return PaymentResult(
      success: true,
      provider: providerId,
      externalRef: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      metadata: metadata,
    );
  }

  @override
  Future<PaymentResult> refund({
    required String externalRef,
    required double amount,
    String? reason,
  }) async {
    AppLogger.info(
      'ManualPaymentProvider: recorded refund of $amount for $externalRef',
      tag: _tag,
    );
    return PaymentResult(
      success: true,
      provider: providerId,
      externalRef: 'refund_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}

// ── Provider Registry ─────────────────────────────────────────────────────────

/// Returns the correct PaymentProvider based on the config value.
/// Called once at startup. Manual is always available as fallback.
PaymentProvider resolvePaymentProvider(String configuredProvider) {
  switch (configuredProvider.toLowerCase()) {
    case 'stripe':
      // Phase 10: return StripePaymentProvider();
      AppLogger.warning(
        'Stripe provider requested but not yet implemented. '
        'Falling back to ManualPaymentProvider.',
        tag: 'PaymentInterface',
      );
      return const ManualPaymentProvider();
    case 'paypal':
      // Phase 10: return PayPalPaymentProvider();
      AppLogger.warning(
        'PayPal provider requested but not yet implemented. '
        'Falling back to ManualPaymentProvider.',
        tag: 'PaymentInterface',
      );
      return const ManualPaymentProvider();
    case 'manual':
    default:
      return const ManualPaymentProvider();
  }
}
