// lib/modules/team/registry/member_card.dart
//
// A compact card that represents a single team member.
// Registered into WidgetRegistry as 'team.MemberCard'.
//
// Consumed by:
//   - Dashboard (Phase 6) — team count / recent members widget
//   - Messaging (Phase 5) — attachment showing member context
//
// Data keys (all optional — card degrades gracefully if missing):
//   'displayName'  String   — member's name
//   'role'         String   — 'owner' | 'partner' | 'staff' | 'client'
//   'categoryId'   String?  — category label for partners
//   'isActive'     bool     — active status indicator
//
// FIX — removed private _initials() helper. Now uses the `avatarInitials`
// getter on String from core/extensions/string_extensions.dart.
// The private helper was 100% identical to copies in marketplace_screen,
// client_dashboard_screen, network_screen, partner_services_screen, and
// client_network_screen — all should be updated the same way.

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/extensions/string_extensions.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

class MemberCard extends StatelessWidget {
  const MemberCard({super.key, this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final displayName = data?['displayName'] as String? ?? 'Unknown';
    final role        = data?['role']        as String? ?? '';
    final categoryId  = data?['categoryId']  as String?;
    final isActive    = data?['isActive']    as bool?   ?? true;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: AppSpacing.avatarSizeSm / 2,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                // FIX: was _initials(displayName) — a private function duplicated
                // verbatim across 6+ files. Now uses the shared extension getter.
                displayName.avatarInitials,
                style: AppTextStyles.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    categoryId != null
                        ? '${role.capitalize()} · $categoryId'
                        : role.capitalize(),
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.grey600),
                  ),
                ],
              ),
            ),
            if (!isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Inactive',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey600),
                ),
              ),
          ],
        ),
      ),
    );
  }
  // FIX: _initials() and _capitalise() removed.
  // _initials  → displayName.avatarInitials  (string_extensions.dart)
  // _capitalise → role.capitalize()          (string_extensions.dart)
}
