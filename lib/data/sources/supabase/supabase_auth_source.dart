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

    return _fetchProfile(response.user!.id);
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
      return await _fetchProfile(session.user.id);
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
      'primary_color': updatedProfile.primaryColor,
      'job_id': updatedProfile.jobId,
    }).eq('user_id', userId);
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

  Future<UserProfile> _fetchProfile(String userId) async {
    final data = await _db
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .single();
        
    return UserProfile.fromJson(data);
  }
}