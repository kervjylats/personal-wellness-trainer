// lib/data/repositories/homework_repository.dart
//
// Abstract interface for homework data operations.

import 'package:personal_wellness_trainer/data/models/homework_model.dart';

abstract class HomeworkRepository {
  Future<List<HomeworkModel>> getHomeworkForClient(
    String businessId,
    String clientUserId,
  );

  /// Every homework item in the business, newest first — the coach
  /// management view (owner/partner/staff) reads this so a coach sees
  /// assignments across ALL clients, not just items addressed to
  /// themselves (getHomeworkForClient is hard-wired to the signed-in
  /// user by HomeworkNotifier.build). RLS on the homework table is
  /// business-membership scoped for SELECT, so the DB permits exactly
  /// this read.
  Future<List<HomeworkModel>> getHomeworkForBusiness(String businessId);

  Future<HomeworkModel> assignHomework({
    required String businessId,
    required String assignedByUserId,
    required String assignedToUserId,
    required String assignedToUserName,
    required String title,
    String description = '',
  });

  Future<HomeworkModel> markCompleted(String homeworkId);

  Future<void> deleteHomework(String homeworkId);
}