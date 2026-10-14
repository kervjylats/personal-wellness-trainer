// lib/modules/homework/providers/homework_notifier.dart
//
// Riverpod notifier for client homework – load, assign, mark completed, delete.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/homework_model.dart';
import 'package:personal_wellness_trainer/data/repositories/homework_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_homework_source.dart';
import 'package:personal_wellness_trainer/data/sources/supabase/supabase_homework_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

final _homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  if (DataConfig.useMockData) return MockHomeworkSource();
  return SupabaseHomeworkSource();
});

final homeworkNotifierProvider =
    AsyncNotifierProvider<HomeworkNotifier, List<HomeworkModel>>(
  HomeworkNotifier.new,
  dependencies: [authNotifierProvider],
);

/// Business-wide homework for the COACH management view.
///
/// `homeworkNotifierProvider` is hard-wired to homework assigned to the
/// signed-in user (the client view), so a coach watching it always saw
/// an empty list even after assigning work. This provider reads
/// getHomeworkForBusiness instead. It deliberately lives here rather
/// than as a method on HomeworkNotifier because that class declares
/// `dependencies: [authNotifierProvider]`, and a dependent notifier
/// cannot invalidate providers outside its dependency set — the screen
/// invalidates THIS provider after an assign/delete.
final businessHomeworkNotifierProvider =
    AsyncNotifierProvider<BusinessHomeworkNotifier, List<HomeworkModel>>(
  BusinessHomeworkNotifier.new,
  dependencies: [authNotifierProvider],
);

class BusinessHomeworkNotifier extends AsyncNotifier<List<HomeworkModel>> {
  static const String _tag = 'BusinessHomeworkNotifier';

  HomeworkRepository get _repo => ref.read(_homeworkRepositoryProvider);

  @override
  Future<List<HomeworkModel>> build() async {
    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) return [];
    return _repo.getHomeworkForBusiness(auth.profile.businessId);
  }

  Future<void> delete(String homeworkId) async {
    try {
      await _repo.deleteHomework(homeworkId);
      ref.invalidateSelf();
    } catch (e, st) {
      AppLogger.error('delete homework failed', tag: _tag, error: e, stackTrace: st);
    }
  }
}

class HomeworkNotifier extends AsyncNotifier<List<HomeworkModel>> {
  static const String _tag = 'HomeworkNotifier';

  HomeworkRepository get _repo => ref.read(_homeworkRepositoryProvider);

  @override
  Future<List<HomeworkModel>> build() async {
    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) return [];
    return _repo.getHomeworkForClient(
      auth.profile.businessId,
      auth.profile.userId,
    );
  }

  Future<HomeworkModel?> assign({
    required String assignedToUserId,
    required String assignedToUserName,
    required String title,
    String description = '',
  }) async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return null;
    try {
      final hw = await _repo.assignHomework(
        businessId: auth.profile.businessId,
        assignedByUserId: auth.profile.userId,
        assignedToUserId: assignedToUserId,
        assignedToUserName: assignedToUserName,
        title: title,
        description: description,
      );
      ref.invalidateSelf();
      return hw;
    } catch (e, st) {
      AppLogger.error('assign homework failed', tag: _tag, error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> markCompleted(String homeworkId) async {
    try {
      await _repo.markCompleted(homeworkId);
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      AppLogger.error('mark homework completed failed', tag: _tag, error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> delete(String homeworkId) async {
    try {
      await _repo.deleteHomework(homeworkId);
      ref.invalidateSelf();
    } catch (e, st) {
      AppLogger.error('delete homework failed', tag: _tag, error: e, stackTrace: st);
    }
  }
}

