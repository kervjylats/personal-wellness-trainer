// lib/data/sources/mock/mock_team_source.dart

import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/data/repositories/team_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockTeamSource with MockSourceMixin implements TeamRepository {
  static const String _businessId = 'biz_mock_001';

  static final List<TeamMemberModel> _store = _buildSeedData();
  static int _idCounter = 50;

  // ── SaaS Spin-Off Client Migration Script ──
  void migratePartnerClients(String partnerId, String newBusinessId) {
    for (int i = 0; i < _store.length; i++) {
      final member = _store[i];
      if (member.role == 'client' && member.primaryPartnerId == partnerId) {
        _store[i] = member.copyWith(businessId: newBusinessId);
      }
    }
  }

  @override
  Future<List<TeamMemberModel>> getMembers(
    String businessId, {
    String? role,
  }) async {
    await simulateNetworkDelay();
    
    final matches = _store.where((m) => m.businessId == businessId && (role == null || m.role == role)).toList();
    if (matches.isEmpty) {
      // Dynamic Fallback: Clone seed partners & staff to the active businessId
      return _store
          .map((m) => m.copyWith(businessId: businessId))
          .where((m) => role == null || m.role == role)
          .toList();
    }
    return matches;
  }

  @override
  Future<TeamMemberModel> inviteMember({
    required String businessId,
    required String invitedByUserId,
    required String role,
    required String displayName,
    String? email,
    String? categoryId,
  }) async {
    await simulateNetworkDelay();

    _idCounter++;
    final now = DateTime.now();
    final member = TeamMemberModel(
      userId: 'usr_mock_${_idCounter.toString().padLeft(3, '0')}',
      businessId: businessId,
      role: role,
      displayName: displayName,
      isActive: true,
      joinedAt: now,
      featureToggles: _defaultTogglesFor(role),
      categoryId: categoryId,
      email: email,
      inviteToken: 'tok_mock_${_idCounter.toString().padLeft(3, '0')}',
      primaryPartnerId: role == 'client' ? invitedByUserId : null,
    );
    _store.add(member);
    return member;
  }

  @override
  Future<TeamMemberModel> toggleFeature({
    required String memberId,
    required String businessId,
    required String featureKey,
    required bool value,
  }) async {
    await simulateNetworkDelay();

    // 1. Search by exact match first
    int index = _store.indexWhere(
        (m) => m.userId == memberId && m.businessId == businessId);
        
    // 2. Fallback: If not found, search by userId alone (to support active dev business mappings!)
    if (index == -1) {
      index = _store.indexWhere((m) => m.userId == memberId);
      // Synchronize their businessId on the fly in the master list
      if (index != -1) {
        _store[index] = _store[index].copyWith(businessId: businessId);
      }
    }

    if (index == -1) throw Exception('Member $memberId not found');

    // Merge new feature toggles
    final updated = _store[index].copyWith(
      featureToggles: {
        ..._store[index].featureToggles,
        featureKey: value,
      },
    );
    _store[index] = updated;
    return updated;
  }

  @override
  Future<bool> removeMember({
    required String memberId,
    required String businessId,
  }) async {
    await simulateNetworkDelay();
    final before = _store.length;
    
    // Remove by exact match or by matching the default mock space fallback
    _store.removeWhere((m) => m.userId == memberId && (m.businessId == businessId || m.businessId == _businessId));
    
    return _store.length < before;
  }

  static List<TeamMemberModel> _buildSeedData() {
    final base = DateTime(2025, 1, 15);
    return [
      TeamMemberModel(
        userId: 'usr_partner_001',
        businessId: _businessId,
        role: 'partner',
        displayName: 'Jordan Partner',
        isActive: true,
        joinedAt: base,
        categoryId: 'cat_2',
        email: 'partner1@mock.com',
        featureToggles: const {
          'can_upload_media': false,
          'can_view_client_list': false,
          'sees_upgrade_prompt': true,
        },
      ),
      TeamMemberModel(
        userId: 'usr_partner_002',
        businessId: _businessId,
        role: 'partner',
        displayName: 'Casey Partner',
        isActive: true,
        joinedAt: base,
        categoryId: 'cat_3',
        email: 'partner2@mock.com',
        featureToggles: const {
          'can_upload_media': true,
          'can_view_client_list': false,
          'sees_upgrade_prompt': true,
        },
      ),
      TeamMemberModel(
        userId: 'usr_staff_001',
        businessId: _businessId,
        role: 'staff',
        displayName: 'Morgan Staff',
        isActive: true,
        joinedAt: base,
        email: 'staff1@mock.com',
        featureToggles: const {
          'can_create_activity': true,
          'can_view_finance': false,
          'can_manage_clients': false,
          'can_view_all_activities': true,
        },
      ),
      TeamMemberModel(
        userId: 'usr_client_001',
        businessId: _businessId,
        role: 'client',
        displayName: 'Sam Client',
        isActive: true,
        joinedAt: base,
        email: 'client1@mock.com',
        primaryPartnerId: 'usr_partner_001',
        featureToggles: const {
          'can_book_activity': true,
          'can_view_free_media': true,
          'can_purchase_media': true,
        },
      ),
    ];
  }

  static Map<String, bool> _defaultTogglesFor(String role) {
    switch (role) {
      case 'partner':
        return {
          'can_upload_media': false,
          'can_view_client_list': false,
          'sees_upgrade_prompt': true,
        };
      case 'staff':
        return {
          'can_create_activity': true,
          'can_view_finance': false,
          'can_manage_clients': false,
          'can_view_all_activities': true,
        };
      case 'client':
        return {
          'can_book_activity': true,
          'can_view_free_media': true,
          'can_purchase_media': true,
        };
      default:
        return {};
    }
  }
}