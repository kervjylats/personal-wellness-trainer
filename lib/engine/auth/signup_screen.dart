// lib/engine/auth/signup_screen.dart
//
// Owner-only. This is how a brand-new business gets started — someone has
// to be first, so an Owner signing up with no invite is correct, intended
// behavior. Partners and Clients are deliberately NOT offered here: every
// Partner/Client is supposed to arrive via an invite link from an actual
// business (see mock_team_source.dart's _resolveClientOwnerId for why —
// ownership resolves through who directly invited someone, which has no
// meaning for a self-serve signup with no inviter at all). This screen
// used to offer a Client/Partner toggle with no invite context behind it,
// which broke that model; removed rather than built out further, since an
// invite link is the only path either role is meant to use.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/constants/app_constants.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/validators.dart';
import 'package:personal_wellness_trainer/core/widgets/app_text_field.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/primary_button.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    ref.read(authNotifierProvider.notifier).clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
          role: AppConstants.roleOwner,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState    = ref.watch(authNotifierProvider);
    final isLoading    = authState is AuthLoading;
    final errorMessage = authState is AuthUnauthenticated ? authState.errorMessage : null;
    final appName      = ref.watch(configProvider).valueOrNull?.industry.appName
        ?? 'Personal Wellness Trainer';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: BackButton(onPressed: () => context.goNamed(RouteNames.login)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
              vertical:   AppSpacing.screenPaddingV,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SignUpHeader(appName: appName, theme: theme),
                  const SizedBox(height: AppSpacing.xl),
                  _SignUpForm(
                    formKey:          _formKey,
                    nameController:   _nameController,
                    emailController:  _emailController,
                    passwordController: _passwordController,
                    obscurePassword:  _obscurePassword,
                    isLoading:        isLoading,
                    errorMessage:     errorMessage,
                    onToggleObscure:  () => setState(() => _obscurePassword = !_obscurePassword),
                    onSignUp:         _signUp,
                    onBackToLogin:    () => context.goNamed(RouteNames.login),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _JoinExistingBusinessNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader({required this.appName, required this.theme});
  final String appName;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        Icon(Icons.storefront_outlined, size: AppSpacing.iconSizeXxl,
             color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.md),
        Text('Start your practice on $appName', style: AppTextStyles.displayMedium,
             textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        const Text('Create your free Owner account to set up your business',
            style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      ],
    );
  }
}

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.errorMessage,
    required this.onToggleObscure,
    required this.onSignUp,
    required this.onBackToLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onToggleObscure;
  final VoidCallback onSignUp;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          AppTextField(
            hint: 'Your business name', label: 'Display Name',
            controller: nameController,
            validator: AppValidators.required(fieldName: 'Display Name'),
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.person_outline,
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            hint: 'you@example.com', label: 'Email',
            controller: emailController,
            validator: AppValidators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.email_outlined,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            hint: 'At least 6 characters', label: 'Password',
            controller: passwordController,
            validator: AppValidators.password,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => onSignUp(),
            suffixIcon: IconButton(
              icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: onToggleObscure,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (errorMessage != null) ...[
            ErrorDisplay(message: errorMessage!, compact: true),
            const SizedBox(height: AppSpacing.md),
          ],
          PrimaryButton(
            label: 'Create Account',
            onPressed: isLoading ? null : onSignUp,
            isLoading: isLoading,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onBackToLogin,
            child: const Text('Already have an account? Sign in'),
          ),
        ],
      ),
    );
  }
}

class _JoinExistingBusinessNote extends StatelessWidget {
  const _JoinExistingBusinessNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: AppSpacing.iconSize,
               color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Joining as a Partner or Client? You\'ll need an invite link '
              'from your coach or business — ask them to send you one '
              'instead of creating an account here.',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
