import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/primary_button.dart';
import 'package:personal_wellness_trainer/data/models/challenge_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/challenges/providers/participation_notifier.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  final ChallengeModel challenge;
  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState is AuthAuthenticated ? authState.profile.userId : '';
    final currentUserName = authState is AuthAuthenticated ? authState.profile.displayName : '';
    final participantsAsync = ref.watch(participationNotifierProvider(challenge.id));

    return Scaffold(
      appBar: AppBar(title: Text(challenge.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(challenge.description, style: AppTextStyles.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Text('Duration: ${challenge.durationDays} days', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.xl),

          // Join / Mark Today
          participantsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => const SizedBox.shrink(),
            data: (participants) {
              final myPart = participants.where((p) => p.userId == currentUserId).firstOrNull;
              if (myPart == null) {
                return PrimaryButton(
                  label: 'Join Challenge',
                  onPressed: () => ref
                      .read(participationNotifierProvider(challenge.id).notifier)
                      .join(userName: currentUserName),
                );
              } else {
                final today = DateTime.now();
                final alreadyDoneToday = myPart.lastCompletedDate != null &&
                    myPart.lastCompletedDate!.year == today.year &&
                    myPart.lastCompletedDate!.month == today.month &&
                    myPart.lastCompletedDate!.day == today.day;
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatChip(label: 'My Streak', value: '${myPart.completedDays}'),
                        _StatChip(label: 'Today', value: alreadyDoneToday ? '✅' : '⬜'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: alreadyDoneToday ? 'Already Done Today' : 'Mark Today Complete',
                      onPressed: alreadyDoneToday
                          ? null
                          : () => ref.read(participationNotifierProvider(challenge.id).notifier).markDayComplete(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => ref.read(participationNotifierProvider(challenge.id).notifier).leave(),
                      child: const Text('Leave Challenge', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: AppSpacing.xl),
          const Text('Leaderboard', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          participantsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Could not load leaderboard'),
            data: (participants) {
              if (participants.isEmpty) return const Text('No participants yet.');
              final sorted = [...participants]..sort((a, b) => b.completedDays.compareTo(a.completedDays));
              return Column(
                children: [
                  for (int i = 0; i < sorted.length; i++)
                    ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(sorted[i].userName),
                      trailing: Text('${sorted[i].completedDays} days'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value', style: AppTextStyles.labelLarge),
      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
    );
  }
}