// lib/engine/config/feature_flags.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeatureFlags {
  final Map<String, dynamic> _flags;

  const FeatureFlags._(this._flags);

  bool _get(String path, bool defaultValue) {
    final keys = path.split('.');
    dynamic current = _flags;
    for (final key in keys) {
      if (current is Map) {
        current = current[key];
      } else {
        return defaultValue;
      }
    }
    return current is bool ? current : defaultValue;
  }

  bool get challengesOwnerCanCreate => _get('challenges.owner_can_create', true);
  bool get challengesPartnerCanCreate => _get('challenges.partner_can_create', false);
  bool get challengesPartnerCanView => _get('challenges.partner_can_view', true);
  bool get challengesClientCanView => _get('challenges.client_can_view', true);
  bool get challengesClientCanJoin => _get('challenges.client_can_join', true);
  bool get challengesShowInPartnerShell => _get('challenges.show_in_partner_shell', true);
  bool get challengesShowInClientShell => _get('challenges.show_in_client_shell', true);

  bool get homeworkOwnerCanAssign => _get('homework.owner_can_assign', true);
  bool get homeworkPartnerCanAssign => _get('homework.partner_can_assign', false);
  bool get homeworkClientCanView => _get('homework.client_can_view', true);
  bool get homeworkShowInPartnerShell => _get('homework.show_in_partner_shell', true);
  bool get homeworkShowInClientShell => _get('homework.show_in_client_shell', true);

  bool get progressClientCanLog => _get('progress.client_can_log', true);
  bool get progressClientCanView => _get('progress.client_can_view', true);
  bool get progressShowInClientShell => _get('progress.show_in_client_shell', true);

  bool get loyaltyClientCanRedeem => _get('loyalty.client_can_redeem', true);
  bool get loyaltyOwnerCanManage => _get('loyalty.owner_can_manage', true);
  bool get loyaltyShowInClientShell => _get('loyalty.show_in_client_shell', true);
  bool get loyaltyShowInOwnerShell => _get('loyalty.show_in_owner_shell', true);

  bool get communityFeedEnabled => _get('community_feed.enabled', true);
  bool get communityFeedOwnerCanPost => _get('community_feed.owner_can_post', true);
  bool get communityFeedPartnerCanPost => _get('community_feed.partner_can_post', true);
  bool get communityFeedClientCanPost => _get('community_feed.client_can_post', true);
  bool get communityFeedShowInPartnerShell => _get('community_feed.show_in_partner_shell', true);
  bool get communityFeedShowInClientShell => _get('community_feed.show_in_client_shell', true);

  bool get chatPartnerCanCreateGroup => _get('chat.partner_can_create_group', false);

  bool get discoverClientTabEnabled => _get('discover.client_tab_enabled', true);

  bool get staffPermissionsOwnerCanManage => _get('staff_permissions.owner_can_manage', true);
}

final featureFlagsProvider = FutureProvider<FeatureFlags>((ref) async {
  final raw = await rootBundle.loadString('assets/config/feature_flags.json');
  final map = jsonDecode(raw) as Map<String, dynamic>;
  return FeatureFlags._(map);
});