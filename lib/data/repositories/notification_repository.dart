// lib/data/repositories/notification_repository.dart
//
// Abstract interface for all notification data operations.
// MockNotificationSource implements this for Phases 1–9.

import 'package:personal_wellness_trainer/data/models/notification_model.dart';

abstract class NotificationRepository {
  /// Returns all notifications for a user, newest first.
  Future<List<NotificationModel>> getNotifications(
    String businessId,
    String userId,
  );

  /// Returns the count of unread notifications for a user.
  Future<int> getUnreadCount(String businessId, String userId);

  /// Marks a single notification as read.
  Future<NotificationModel> markRead(String notificationId);

  /// Marks all notifications as read for a user.
  Future<void> markAllRead(String businessId, String userId);

  /// Deletes a notification.
  Future<void> deleteNotification(String notificationId);

  /// Creates a notification for [userId] — the write path engine events
  /// use (agreement proposed/approved, member joined, sale recorded…).
  /// Never existed before M5: real mode's bell was permanently empty
  /// because nothing ever inserted a row.
  ///
  /// Real mode goes through the `notify_user` SECURITY DEFINER RPC
  /// (triggers.sql), which derives the business stamp from the
  /// RECIPIENT's profile (the read key getNotifications filters on) and
  /// validates the caller's relationship to them server-side: same
  /// business, or their businesses share an agreement. Direct inserts
  /// can't cover the cross-business case — the insert policy requires
  /// membership in the stamped business, which the notifying caller
  /// (e.g. the buyer's side of a referral sale) isn't part of.
  Future<void> createNotification({
    required String userId,
    required String businessId,
    required String type,
    required String title,
    required String body,
    String? referenceId,
    String? referenceType,
  });
}
