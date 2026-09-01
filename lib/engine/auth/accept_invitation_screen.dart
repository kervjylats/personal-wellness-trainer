// lib/engine/auth/accept_invitation_screen.dart
//
// Accept invitation screen. P7-05.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/validators.dart';
import 'package:personal_wellness_trainer/core/widgets/app_text_field.dart';
import 'package:personal_wellness_trainer/core/widgets/primary_button.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/data/repositories/team_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_team_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/engine/invites/invite_link_notifier.dart';

// Mirrors the established pattern in propose_agreement_screen.dart
// (_teamRepoForAgreementsProvider) — reads TeamRepository from the data
// layer directly, without importing the team module.
final _teamRepoForInvitesProvider = Provider<TeamRepository>((ref) {
  if (DataConfig.useMockData) return MockTeamSource();
  throw UnimplementedError('Supabase team source — Phase 10 only.');
});

class AcceptInvitationScreen extends ConsumerStatefulWidget {
  const AcceptInvitationScreen({super.key});

  @override
  ConsumerState<AcceptInvitationScreen> createState() =>
      _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState
    extends ConsumerState<AcceptInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSaving = false;
  bool _accepted = false;
  String? _error;
  String _joinedRole = 'client'; // updated on successful join

  @override
  void dispose() {
    _tokenController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final token = _tokenController.text.trim();
    final result =
        await ref.read(inviteLinkNotifierProvider.notifier).validateToken(token);

    if (!mounted) return;

    switch (result) {
      case TokenInvalid(:final reason):
        setState(() {
          _isSaving = false;
          _error = reason;
        });
        return;

      case TokenValid(:final link):
        try {
          // Creates the real team-member record — the SAME data source
          // the Owner's Network/Team screen reads from, so the new
          // member shows up there immediately, in any panel watching it.
          final member = await ref.read(_teamRepoForInvitesProvider).inviteMember(
                businessId: link.businessId,
                invitedByUserId: link.invitedByUserId,
                role: link.targetRole,
                displayName: _nameController.text.trim(),
                categoryId: link.categoryId,
              );

          final profile = UserProfile(
            userId: member.userId,
            businessId: member.businessId,
            role: member.role,
            displayName: member.displayName,
            joinedAt: member.joinedAt,
            isActive: member.isActive,
            email: member.email,
            categoryId: member.categoryId,
            primaryPartnerId: member.primaryPartnerId,
            featureToggles: member.featureToggles,
          );

          // Marks the invite link as used (so a single-use link can't be
          // redeemed twice) — and only AFTER the team member was
          // successfully created, so a failure above doesn't burn the
          // invite for nothing.
          await ref.read(inviteLinkNotifierProvider.notifier).recordUse(link.id);

          await ref.read(authNotifierProvider.notifier).completeInviteJoin(profile);

          if (!mounted) return;
          setState(() {
            _isSaving = false;
            _accepted = true;
            _joinedRole = link.targetRole;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _isSaving = false;
            _error = 'Could not complete sign-up. Please try again.';
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appName = ref.watch(configProvider).valueOrNull?.industry.appName
        ?? 'App Engine';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: Text(appName)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
              vertical: AppSpacing.screenPaddingV,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
              child: _accepted
                  ? _AcceptedView(appName: appName, joinedRole: _joinedRole)
                  : _InviteFormView(
                      formKey: _formKey,
                      tokenController: _tokenController,
                      nameController: _nameController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      isSaving: _isSaving,
                      error: _error,
                      onAccept: _accept,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      appName: appName,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteFormView extends StatelessWidget {
  const _InviteFormView({
    required this.formKey,
    required this.tokenController,
    required this.nameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isSaving,
    required this.error,
    required this.onAccept,
    required this.onTogglePassword,
    required this.appName,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController tokenController;
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isSaving;
  final String? error;
  final VoidCallback onAccept;
  final VoidCallback onTogglePassword;
  final String appName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Icon(
            Icons.handshake_outlined,
            size: AppSpacing.iconSizeXxl,
            color: colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "You're invited to join $appName",
            style: AppTextStyles.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Enter your invite code to get started',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Real, editable invite token field — paste/type the code shown
          // when an Owner/Partner generates an invite link (e.g. via the
          // QR dialog on the Network screen, where the raw token is also
          // shown as selectable text underneath the QR code).
          AppTextField(
            hint: 'e.g. wlp_000002',
            label: 'Invite Code',
            controller: tokenController,
            validator: AppValidators.required(fieldName: 'Invite Code'),
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.vpn_key_outlined,
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            hint: 'Your full name',
            label: 'Your Name',
            controller: nameController,
            validator: AppValidators.required(fieldName: 'Your Name'),
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            hint: 'Choose a password',
            label: 'Password',
            controller: passwordController,
            validator: AppValidators.password,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline,
            onFieldSubmitted: (_) => onAccept(),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: onTogglePassword,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Accept Invitation',
            onPressed: isSaving ? null : onAccept,
            isLoading: isSaving,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.goNamed(RouteNames.login),
            child: const Text('Already have an account? Sign in'),
          ),
        ],
      ),
    );
  }
}

class _AcceptedView extends StatelessWidget {
  const _AcceptedView({required this.appName, required this.joinedRole});
  final String appName;
  final String joinedRole;

  String get _destinationPath => switch (joinedRole) {
        'owner' => RouteNames.ownerPath,
        'partner' => RouteNames.partnerPath,
        'staff' => RouteNames.staffPath,
        _ => RouteNames.clientPath,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Icon(
          Icons.check_circle_outline,
          size: AppSpacing.iconSizeXxl,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          "You're in!",
          style: AppTextStyles.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your invitation to $appName has been accepted.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
          label: 'Go to Dashboard',
          onPressed: () => context.go(_destinationPath),
        ),
      ],
    );
  }
}