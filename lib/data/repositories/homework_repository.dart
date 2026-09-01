// lib/data/repositories/homework_repository.dart
//
// Abstract interface for homework data operations.

import 'package:personal_wellness_trainer/data/models/homework_model.dart';

abstract class HomeworkRepository {
  Future<List<HomeworkModel>> getHomeworkForClient(
    String businessId,
    String clientUserId,
  );

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