import 'package:personal_wellness_trainer/data/models/invite_link_model.dart';
import 'package:personal_wellness_trainer/data/repositories/invite_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockInviteSource with MockSourceMixin implements InviteRepository {
  static const String _businessId = 'biz_mock_001';

  static final List<InviteLinkModel> _store = _buildSeedData();
  static int _idCounter = 10;

  static void resetForTesting() {
    _store
      ..clear()
      ..addAll(_buildSeedData());
    _idCounter = 10;
  }

  @override
  Future<List<InviteLinkModel>> getLinks(String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((l) => l.businessId == businessId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<InviteLinkModel?> getLinkByToken(String token) async {
    await simulateNetworkDelay();
    try {
      return _store.firstWhere((l) => l.token == token);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<InviteLinkModel> createLink({
    required String businessId,
    required String invitedByUserId,
    required String invitedByRole,
    required String targetRole,
    String? categoryId,
    String? label,
    int maxUses = 0,
    DateTime? expiresAt,
  }) async {
    await simulateNetworkDelay();
    _idCounter++;
    final id = 'lnk_mock_${_idCounter.toString().padLeft(3, '0')}';
    final link = InviteLinkModel(
      id: id,
      token: 'wlp_${_idCounter.toString().padLeft(6, '0')}',
      businessId: businessId,
      invitedByUserId: invitedByUserId,
      invitedByRole: invitedByRole,
      targetRole: targetRole,
      categoryId: categoryId,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      useCount: 0,
      maxUses: maxUses,
      label: label,
    );
    _store.add(link);
    return link;
  }

  @override
  Future<InviteLinkModel> recordUse(String linkId) async {
    await simulateNetworkDelay();
    final index = _store.indexWhere((l) => l.id == linkId);
    if (index == -1) throw Exception('InviteLink $linkId not found');
    final updated = _store[index].copyWith(
      useCount: _store[index].useCount + 1,
    );
    _store[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteLink(String linkId) async {
    await simulateNetworkDelay();
    _store.removeWhere((l) => l.id == linkId);
  }

  static List<InviteLinkModel> _buildSeedData() {
    final now = DateTime.now();
    return [
      InviteLinkModel(
        id: 'lnk_mock_001',
        token: 'wlp_000001',
        businessId: _businessId,
        invitedByUserId: 'usr_owner_001',
        invitedByRole: 'owner',
        targetRole: 'client',
        createdAt: now.subtract(const Duration(days: 7)),
        useCount: 3,
        maxUses: 0,
        label: 'General client invite',
      ),
      InviteLinkModel(
        id: 'lnk_mock_002',
        token: 'wlp_000002',
        businessId: _businessId,
        invitedByUserId: 'usr_owner_001',
        invitedByRole: 'owner',
        targetRole: 'partner',
        categoryId: 'cat_1',
        createdAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 14)),
        useCount: 0,
        maxUses: 1,
        label: 'Cat 1 partner slot',
      ),
    ];
  }
}
