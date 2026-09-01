import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/currency_text.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/core/extensions/string_extensions.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';
import 'package:personal_wellness_trainer/modules/catalog/providers/catalog_notifier.dart';
import 'package:personal_wellness_trainer/modules/media/providers/media_notifier.dart';

class PartnerServicesScreen extends ConsumerWidget {
  const PartnerServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamNotifierProvider);
    final catalogAsync = ref.watch(catalogNotifierProvider);
    final mediaAsync = ref.watch(mediaNotifierProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teamNotifierProvider);
        ref.invalidate(catalogNotifierProvider);
        ref.invalidate(mediaNotifierProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        children: [
          const SizedBox(height: AppSpacing.md),
          _PartnersSection(teamAsync: teamAsync),
          const SizedBox(height: AppSpacing.lg),
          _CatalogSection(catalogAsync: catalogAsync),
          const SizedBox(height: AppSpacing.lg),
          _MediaSection(mediaAsync: mediaAsync),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _PartnersSection extends StatelessWidget {
  final AsyncValue<List<TeamMemberModel>> teamAsync;
  const _PartnersSection({required this.teamAsync});

  @override
  Widget build(BuildContext context) {
    return teamAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
      data: (members) {
        final partners = members.where((m) => m.role == 'partner').toList();
        if (partners.isEmpty) {
          return const _EmptyMessage(
            icon: Icons.people_outline,
            title: 'No partners yet',
            subtitle: 'Check back later!',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Our Partners (${partners.length})',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...partners.map(
              (partner) => Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      partner.displayName.avatarInitials,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(partner.displayName,
                      style: AppTextStyles.bodyMedium),
                  subtitle: partner.categoryId != null
                      ? Text(partner.categoryId!,
                          style: AppTextStyles.caption)
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CatalogSection extends StatelessWidget {
  final AsyncValue catalogAsync;
  const _CatalogSection({required this.catalogAsync});

  @override
  Widget build(BuildContext context) {
    return catalogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
      data: (items) {
        final active = (items as Iterable)
            .where((i) => (i as dynamic).isActive as bool)
            .toList();
        if (active.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Available Services', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            ...active.take(3).map((item) => ListTile(
                  title: Text((item as dynamic).title as String),
                  trailing: CurrencyText(
                    amount: (item as dynamic).price as double,
                    currencySymbol: (item as dynamic).currency as String,
                  ),
                  dense: true,
                )),
          ],
        );
      },
    );
  }
}

class _MediaSection extends StatelessWidget {
  final AsyncValue mediaAsync;
  const _MediaSection({required this.mediaAsync});

  @override
  Widget build(BuildContext context) {
    return mediaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
      data: (items) {
        final public = (items as Iterable)
            .where((i) => (i as dynamic).isPublic as bool)
            .toList();
        if (public.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Content Library', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            ...public.take(3).map((item) => ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text((item as dynamic).title as String),
                  subtitle: Text((item as dynamic).mediaType as String),
                  dense: true,
                )),
          ],
        );
      },
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.grey400),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.bodyMedium),
          Text(subtitle,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.grey600)),
        ],
      ),
    );
  }
}
