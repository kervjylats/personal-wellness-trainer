// lib/engine/payments/payment_gateway.dart
//
// The one seam a buyer/dev swaps out to charge real money for the free
// Partner → Pro Owner upgrade. Ships as FreePaymentGateway, which always
// allows the upgrade for free — matching "no paywall by default, buyer
// adds their own later if they want one."
//
// To wire in Stripe/PayPal/Payoneer/anything else: write a new class
// implementing PaymentGateway, do the actual charge/checkout however that
// provider works, return true only once payment genuinely succeeded —
// then swap FreePaymentGateway() for it in AuthNotifier._resolvePaymentGateway()
// (auth_notifier.dart). Nothing else in the upgrade flow needs to change;
// upgradeToPremium() itself has no idea which gateway is behind this
// interface.

import 'package:personal_wellness_trainer/data/models/user_profile.dart';

abstract class PaymentGateway {
  /// Called before upgradeToPremium() does anything irreversible (minting
  /// a new businessId, migrating clients). Return true to let the
  /// upgrade proceed, false to block it — e.g. payment declined,
  /// cancelled, or the buyer's own checkout flow didn't complete.
  Future<bool> chargeForUpgrade(UserProfile profile);
}

class FreePaymentGateway implements PaymentGateway {
  @override
  Future<bool> chargeForUpgrade(UserProfile profile) async => true;
}
