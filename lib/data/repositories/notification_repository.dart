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
}
