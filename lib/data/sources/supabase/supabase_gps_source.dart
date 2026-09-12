// lib/data/sources/supabase/supabase_gps_source.dart
//
// Real Supabase implementation of GpsRepository. See schema.sql's
// gps_points table comment for the RLS reasoning — location data is
// handled more conservatively than most tables (row-level "your own
// data" plus an explicit Owner-only broader read, rather than the
// default business-membership pattern most other tables use).

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/gps_point_model.dart';
import 'package:personal_wellness_trainer/data/repositories/gps_repository.dart';

class SupabaseGpsSource implements GpsRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<GpsPointModel>> getLatestPoints(String businessId) async {
    // Postgrest has no built-in "latest row per group" query — pull all
    // points for the business (RLS already restricts this to Owner-only
    // in practice) ordered newest-first, then keep only the first point
    // seen per user client-side. Fine at this table's expected scale
    // (one business's tracked staff, not a general-purpose location feed).
    final rows = await _db
        .from('gps_points')
        .select()
        .eq('business_id', businessId)
        .order('recorded_at', ascending: false);

    final seen = <String>{};
    final latest = <GpsPointModel>[];
    for (final r in rows as List) {
      final point = GpsPointModel.fromJson(r as Map<String, dynamic>);
      if (seen.add(point.userId)) latest.add(point);
    }
    return latest;
  }

  @override
  Future<List<GpsPointModel>> getPointsForUser(
    String businessId,
    String userId,
  ) async {
    final rows = await _db
        .from('gps_points')
        .select()
        .eq('business_id', businessId)
        .eq('user_id', userId)
        .order('recorded_at', ascending: false);
    return (rows as List)
        .map((r) => GpsPointModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GpsPointModel> recordPoint({
    required String businessId,
    required String userId,
    required double latitude,
    required double longitude,
    String? label,
    double? accuracyMetres,
    String? linkedActivityId,
  }) async {
    final row = await _db.from('gps_points').insert({
      'business_id': businessId,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      if (label != null) 'label': label,
      if (accuracyMetres != null) 'accuracy_metres': accuracyMetres,
      if (linkedActivityId != null) 'linked_activity_id': linkedActivityId,
    }).select().single();

    return GpsPointModel.fromJson(row);
  }

  @override
  Future<void> clearPointsForUser(String businessId, String userId) async {
    await _db
        .from('gps_points')
        .delete()
        .eq('business_id', businessId)
        .eq('user_id', userId);
  }
}
