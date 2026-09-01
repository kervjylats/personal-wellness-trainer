import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/progress_entry_model.dart';
import 'package:personal_wellness_trainer/data/repositories/progress_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_progress_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

final _progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  if (DataConfig.useMockData) return MockProgressSource();
  throw UnimplementedError('Supabase progress source — Phase 10');
});

final progressNotifierProvider =
    AsyncNotifierProvider<ProgressNotifier, List<ProgressEntryModel>>(
  ProgressNotifier.new,
  dependencies: [authNotifierProvider],
);

class ProgressNotifier extends AsyncNotifier<List<ProgressEntryModel>> {
  static const String _tag = 'ProgressNotifier';

  ProgressRepository get _repo => ref.read(_progressRepositoryProvider);

  @override
  Future<List<ProgressEntryModel>> build() async {
    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) return [];
    return _repo.getEntries(
      auth.profile.businessId,
      auth.profile.userId,
    );
  }

  Future<ProgressEntryModel?> addEntry({
    List<String> photoUrls = const [],
    Map<String, double> metrics = const {},
    String? notes,
  }) async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return null;
    try {
      final entry = await _repo.addEntry(
        businessId: auth.profile.businessId,
        clientUserId: auth.profile.userId,
        photoUrls: photoUrls,
        metrics: metrics,
        notes: notes,
      );
      ref.invalidateSelf();
      return entry;
    } catch (e, st) {
      AppLogger.error('add progress entry failed', tag: _tag, error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      await _repo.deleteEntry(entryId);
      ref.invalidateSelf();
    } catch (e, st) {
      AppLogger.error('delete progress entry failed', tag: _tag, error: e, stackTrace: st);
    }
  }
}
