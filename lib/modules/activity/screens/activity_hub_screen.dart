// lib/modules/activity/screens/activity_hub_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/formatters.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/data/models/activity_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/permissions/permissions_engine.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/activity/providers/activity_notifier.dart';
import 'package:personal_wellness_trainer/modules/activity/widgets/activity_status_badge.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';
import 'package:personal_wellness_trainer/core/extensions/string_extensions.dart';
import 'package:personal_wellness_trainer/engine/providers/chat_launcher_provider.dart';

// ── Module card definitions ───────────────────────────────────────────────────

class _ModuleDef {
  const _ModuleDef({
    required this.moduleId,
    required this.icon,
    required this.color,
    required this.routeOwner,
    this.routePartner,
    this.routeStaff,
  });
  final String   moduleId;
  final IconData icon;
  final Color    color;
  final String   routeOwner;
  final String?  routePartner;
  final String?  routeStaff;
}

String _moduleLabel(String id) => switch (id) {
      'scheduling'    => 'Schedule',
      'reservations'  => 'Reservations',
      'catalog'       => 'Catalog',
      'inventory'     => 'Inventory',
      'media'         => 'Media',
      'gps'           => 'GPS Tracking',
      'delivery_fees' => 'Delivery Fees',
      'reviews'       => 'Reviews',
      _               => id,
    };

String _moduleSub(String id) => switch (id) {
      'scheduling'    => 'Manage availability',
      'reservations'  => 'Upcoming bookings',
      'catalog'       => 'Products & services',
      'inventory'     => 'Stock levels',
      'media'         => 'Files & content',
      'gps'           => 'Live tracking',
      'delivery_fees' => 'Zones & pricing',
      'reviews'       => 'Customer feedback',
      _               => 'Tap to open',
    };

// ── Screen ────────────────────────────────────────────────────────────────────

class ActivityHubScreen extends ConsumerWidget {
  const ActivityHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final profile  = authState.profile;
    final role     = AppRole.fromString(profile.role);
    final jobConfig = ref.watch(activeJobConfigProvider);
    final engine   = ref.read(permissionsEngineProvider);

    final activityLabel = jobConfig.terminology.activities;
    final singleLabel   = jobConfig.terminology.activity;
    final canCreate     = engine.canCreateActivity(profile);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(activityLabel),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              heroTag: 'activity_hub_fab',
              onPressed: () => unawaited(context.pushNamed(switch (role) {
                AppRole.owner   => RouteNames.ownerActivityCreate,
                AppRole.partner => RouteNames.partnerActivityCreate,
                AppRole.staff   => RouteNames.staffActivityCreate,
                AppRole.client  => RouteNames.clientActivityCreate,
              })),
              tooltip: 'New $singleLabel',
              child: const Icon(Icons.add),
            )
          : null,
      body: _ActivityHubBody(
        profile: profile,
        role: role,
        activityLabel: activityLabel,
        singleLabel: singleLabel,
        engine: engine,
      ),
    );
  }
}

class _ActivityHubBody extends ConsumerWidget {
  const _ActivityHubBody({
    required this.profile,
    required this.role,
    required this.activityLabel,
    required this.singleLabel,
    required this.engine,
  });

  final dynamic  profile;
  final AppRole  role;
  final String   activityLabel;
  final String   singleLabel;
  final dynamic  engine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activitiesAsync = ref.watch(activityNotifierProvider);
    final jobConfig = ref.watch(activeJobConfigProvider);
    final teamAsync = ref.watch(teamNotifierProvider);

    final List<_ModuleDef> kModules = [
      _ModuleDef(
        moduleId: 'scheduling',
        icon: Icons.calendar_today_outlined,
        color: colorScheme.primary,
        routeOwner: RouteNames.schedule,
        routeStaff: RouteNames.schedule,
      ),
      _ModuleDef(
        moduleId: 'reservations',
        icon: Icons.event_available_outlined,
        color: colorScheme.secondary,
        routeOwner: RouteNames.reservationList,
        routePartner: RouteNames.reservationList,
        routeStaff: RouteNames.reservationList,
      ),
      _ModuleDef(
        moduleId: 'catalog',
        icon: Icons.storefront_outlined,
        color: colorScheme.tertiary,
        routeOwner: RouteNames.catalogList,
        routePartner: RouteNames.catalogList,
        routeStaff: RouteNames.catalogList,
      ),
      _ModuleDef(
        moduleId: 'inventory',
        icon: Icons.inventory_2_outlined,
        color: colorScheme.error,
        routeOwner: RouteNames.inventory,
        routeStaff: RouteNames.inventory,
      ),
      _ModuleDef(
        moduleId: 'media',
        icon: Icons.perm_media_outlined,
        color: colorScheme.primary,
        routeOwner: RouteNames.mediaLibrary,
        routePartner: RouteNames.mediaLibrary,
        routeStaff: RouteNames.mediaLibrary,
      ),
      _ModuleDef(
        moduleId: 'gps',
        icon: Icons.location_on_outlined,
        color: colorScheme.secondary,
        routeOwner: RouteNames.gpsTracking,
        routePartner: RouteNames.gpsTracking,
        routeStaff: RouteNames.gpsTracking,
      ),
      _ModuleDef(
        moduleId: 'delivery_fees',
        icon: Icons.local_shipping_outlined,
        color: colorScheme.tertiary,
        routeOwner: RouteNames.deliveryFees,
        routeStaff: RouteNames.staffDeliveryFees,
      ),
      _ModuleDef(
        moduleId: 'reviews',
        icon: Icons.star_outline,
        color: colorScheme.secondary,
        routeOwner: RouteNames.reviewList,
        routePartner: RouteNames.reviewList,
        routeStaff: RouteNames.reviewList,
      ),
    ];

    final activeModules = kModules
        .where((m) => engine.canAccessModule(m.moduleId, profile))
        .toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(activityNotifierProvider),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        children: [
          const SizedBox(height: AppSpacing.md),

          // ── ZONE 2: PARTNERS CO-OP CAROUSEL 🤝 ──
          if (role == AppRole.client)
            teamAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (members) {
                final partners = members.where((m) => m.role == 'partner').toList();
                if (partners.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic wellness-focused heading: e.g. "Explore our Partner Studios"
                    Text(
                      'Explore our ${jobConfig.terminology.partner} Studios', // ◄ Fixed: Modified exactly as requested!
                      style: AppTextStyles.titleMedium.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: partners.length,
                        itemBuilder: (context, index) {
                          final p = partners[index];
                          return Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            child: Card(
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: colorScheme.secondaryContainer,
                                      child: Text(
                                        p.displayName.avatarInitials,
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            p.displayName,
                                            style: AppTextStyles.titleSmall.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (p.categoryId != null)
                                            Text(
                                              p.categoryId!,
                                              style: AppTextStyles.caption.copyWith(color: colorScheme.onSurfaceVariant),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                      color: colorScheme.primary,
                                      onPressed: () => _openDm(context, ref, p),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                );
              },
            ),

          // ── Recent activities list ──────────────────────────────────────
          activitiesAsync.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorDisplay(
              message: 'Could not load $activityLabel.',
              onRetry: () => ref.invalidate(activityNotifierProvider),
            ),
            data: (activities) {
              final recent = activities.take(5).toList();
              if (recent.isEmpty) {
                return _EmptyActivities(
                  singleLabel: singleLabel,
                  role: role,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent $activityLabel',
                      style: AppTextStyles.titleMedium.copyWith(color: colorScheme.onSurface)),
                  const SizedBox(height: AppSpacing.sm),
                  ...recent.map((a) => _ActivityRow(
                        activity: a,
                        role: role,
                      )),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            },
          ),

          // ── Module cards (elegant list tiles) ───────────────────────────
          if (activeModules.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Tools', style: AppTextStyles.titleMedium.copyWith(color: colorScheme.onSurface)),
            const SizedBox(height: AppSpacing.sm),
            ...activeModules.map(
              (m) => Card(
                color: colorScheme.surfaceContainerLow,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    final route = switch (role) {
                      AppRole.owner   => m.routeOwner,
                      AppRole.partner => m.routePartner ?? m.routeOwner,
                      AppRole.staff   => m.routeStaff   ?? m.routeOwner,
                      AppRole.client  => m.routeOwner,
                    };
                    context.pushNamed(route);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: m.color.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(m.icon, size: 22, color: m.color),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _moduleLabel(m.moduleId),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _moduleSub(m.moduleId),
                                style: AppTextStyles.caption.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: colorScheme.onSurfaceVariant.withAlpha(120),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ── Engagement (horizontal chips) ──────────────────────────────
          const SizedBox(height: AppSpacing.xl),
          Text('Engagement', style: AppTextStyles.titleMedium.copyWith(color: colorScheme.onSurface)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CompactEngagementChip(
                  icon: Icons.chat_bubble_outline,
                  color: colorScheme.primary,
                  label: 'Community',
                  onTap: () => context.pushNamed('owner-community-feed'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _CompactEngagementChip(
                  icon: Icons.emoji_events,
                  color: colorScheme.secondary,
                  label: 'Challenges',
                  onTap: () => context.pushNamed('owner-challenges'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _CompactEngagementChip(
                  icon: Icons.assignment,
                  color: colorScheme.tertiary,
                  label: 'Homework',
                  onTap: () => context.pushNamed('owner-homework'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _CompactEngagementChip(
                  icon: Icons.card_giftcard,
                  color: colorScheme.error,
                  label: 'Rewards',
                  onTap: () => context.pushNamed('owner-rewards'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _CompactEngagementChip(
                  icon: Icons.star_outline_rounded,
                  color: colorScheme.secondary,
                  label: 'Reviews',
                  onTap: () => context.pushNamed(RouteNames.reviewList),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Future<void> _openDm(BuildContext context, WidgetRef ref, dynamic partner) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;
    final role = AppRole.fromString(authState.profile.role);

    final conv = await ref.read(chatLauncherProvider).openDirect(
          participantId: partner.userId as String,
          participantName: partner.displayName as String,
        );

    if (conv == null || !context.mounted) return;

    final routeName = switch (role) {
      AppRole.owner   => RouteNames.ownerMessageThread,
      AppRole.partner => RouteNames.partnerMessageThread,
      AppRole.staff   => RouteNames.staffMessageThread,
      AppRole.client  => RouteNames.clientMessageThread,
    };

    await context.pushNamed(routeName, extra: conv);
  }
}

class _EmptyActivities extends StatelessWidget {
  const _EmptyActivities({required this.singleLabel, required this.role});
  final String   singleLabel;
  final AppRole  role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text('No $singleLabel yet',
                style: AppTextStyles.headlineSmall.copyWith(color: theme.colorScheme.onSurface)),
            if (role.isManagement) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tap + to create your first $singleLabel.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.role});
  final ActivityModel activity;
  final AppRole       role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = activity.fields['service_type']?.toString() ??
        activity.fields.values.firstOrNull?.toString() ??
        'Activity';

    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        dense: true,
        leading: ActivityStatusBadge(status: activity.status),
        title: Text(title,
            style: AppTextStyles.bodyMedium.copyWith(color: theme.colorScheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          AppFormatters.dateTime(activity.createdAt),
          style: AppTextStyles.caption.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _CompactEngagementChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _CompactEngagementChip({
    required this.icon, required this.color,
    required this.label, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(80), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}