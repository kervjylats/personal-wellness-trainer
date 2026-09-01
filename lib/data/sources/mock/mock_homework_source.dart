// lib/data/sources/mock/mock_homework_source.dart
//
// Mock implementation of HomeworkRepository.

import 'package:personal_wellness_trainer/data/models/homework_model.dart';
import 'package:personal_wellness_trainer/data/repositories/homework_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockHomeworkSource with MockSourceMixin implements HomeworkRepository {
  static const String _businessId = 'biz_mock_001';

  static final List<HomeworkModel> _homeworks = [
    HomeworkModel(
      id: 'hw_001',
      businessId: _businessId,
      assignedByUserId: 'usr_owner_001',
      assignedToUserId: 'usr_client_001',
      assignedToUserName: 'Sam Client',
      title: 'Complete your food journal',
      description: 'Log everything you eat for 3 days.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isCompleted: false,
    ),
    HomeworkModel(
      id: 'hw_002',
      businessId: _businessId,
      assignedByUserId: 'usr_owner_001',
      assignedToUserId: 'usr_client_001',
      assignedToUserName: 'Sam Client',
      title: 'Morning stretch routine',
      description: '15-minute stretch video in Content Library.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isCompleted: true,
      completedAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  static int _idCounter = 10;

  @override
  Future<List<HomeworkModel>> getHomeworkForClient(
    String businessId,
    String clientUserId,
  ) async {
    await simulateNetworkDelay();
    return _homeworks
        .where((h) => h.businessId == businessId && h.assignedToUserId == clientUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<HomeworkModel> assignHomework({
    required String businessId,
    required String assignedByUserId,
    required String assignedToUserId,
    required String assignedToUserName,
    required String title,
    String description = '',
  }) async {
    await simulateNetworkDelay();
    _idCounter++;
    final hw = HomeworkModel(
      id: 'hw_$_idCounter',
      businessId: businessId,
      assignedByUserId: assignedByUserId,
      assignedToUserId: assignedToUserId,
      assignedToUserName: assignedToUserName,
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );
    _homeworks.add(hw);
    return hw;
  }

  @override
  Future<HomeworkModel> markCompleted(String homeworkId) async {
    await simulateNetworkDelay();
    final idx = _homeworks.indexWhere((h) => h.id == homeworkId);
    if (idx == -1) throw Exception('Homework not found');
    final updated = _homeworks[idx].copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    _homeworks[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteHomework(String homeworkId) async {
    await simulateNetworkDelay();
    _homeworks.removeWhere((h) => h.id == homeworkId);
  }
}