// lib/data/repositories/progress_repository.dart
//
// Abstract interface for progress tracking operations.

import 'package:personal_wellness_trainer/data/models/progress_entry_model.dart';

abstract class ProgressRepository {
  Future<List<ProgressEntryModel>> getEntries(
    String businessId,
    String clientUserId,
  );

  Future<ProgressEntryModel> addEntry({
    required String businessId,
    required String clientUserId,
    List<String> photoUrls = const [],
    Map<String, double> metrics = const {},
    String? notes,
  });

  Future<void> deleteEntry(String entryId);
}