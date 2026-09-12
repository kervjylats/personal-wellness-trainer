// lib/data/sources/supabase/supabase_notification_source.dart
//
// Real Supabase implementation of NotificationRepository. Strictly
// single-owner data — no cross-tenant or cross-user reads anywhere here.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/notification_model.dart';
import 'package:personal_wellness_trainer/data/repositories/notification_repository.dart';

class SupabaseNotificationSource implements NotificationRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<NotificationModel>> getNotifications(
    String businessId,
    String userId,
  ) async {
    final rows = await _db
        .from('notifications')
        .select()
        .eq('business_id', businessId)
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => NotificationModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> getUnreadCount(String businessId, String userId) async {
    final rows = await _db
        .from('notifications')
        .select('id')
        .eq('business_id', businessId)
        .eq('user_id', userId)
        .eq('is_read', false);
    return (rows as List).length;
  }

  @override
  Future<NotificationModel> markRead(String notificationId) async {
    final row = await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .select()
        .single();
    return NotificationModel.fromJson(row);
  }

  @override
  Future<void> markAllRead(String businessId, String userId) async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('business_id', businessId)
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _db.from('notifications').delete().eq('id', notificationId);
  }
}
