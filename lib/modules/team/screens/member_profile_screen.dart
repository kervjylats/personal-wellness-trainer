// lib/modules/team/screens/member_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/formatters.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/modules/team/screens/staff_permissions_screen.dart';

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({super.key, required this.member});

  final TeamMemberModel member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamNotifierProvider);
    final categories = ref.watch(configProvider).valueOrNull?.industry.categories ?? [];
    final liveMember = teamAsync.valueOrNull?.firstWhere(
          (m) => m.userId == member.userId,
          orElse: () => member,
        ) ??
        member;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(liveMember.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_remove_outlined),
            tooltip: 'Remove member',
            onPressed: () => _confirmRemove(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile header ───────────────────────────────────────────────
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  AppFormatters.initials(liveMember.displayName),
                  style: AppTextStyles.titleLarge.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                liveMember.displayName,
                style: AppTextStyles.titleMedium.copyWith(color: colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                _capitalise(liveMember.role),
                style: AppTextStyles.bodySmall
                    .copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Info rows ────────────────────────────────────────────────────
            const _SectionHeader(title: 'Details'),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              label: 'Status',
              value: liveMember.isActive ? 'Active' : 'Inactive',
              valueColor:
                  liveMember.isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            _InfoRow(
              label: 'Joined',
              value: AppFormatters.date(liveMember.joinedAt),
            ),
            if (liveMember.email != null)
              _InfoRow(label: 'Email', value: liveMember.email!),
            if (liveMember.categoryId != null)
              _InfoRow(
                label: 'Category',
                value: categories
                    .where((c) => c.id == liveMember.categoryId)
                    .map((c) => c.label)
                    .firstOrNull ?? liveMember.categoryId!,
              ),

            const SizedBox(height: AppSpacing.xl),

            // ── Feature toggles ──────────────────────────────────────────────
            const _SectionHeader(title: 'Permissions'),
            const SizedBox(height: AppSpacing.md),
            if (liveMember.role == 'staff')
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StaffPermissionsScreen(member: liveMember),
                        ),
                      );
                    },
                    child: const Text('Manage Permissions'),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'These settings take effect immediately.',
              style: AppTextStyles.labelSmall
                  .copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (liveMember.featureToggles.isEmpty)
              Text(
                'No configurable permissions for this member.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: colorScheme.onSurfaceVariant),
              )
            else
              ...liveMember.featureToggles.entries.map(
                (e) => _FeatureToggleTile(
                  member: liveMember,
                  featureKey: e.key,
                  value: e.value,
                  locked: _isLockedKey(e.key),
                ),
              ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  bool _isLockedKey(String key) =>
      key == 'sees_upgrade_prompt' || key == 'can_view_all_activities';

  void _confirmRemove(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
            'Remove ${member.displayName} from your network? '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(teamNotifierProvider.notifier)
                  .removeMember(member.userId);
              if (success && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ── Feature toggle tile ───────────────────────────────────────────────────────

class _FeatureToggleTile extends ConsumerStatefulWidget {
  const _FeatureToggleTile({
    required this.member,
    required this.featureKey,
    required this.value,
    required this.locked,
  });

  final TeamMemberModel member;
  final String featureKey;
  final bool value;
  final bool locked;

  @override
  ConsumerState<_FeatureToggleTile> createState() =>
      _FeatureToggleTileState();
}

class _FeatureToggleTileState extends ConsumerState<_FeatureToggleTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 0,
      ),
      title: Text(
        _labelFor(widget.featureKey),
        style: AppTextStyles.bodyMedium.copyWith(
          color: widget.locked ? colorScheme.onSurfaceVariant.withAlpha(120) : colorScheme.onSurface,
        ),
      ),
      subtitle: widget.locked
          ? Text(
              'Locked — cannot be changed',
              style: AppTextStyles.labelSmall
                  .copyWith(color: colorScheme.onSurfaceVariant.withAlpha(120)),
            )
          : null,
      value: widget.value,
      onChanged: widget.locked || _busy
          ? null
          : (newValue) async {
              setState(() => _busy = true);
              await ref.read(teamNotifierProvider.notifier).toggleFeature(
                    memberId: widget.member.userId,
                    featureKey: widget.featureKey,
                    value: newValue,
                  );
              if (mounted) setState(() => _busy = false);
            },
    );
  }

  String _labelFor(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceFirst('can ', 'Can ')
        .replaceFirst('sees ', 'Sees ');
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(title, style: AppTextStyles.titleSmall.copyWith(color: theme.colorScheme.onSurface));
  }
}