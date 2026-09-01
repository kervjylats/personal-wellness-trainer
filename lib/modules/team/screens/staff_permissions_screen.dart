import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';

class StaffPermissionsScreen extends ConsumerWidget {
  final TeamMemberModel member;
  const StaffPermissionsScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the live member list to reflect changes immediately
    final teamAsync = ref.watch(teamNotifierProvider);
    final liveMember = teamAsync.valueOrNull
            ?.firstWhere((m) => m.userId == member.userId, orElse: () => member) ??
        member;

    final toggles = liveMember.featureToggles;

    // List of all possible staff permissions
    final permissions = {
      'can_create_activity': 'Create Content',
      'can_edit_activity': 'Edit Content',
      'can_view_finance': 'View Finance',
      'can_manage_clients': 'Manage Clients',
      'can_view_clients': 'View Client List',
      'can_send_messages': 'Send Messages',
      'can_view_all_activities': 'View All Content',
      'can_access_scheduling': 'Access Scheduling',
      'can_access_catalog': 'Access Catalog',
      'can_access_media': 'Access Media Library',
      'can_access_reviews': 'Access Reviews',
      'client_can_message': 'Clients Can Message',
    };

    return Scaffold(
      appBar: AppBar(title: Text('Permissions: ${liveMember.displayName}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'Toggle what ${liveMember.displayName} can access.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...permissions.entries.map((entry) {
            final key = entry.key;
            final label = entry.value;
            final value = toggles[key] ?? false;
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label, style: AppTextStyles.bodyMedium),
              value: value,
              onChanged: (newValue) {
                ref.read(teamNotifierProvider.notifier).toggleFeature(
                      memberId: liveMember.userId,
                      featureKey: key,
                      value: newValue,
                    );
              },
            );
          }),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}