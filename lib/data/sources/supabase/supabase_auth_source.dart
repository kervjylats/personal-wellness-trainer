import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_repository.dart';

class SupabaseAuthSource implements AuthRepository {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  final SupabaseClient _db = Supabase.instance.client;

  String _deterministicUuid(String key) {
    final bytes = utf8.encode(key.trim().toUpperCase());
    final hash = <int>[];
    for (int i = 0; i < 16; i++) {
      if (i < bytes.length) {
        hash.add(bytes[i]);
      } else {
        hash.add((i * 31) & 0xFF);
      }
    }
    final hex = hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

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
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
        'role': 'owner', 
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

  /// ── LIVE DATABASE LICENSE KEY ACTIVATION ──
  @override
  Future<UserProfile?> activateLicenseKey(String key) async {
    final trimmed = key.trim().toUpperCase();

    // 1. Query your live "activation_keys" table in the Supabase cloud!
    final response = await _db
        .from('activation_keys')
        .select()
        .eq('key_code', trimmed)
        .maybeSingle();

    if (response == null) return null; // Key doesn't exist on your server

    // 2. Extract the pre-configured parameters from your cloud database row!
    final jobId = response['job_id'] as String;
    final businessName = response['business_name'] as String;
    final primaryColor = response['primary_color'] as String;

    // Use a stable, distinct mock/live UUID for the activated profile
    final String userId = _deterministicUuid(trimmed);
    final String businessId = _deterministicUuid('biz_$trimmed');

    // Check if they already have an active profile in your live profiles table
    final existing = await _db
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      return UserProfile.fromJson(existing);
    }

    // 3. If first-time activation, insert their pre-activated Owner profile row into the cloud database!
    final newProfile = {
      'user_id': userId,
      'business_id': businessId,
      'role': 'owner',
      'display_name': businessName,
      'email': 'owner@${trimmed.toLowerCase()}.com',
      'is_active': true,
      'business_name': businessName,
      'plan_tier': 'premium', // Unlocks white-labeling instantly
      'job_id': jobId,
      'selected_category': jobId,
      'primary_color': primaryColor,
    };

    await _db.from('profiles').insert(newProfile);
    return UserProfile.fromJson(newProfile);
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