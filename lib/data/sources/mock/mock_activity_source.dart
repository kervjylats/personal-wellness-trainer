// lib/data/sources/mock/mock_activity_source.dart
import 'package:personal_wellness_trainer/data/models/activity_model.dart';
import 'package:personal_wellness_trainer/data/repositories/activity_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockActivitySource with MockSourceMixin implements ActivityRepository {
  static const String _businessId = 'biz_mock_001';
  static const String _ownerUserId = 'usr_owner_001';
  static const String _staffUserId = 'usr_staff_001';
  static const String _clientUserId = 'usr_client_001';

  static final List<ActivityModel> _store = _buildSeedData();
  static int _idCounter = 100;

  @override
  Future<List<ActivityModel>> getActivities(String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((a) => a.businessId == businessId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<ActivityModel>> getActivitiesForStaff(
    String businessId,
    String staffUserId,
  ) async {
    await simulateNetworkDelay();
    return _store
        .where((a) =>
            a.businessId == businessId &&
            a.assignedToUserId == staffUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<ActivityModel>> getActivitiesForClient(
    String businessId,
    String clientUserId,
  ) async {
    await simulateNetworkDelay();
    return _store
        .where((a) =>
            a.businessId == businessId && a.clientUserId == clientUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<ActivityModel> createActivity({
    required String businessId,
    required String createdByUserId,
    required Map<String, dynamic> fields,
    String? assignedToUserId,
    String? clientUserId,
    String? notes,
  }) async {
    await simulateNetworkDelay();
    _idCounter++;
    final now = DateTime.now();
    final activity = ActivityModel(
      id: 'act_mock_${_idCounter.toString().padLeft(3, '0')}',
      businessId: businessId,
      createdByUserId: createdByUserId,
      assignedToUserId: assignedToUserId,
      clientUserId: clientUserId,
      status: 'pending',
      createdAt: now,
      updatedAt: now,
      fields: Map<String, dynamic>.from(fields),
      notes: notes,
    );
    _store.insert(0, activity);
    return activity;
  }

  @override
  Future<ActivityModel> updateActivity({
    required String activityId,
    required Map<String, dynamic> fields,
    String? assignedToUserId,
    String? clientUserId,
    String? notes,
  }) async {
    await simulateNetworkDelay();
    final index = _store.indexWhere((a) => a.id == activityId);
    if (index == -1) throw Exception('Activity $activityId not found');
    final updated = _store[index].copyWith(
      fields: fields,
      assignedToUserId: assignedToUserId,
      clientUserId: clientUserId,
      notes: notes,
      updatedAt: DateTime.now(),
    );
    _store[index] = updated;
    return updated;
  }

  @override
  Future<void> updateActivityStatus(
    String activityId,
    String newStatus,
  ) async {
    await simulateNetworkDelay();
    final index = _store.indexWhere((a) => a.id == activityId);
    if (index == -1) throw Exception('Activity $activityId not found');
    _store[index] = _store[index].copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    await simulateNetworkDelay();
    _store.removeWhere((a) => a.id == activityId);
  }

  static List<ActivityModel> _buildSeedData() {
    final now = DateTime.now();
    return [
      ActivityModel(
        id: 'act_mock_001',
        businessId: _businessId,
        createdByUserId: _ownerUserId,
        assignedToUserId: _staffUserId,
        clientUserId: _clientUserId,
        status: 'confirmed',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        fields: {
          'service_type': 'Consultation',
          'scheduled_at': now.add(const Duration(days: 1)).toIso8601String(),
          'amount': 120.0,
          'notes': 'First visit.',
        },
      ),
      ActivityModel(
        id: 'act_mock_002',
        businessId: _businessId,
        createdByUserId: _ownerUserId,
        assignedToUserId: _staffUserId,
        clientUserId: 'usr_client_002',
        status: 'completed',
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 5)),
        fields: {
          'service_type': 'Session',
          'scheduled_at':
              now.subtract(const Duration(days: 5)).toIso8601String(),
          'amount': 80.0,
          'notes': '',
        },
      ),
      ActivityModel(
        id: 'act_mock_003',
        businessId: _businessId,
        createdByUserId: _staffUserId,
        assignedToUserId: _staffUserId,
        clientUserId: _clientUserId,
        status: 'pending',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        fields: {
          'service_type': 'Workshop',
          'scheduled_at': now.add(const Duration(days: 3)).toIso8601String(),
          'amount': 200.0,
          'notes': 'Group session.',
        },
      ),
      ActivityModel(
        id: 'act_mock_004',
        businessId: _businessId,
        createdByUserId: _ownerUserId,
        clientUserId: 'usr_client_002',
        status: 'in_progress',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        fields: {
          'service_type': 'Consultation',
          'scheduled_at': now.toIso8601String(),
          'amount': 150.0,
          'notes': '',
        },
      ),
      ActivityModel(
        id: 'act_mock_005',
        businessId: _businessId,
        createdByUserId: _ownerUserId,
        assignedToUserId: 'usr_staff_002',
        clientUserId: 'usr_client_003',
        status: 'cancelled',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 9)),
        fields: {
          'service_type': 'Session',
          'scheduled_at':
              now.subtract(const Duration(days: 9)).toIso8601String(),
          'amount': 80.0,
          'notes': 'Client cancelled.',
        },
      ),
    ];
  }
}