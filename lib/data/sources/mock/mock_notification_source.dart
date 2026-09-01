// lib/data/sources/mock/mock_notification_source.dart
//
// Mock implementation of NotificationRepository.
// Active when DataConfig.useMockData = true.
// Seeded with realistic notifications for the owner user.
// Zero industry-specific words in this file.

import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/notification_model.dart';
import 'package:personal_wellness_trainer/data/repositories/notification_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockNotificationSource with MockSourceMixin implements NotificationRepository {
  static const String _tag = 'MockNotificationSource';

  static const _biz     = 'biz_mock_001';
  static const _owner   = 'usr_owner_001';
  static const _partner = 'usr_partner_001';
  static const _staff   = 'usr_staff_001';
  static const _client  = 'usr_client_001';

  final List<NotificationModel> _notifications = _seedNotifications();

  static List<NotificationModel> _seedNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id:          'notif_001',
        userId:      _owner,
        businessId:  _biz,
        title:       'New message from Jordan Partner',
        body:        'Sounds good — see you then.',
        type:        'message',
        createdAt:   now.subtract(const Duration(minutes: 30)),
        isRead:      false,
        referenceId: 'conv_001',
        referenceType: 'conversation',
      ),
      NotificationModel(
        id:          'notif_002',
        userId:      _owner,
        businessId:  _biz,
        title:       'Agreement proposed',
        body:        'Jordan Partner has proposed a new agreement.',
        type:        'agreement',
        createdAt:   now.subtract(const Duration(hours: 2)),
        isRead:      false,
        referenceId: 'agr_001',
        referenceType: 'agreement',
      ),
      NotificationModel(
        id:          'notif_003',
        userId:      _owner,
        businessId:  _biz,
        title:       'New team member joined',
        body:        'Morgan Staff has accepted your invitation.',
        type:        'team',
        createdAt:   now.subtract(const Duration(days: 1)),
        isRead:      true,
        referenceId: 'usr_staff_001',
        referenceType: 'team_member',
      ),
      NotificationModel(
        id:          'notif_004',
        userId:      _partner,
        businessId:  _biz,
        title:       'New message from Alex Owner',
        body:        'Can we connect tomorrow at 10?',
        type:        'message',
        createdAt:   now.subtract(const Duration(hours: 3)),
        isRead:      false,
        referenceId: 'conv_001',
        referenceType: 'conversation',
      ),
      NotificationModel(
        id:          'notif_005',
        userId:      _staff,
        businessId:  _biz,
        title:       'New task assigned',
        body:        'Alex Owner has assigned a record to you.',
        type:        'activity',
        createdAt:   now.subtract(const Duration(hours: 6)),
        isRead:      false,
        referenceType: 'activity',
      ),
      NotificationModel(
        id:          'notif_006',
        userId:      _client,
        businessId:  _biz,
        title:       'Record confirmed',
        body:        'Your request has been confirmed.',
        type:        'activity',
        createdAt:   now.subtract(const Duration(days: 2)),
        isRead:      true,
        referenceType: 'activity',
      ),
    ];
  }

  @override
  Future<List<NotificationModel>> getNotifications(
    String businessId,
    String userId,
  ) async {
    await simulateNetworkDelay();

    final result = _notifications
        .where(
          (n) => n.businessId == businessId && n.userId == userId,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    AppLogger.debug(
      'MockNotificationSource: ${result.length} notifications for $userId',
      tag: _tag,
    );
    return result;
  }

  @override
  Future<int> getUnreadCount(String businessId, String userId) async {
    await simulateNetworkDelay(const Duration(milliseconds: 100));
    return _notifications
        .where(
          (n) =>
              n.businessId == businessId &&
              n.userId == userId &&
              !n.isRead,
        )
        .length;
  }

  @override
  Future<NotificationModel> markRead(String notificationId) async {
    await simulateNetworkDelay(const Duration(milliseconds: 100));

    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx == -1) throw Exception('Notification not found: $notificationId');

    _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    AppLogger.debug('MockNotificationSource: marked $notificationId read', tag: _tag);
    return _notifications[idx];
  }

  @override
  Future<void> markAllRead(String businessId, String userId) async {
    await simulateNetworkDelay(const Duration(milliseconds: 100));

    for (var i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      if (n.businessId == businessId && n.userId == userId && !n.isRead) {
        _notifications[i] = n.copyWith(isRead: true);
      }
    }
    AppLogger.info(
      'MockNotificationSource: marked all read for $userId',
      tag: _tag,
    );
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await simulateNetworkDelay(const Duration(milliseconds: 100));
    _notifications.removeWhere((n) => n.id == notificationId);
    AppLogger.debug(
      'MockNotificationSource: deleted $notificationId',
      tag: _tag,
    );
  }
}
