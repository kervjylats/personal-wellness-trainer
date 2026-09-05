// lib/data/models/user_profile.dart
//
// The UserProfile model is the ID badge of the engine.
// When any user logs in, the engine loads their profile and uses it to
// determine which shell to render, which business config to load, and
// which permissions apply. See Blueprint Section 3.
//
// Design rules:
//   - Immutable. All fields are final.
//   - copyWith() for producing updated copies.
//   - fromJson() for deserialising from database or mock source.
//   - toJson() for serialising (used by Supabase in Phase 10).
//   - ZERO business logic in this file. It is a data container only.
//
// Role is stored as a raw String from JSON ('owner' | 'partner' | 'staff' |
// 'client'). The typed AppRole getter is in the engine layer (app_role.dart)
// which is built in Group C. Data models do not import from engine/.
//
// Field sets per role (only fields relevant to a role are non-null):
//   owner   → businessName, businessLogoUrl, primaryColor, planTier, stripeAccountId
//   partner → categoryId, agreementStatus, commissionRate, featureToggles, hasUpgradedToPro
//   staff   → jobTitle, permissionToggles, assignedActivityCount
//   client  → primaryPartnerId, bookingCount, totalPaid, outstandingBalance

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.businessId,
    required this.role,
    required this.displayName,
    required this.joinedAt,
    required this.isActive,
    this.photoUrl,
    this.email,
    this.phone,
    // Owner fields
    this.businessName,
    this.businessLogoUrl,
    this.primaryColor,
    this.planTier,
    this.stripeAccountId,
    this.jobId,
    this.selectedCategory,
    this.currency,
    this.partnersEnabled,
    this.marketplaceEnabled,
    this.agreementsEnabled,
    // Partner fields
    this.categoryId,
    this.agreementStatus,
    this.commissionRate,
    this.featureToggles,
    this.hasUpgradedToPro,
    // Staff fields
    this.jobTitle,
    this.permissionToggles,
    this.assignedActivityCount,
    // Client fields
    this.primaryPartnerId,
    this.bookingCount,
    this.totalPaid,
    this.outstandingBalance,
  });

  // ── Universal Fields (all roles) ──────────────────────────────────────────────
  final String userId;
  final String businessId;

  /// Raw role string. Values: 'owner' | 'partner' | 'staff' | 'client'.
  /// Use AppRole enum for comparisons in Dart code — not this raw string.
  final String role;

  final String displayName;
  final DateTime joinedAt;
  final bool isActive;
  final String? photoUrl;
  final String? email;
  final String? phone;

  // ── Owner-Only Fields ─────────────────────────────────────────────────────────
  final String? businessName;
  final String? businessLogoUrl;

  /// Hex color string from config, e.g. '#2471A3'.
  /// The engine reads this to override the app's primary color per business.
  final String? primaryColor;

  /// Plan tier identifier, e.g. 'free' | 'pro'.
  final String? planTier;

  /// Stripe Connect account ID (Phase 2+). Null until Stripe is wired.
  final String? stripeAccountId;
  /// The job type selected during onboarding (e.g. 'dentist', 'taxi').
  /// Drives which JobDefinition is loaded as the active IndustryConfig.
  final String? jobId;
  final String? selectedCategory;
  final String? currency;

  /// Business-wide toggles (meaningful on the Owner's row only — every
  /// business member reads these off the Owner via businessFeaturesProvider,
  /// same pattern as reading the Owner's businessName/primaryColor). Defaults
  /// (via ?? true at every read site) keep pre-existing businesses fully
  /// functional if this was never set.
  final bool? partnersEnabled;
  final bool? marketplaceEnabled;
  final bool? agreementsEnabled;

  // ── Partner-Only Fields ───────────────────────────────────────────────────────
  final String? categoryId;

  /// Values: 'pending' | 'active' | 'terminated'. Null for non-partners.
  final String? agreementStatus;

  /// Commission rate from the active agreement. Null until agreement is active.
  final double? commissionRate;

  /// Map of feature permission keys to their enabled state.
  /// Set per-individual by the owner. Example: {'messaging_gps': true}.
  final Map<String, bool>? featureToggles;

  /// True if this partner has upgraded to their own Pro (owner) account.
  final bool? hasUpgradedToPro;

  // ── Staff-Only Fields ─────────────────────────────────────────────────────────
  /// Industry-agnostic job title label (e.g. 'staff_1'). Display text from config.
  final String? jobTitle;

  /// Map of permission keys to their enabled state.
  /// Set per-individual by the owner. Example: {'can_create_activity': true}.
  final Map<String, bool>? permissionToggles;

  final int? assignedActivityCount;

  // ── Client-Only Fields ────────────────────────────────────────────────────────
  /// The partner who referred this client, if any.
  final String? primaryPartnerId;

  final int? bookingCount;
  final double? totalPaid;
  final double? outstandingBalance;

  // ── Factory: fromJson ─────────────────────────────────────────────────────────
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String,
      role: json['role'] as String,
      displayName: json['display_name'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      photoUrl: json['photo_url'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      // Owner
      businessName: json['business_name'] as String?,
      businessLogoUrl: json['business_logo_url'] as String?,
      primaryColor: json['primary_color'] as String?,
      planTier: json['plan_tier'] as String?,
      stripeAccountId: json['stripe_account_id'] as String?,
      jobId: json['job_id'] as String?,
      selectedCategory: json['selected_category'] as String?,
      currency: json['currency'] as String?,
      partnersEnabled: json['partners_enabled'] as bool?,
      marketplaceEnabled: json['marketplace_enabled'] as bool?,
      agreementsEnabled: json['agreements_enabled'] as bool?,
      // Partner
      categoryId: json['category_id'] as String?,
      agreementStatus: json['agreement_status'] as String?,
      commissionRate: (json['commission_rate'] as num?)?.toDouble(),
      featureToggles: json['feature_toggles'] != null
          ? Map<String, bool>.from(
              json['feature_toggles'] as Map<dynamic, dynamic>,
            )
          : null,
      hasUpgradedToPro: json['has_upgraded_to_pro'] as bool?,
      // Staff
      jobTitle: json['job_title'] as String?,
      permissionToggles: json['permission_toggles'] != null
          ? Map<String, bool>.from(
              json['permission_toggles'] as Map<dynamic, dynamic>,
            )
          : null,
      assignedActivityCount: json['assigned_activity_count'] as int?,
      // Client
      primaryPartnerId: json['primary_partner_id'] as String?,
      bookingCount: json['booking_count'] as int?,
      totalPaid: (json['total_paid'] as num?)?.toDouble(),
      outstandingBalance: (json['outstanding_balance'] as num?)?.toDouble(),
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'business_id': businessId,
      'role': role,
      'display_name': displayName,
      'joined_at': joinedAt.toIso8601String(),
      'is_active': isActive,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      // Owner
      if (businessName != null) 'business_name': businessName,
      if (businessLogoUrl != null) 'business_logo_url': businessLogoUrl,
      if (primaryColor != null) 'primary_color': primaryColor,
      if (planTier != null) 'plan_tier': planTier,
      if (stripeAccountId != null) 'stripe_account_id': stripeAccountId,
      if (jobId != null) 'job_id': jobId,
      if (selectedCategory != null) 'selected_category': selectedCategory,
      if (currency != null) 'currency': currency,
      if (partnersEnabled != null) 'partners_enabled': partnersEnabled,
      if (marketplaceEnabled != null) 'marketplace_enabled': marketplaceEnabled,
      if (agreementsEnabled != null) 'agreements_enabled': agreementsEnabled,
      // Partner
      if (categoryId != null) 'category_id': categoryId,
      if (agreementStatus != null) 'agreement_status': agreementStatus,
      if (commissionRate != null) 'commission_rate': commissionRate,
      if (featureToggles != null) 'feature_toggles': featureToggles,
      if (hasUpgradedToPro != null) 'has_upgraded_to_pro': hasUpgradedToPro,
      // Staff
      if (jobTitle != null) 'job_title': jobTitle,
      if (permissionToggles != null) 'permission_toggles': permissionToggles,
      if (assignedActivityCount != null)
        'assigned_activity_count': assignedActivityCount,
      // Client
      if (primaryPartnerId != null) 'primary_partner_id': primaryPartnerId,
      if (bookingCount != null) 'booking_count': bookingCount,
      if (totalPaid != null) 'total_paid': totalPaid,
      if (outstandingBalance != null) 'outstanding_balance': outstandingBalance,
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────────
  UserProfile copyWith({
    String? userId,
    String? businessId,
    String? role,
    String? displayName,
    DateTime? joinedAt,
    bool? isActive,
    String? photoUrl,
    String? email,
    String? phone,
    String? businessName,
    String? businessLogoUrl,
    String? primaryColor,
    String? planTier,
    String? stripeAccountId,
    String? jobId,
    String? selectedCategory,
    String? currency,
    bool? partnersEnabled,
    bool? marketplaceEnabled,
    bool? agreementsEnabled,
    String? categoryId,
    String? agreementStatus,
    double? commissionRate,
    Map<String, bool>? featureToggles,
    bool? hasUpgradedToPro,
    String? jobTitle,
    Map<String, bool>? permissionToggles,
    int? assignedActivityCount,
    String? primaryPartnerId,
    int? bookingCount,
    double? totalPaid,
    double? outstandingBalance,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      planTier: planTier ?? this.planTier,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      jobId: jobId ?? this.jobId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      currency: currency ?? this.currency,
      partnersEnabled: partnersEnabled ?? this.partnersEnabled,
      marketplaceEnabled: marketplaceEnabled ?? this.marketplaceEnabled,
      agreementsEnabled: agreementsEnabled ?? this.agreementsEnabled,
      categoryId: categoryId ?? this.categoryId,
      agreementStatus: agreementStatus ?? this.agreementStatus,
      commissionRate: commissionRate ?? this.commissionRate,
      featureToggles: featureToggles ?? this.featureToggles,
      hasUpgradedToPro: hasUpgradedToPro ?? this.hasUpgradedToPro,
      jobTitle: jobTitle ?? this.jobTitle,
      permissionToggles: permissionToggles ?? this.permissionToggles,
      assignedActivityCount:
          assignedActivityCount ?? this.assignedActivityCount,
      primaryPartnerId: primaryPartnerId ?? this.primaryPartnerId,
      bookingCount: bookingCount ?? this.bookingCount,
      totalPaid: totalPaid ?? this.totalPaid,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          businessId == other.businessId &&
          role == other.role;

  @override
  int get hashCode => userId.hashCode ^ businessId.hashCode ^ role.hashCode;

  @override
  String toString() =>
      'UserProfile(userId: $userId, role: $role, displayName: $displayName)';
}
