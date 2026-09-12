// lib/data/sources/supabase/supabase_progress_source.dart
//
// Real Supabase implementation of ProgressRepository.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/progress_entry_model.dart';
import 'package:personal_wellness_trainer/data/repositories/progress_repository.dart';

class SupabaseProgressSource implements ProgressRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<ProgressEntryModel>> getEntries(
    String businessId,
    String clientUserId,
  ) async {
    final rows = await _db
        .from('progress_entries')
        .select()
        .eq('business_id', businessId)
        .eq('client_user_id', clientUserId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ProgressEntryModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProgressEntryModel> addEntry({
    required String businessId,
    required String clientUserId,
    List<String> photoUrls = const [],
    Map<String, double> metrics = const {},
    String? notes,
  }) async {
    final row = await _db.from('progress_entries').insert({
      'business_id': businessId,
      'client_user_id': clientUserId,
      'photo_urls': photoUrls,
      'metrics': metrics,
      if (notes != null) 'notes': notes,
    }).select().single();

    return ProgressEntryModel.fromJson(row);
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    await _db.from('progress_entries').delete().eq('id', entryId);
  }
}
