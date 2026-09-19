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

  Future<UserProfile> _fetchProfile(String userId) async {
    final data = await _db
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .single();
        
    return UserProfile.fromJson(data);
  }
}