// lib/data/sources/supabase/supabase_homework_source.dart
//
// Real Supabase implementation of HomeworkRepository.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/homework_model.dart';
import 'package:personal_wellness_trainer/data/repositories/homework_repository.dart';

class SupabaseHomeworkSource implements HomeworkRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<HomeworkModel>> getHomeworkForClient(
    String businessId,
    String clientUserId,
  ) async {
    final rows = await _db
        .from('homework')
        .select()
        .eq('business_id', businessId)
        .eq('assigned_to_user_id', clientUserId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => HomeworkModel.fromJson(r as Map<String, dynamic>))
        .toList();
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
    final row = await _db.from('homework').insert({
      'business_id': businessId,
      'assigned_by_user_id': assignedByUserId,
      'assigned_to_user_id': assignedToUserId,
      'assigned_to_user_name': assignedToUserName,
      'title': title,
      'description': description,
      'is_completed': false,
    }).select().single();

    return HomeworkModel.fromJson(row);
  }

  @override
  Future<HomeworkModel> markCompleted(String homeworkId) async {
    final row = await _db
        .from('homework')
        .update({
          'is_completed': true,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', homeworkId)
        .select()
        .single();
    return HomeworkModel.fromJson(row);
  }

  @override
  Future<void> deleteHomework(String homeworkId) async {
    await _db.from('homework').delete().eq('id', homeworkId);
  }
}
