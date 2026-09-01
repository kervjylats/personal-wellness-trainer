// lib/modules/agreements/registry/deal_summary_card.dart
//
// A card summarising a partnership agreement.
// Registered into WidgetRegistry as 'agreements.DealSummaryCard'.
//
// Consumed by:
//   - Finance screen — deal list entries
//   - Dashboard (Phase 6) — active deal count widget
//   - Messaging (Phase 5) — attachment sharing a deal summary
//
// Data keys (all optional — card degrades gracefully if missing):
//   'agreementId'        String  — agreement identifier
//   'partnerName'        String  — display name of the partner
//   'ownerCommissionPct' double  — owner's commission percentage
//   'partnerCommissionPct' double — partner's commission percentage
//   'status'             String  — 'pending' | 'active' | 'declined' | 'ended'

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

class DealSummaryCard extends StatelessWidget {
  const DealSummaryCard({super.key, this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final partnerName        = data?['partnerName']          as String? ?? 'Partner';
    final ownerPct           = data?['ownerCommissionPct']   as double? ?? 0.0;
    final partnerPct         = data?['partnerCommissionPct'] as double? ?? 0.0;
    final status             = data?['status']               as String? ?? 'pending';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.handshake_outlined,
                  size: AppSpacing.iconSize,
                  color: AppColors.grey600,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    partnerName,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (ownerPct > 0)
                  _CommissionChip(
                    label: 'You: ${ownerPct.toStringAsFixed(1)}%',
                  ),
                if (ownerPct > 0 && partnerPct > 0)
                  const SizedBox(width: AppSpacing.xs),
                if (partnerPct > 0)
                  _CommissionChip(
                    label: 'Partner: ${partnerPct.toStringAsFixed(1)}%',
                  ),
                if (ownerPct == 0 && partnerPct == 0)
                  Text(
                    'No commission terms',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.grey400),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active'   => AppColors.success,
      'pending'  => AppColors.warning,
      'declined' => AppColors.error,
      'ended'    => AppColors.grey400,
      _          => AppColors.grey400,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _capitalise(status),
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ── Commission chip ───────────────────────────────────────────────────────────

class _CommissionChip extends StatelessWidget {
  const _CommissionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey600),
      ),
    );
  }
}
