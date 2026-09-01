// lib/data/models/delivery_fee_model.dart
//
// Immutable data record for a single delivery fee zone.
// Zones are defined by distance range (km) and apply a flat fee.
// No industry-specific words.

class DeliveryFeeModel {
  const DeliveryFeeModel({
    required this.id,
    required this.businessId,
    required this.zoneLabel,
    required this.minDistanceKm,
    required this.maxDistanceKm,
    required this.fee,
    required this.currency,
    this.isActive = true,
  });

  final String id;
  final String businessId;

  /// Human-readable zone name (e.g. 'Local', 'Extended', 'Remote').
  final String zoneLabel;

  /// Inclusive lower bound of the zone in kilometres.
  final double minDistanceKm;

  /// Inclusive upper bound of the zone in kilometres.
  /// Use double.infinity for open-ended zones.
  final double maxDistanceKm;

  /// Flat fee applied for this zone.
  final double fee;

  final String currency;

  /// When false, this zone is inactive and not applied in calculations.
  final bool isActive;

  /// Returns true if the given distance falls within this zone.
  bool containsDistance(double distanceKm) {
    return distanceKm >= minDistanceKm && distanceKm <= maxDistanceKm;
  }

  // ── fromJson ──────────────────────────────────────────────────────────────────

  factory DeliveryFeeModel.fromJson(Map<String, dynamic> json) {
    return DeliveryFeeModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      zoneLabel: json['zone_label'] as String,
      minDistanceKm: (json['min_distance_km'] as num).toDouble(),
      maxDistanceKm: (json['max_distance_km'] as num).toDouble(),
      fee: (json['fee'] as num).toDouble(),
      currency: json['currency'] as String? ?? '\$',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'zone_label': zoneLabel,
      'min_distance_km': minDistanceKm,
      'max_distance_km': maxDistanceKm,
      'fee': fee,
      'currency': currency,
      'is_active': isActive,
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────────

  DeliveryFeeModel copyWith({
    String? id,
    String? businessId,
    String? zoneLabel,
    double? minDistanceKm,
    double? maxDistanceKm,
    double? fee,
    String? currency,
    bool? isActive,
  }) {
    return DeliveryFeeModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      zoneLabel: zoneLabel ?? this.zoneLabel,
      minDistanceKm: minDistanceKm ?? this.minDistanceKm,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      fee: fee ?? this.fee,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
    );
  }
}
