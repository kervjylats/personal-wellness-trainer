import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_repository.dart';

class SupabaseAuthSource implements AuthRepository {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<UserProfile> signIn(String email, String password) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Sign-in failed. User not found.');
    }

    final profile = await _fetchProfile(response.user!.id);
    // M10: the profiles row is now self-readable even when deactivated
    // (schema.sql SELECT policy), so we can tell the user WHY instead of
    // surfacing a raw PGRST116 "no rows" crash from _fetchProfile.
    if (!profile.isActive) {
      throw Exception(
        'Your access to this business was removed. Ask the owner to restore your account.',
      );
    }
    return profile;
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
    String? redemptionCode,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
        if (redemptionCode != null) 'redemption_code': redemptionCode,
      },
    );

    if (response.user == null) {
      throw Exception('Registration failed.');
    }

    return _fetchProfile(response.user!.id);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<UserProfile?> restoreSession() async {
    final session = _auth.currentSession;
    if (session == null) return null;
    
    try {
      final profile = await _fetchProfile(session.user.id);
      // M10: a deactivated member's stored session resolves to a
      // readable-but-inactive profile; drop it to signed-out rather
      // than restoring a session the app must now police everywhere.
      if (!profile.isActive) return null;
      return profile;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isNewOwner(String userId) async {
    final profile = await _fetchProfile(userId);
    if (profile.role != 'owner') return false;
    
    return profile.jobId == null;
  }

  @override
  Future<void> setOnboardingComplete(String userId, {UserProfile? updatedProfile}) async {
    if (updatedProfile == null) return;

    await _db.from('profiles').update({
      'business_name': updatedProfile.businessName,
      'selected_category': updatedProfile.selectedCategory,
      // Phase C2 (M7): category_id used to be skipped here while the
      // auth notifier's comment claimed setOnboardingComplete covered it
      // — it didn't, so real-mode owners read back null categoryId and
      // every downstream flow (invite links, marketplace discovery)
      // silently operated on an empty category. Both columns are
      // granted on profiles in schema.sql and always hold the same value.
      'category_id': updatedProfile.categoryId,
      'primary_color': updatedProfile.primaryColor,
      'job_id': updatedProfile.jobId,
      // The Owner's own marketing copy. Columns added in schema.sql
      // (business_tagline / business_description / owner_bio); without
      // these the onboarding form collected all three and stored none.
      'business_tagline': updatedProfile.businessTagline,
      'business_description': updatedProfile.businessDescription,
      'owner_bio': updatedProfile.ownerBio,
    }).eq('user_id', userId);
  }

  @override
  Future<void> updateProfileFields({
    required String userId,
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    // #10: the Settings → Profile screen used to mutate session state only
    // and never wrote anything here (the columns weren't even granted).
    // GoTrue FIRST when the sign-in address changes, so a rejected email
    // (taken/invalid) fails the whole save instead of leaving auth and
    // profiles disagreeing about the address.
    if (email != null && email.isNotEmpty) {
      await _auth.updateUser(UserAttributes(email: email));
    }

    final updates = <String, dynamic>{
      if (displayName != null && displayName.isNotEmpty)
        'display_name': displayName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photo_url': photoUrl, // column added in schema.sql (#8)
    };
    if (updates.isEmpty) return;
    await _db.from('profiles').update(updates).eq('user_id', userId);
  }

  @override
  Future<void> setPlanTier(String userId, String planTier) async {
    // A user cannot update their OWN profiles row's plan_tier via the
    // normal table API (RLS + column grants in schema.sql block it) — so
    // tier changes go through a SECURITY DEFINER function owned by the
    // buyer's service role. See supabase/schema.sql `set_plan_tier()`.
    await _db.rpc('set_plan_tier', params: {
      'p_user_id': userId,
      'p_plan_tier': planTier,
    });
  }

  @override
  Future<void> recordUpgradeEvent({
    required String userId,
    String? email,
    required String fromRole,
    required String toRole,
    String? fromTier,
    String? toTier,
    required String businessId,
  }) async {
    // Best-effort audit row. Never throws — an upgrade already in progress
    // must not be rolled back because the audit write failed.
    try {
      await _db.from('upgrade_events').insert({
        'user_id': userId,
        'email': email,
        'from_role': fromRole,
        'to_role': toRole,
        'from_tier': fromTier,
        'to_tier': toTier,
        'business_id': businessId,
      });
    } catch (_) {
      // Ignored — see comment above.
    }
  }

  @override
  Future<String> launchBusiness() async {
    // One atomic SECURITY DEFINER transaction: mints a real uuid business
    // id, flips role/business_id/plan_tier (all API-unwritable via column
    // grants), migrates the associate's clients, and records the
    // upgrade_events audit row. See triggers.sql `launch_business()`.
    final newBusinessId = await _db.rpc('launch_business');
    return newBusinessId as String;
  }

  Future<UserProfile> _fetchProfile(String userId) async {
    final data = await _db
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .single();

    // Rows written before the M7 fix (or by handle_new_user's activation
    // branch) only set selected_category — mirror the team source's
    // `category_id ?? selected_category` fallback so those profiles read
    // back with a usable categoryId instead of null.
    if (data['category_id'] == null && data['selected_category'] != null) {
      data['category_id'] = data['selected_category'];
    }

    return UserProfile.fromJson(data);
  }
}