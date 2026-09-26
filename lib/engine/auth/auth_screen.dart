// lib/engine/auth/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/dev_quick_launch.dart';
import 'package:personal_wellness_trainer/core/utils/validators.dart';
import 'package:personal_wellness_trainer/core/widgets/app_text_field.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/primary_button.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';

// activateLicenseKey / _ActivationDialog / "Activate a Practice Key" removed
// — superseded by the unified redemption flow (signUp(redemptionCode:)),
// reachable here via "Have an invite code? Join here" and from
// MarketingLandingScreen (/get-started). The old path was redundant AND
// broken in real mode (direct profiles insert with a deterministic fake
// UUID that would fail the auth.users FK constraint, no INSERT policy —
// flagged as Critical 4 in the Supabase review, never fixed because the
// new flow was meant to replace it entirely). Found still sitting here,
// reachable, during mock-mode testing of the new flow — removed rather
// than migrated, since it has nothing left to do that the new path
// doesn't already do correctly and securely.

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  bool  _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    ref.read(authNotifierProvider.notifier).clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier)
        .signIn(_emailCtrl.text, _passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState    = ref.watch(authNotifierProvider);
    final isLoading    = authState is AuthLoading;
    final errorMessage = authState is AuthUnauthenticated ? authState.errorMessage : null;
    final appName      = ref.watch(configProvider).valueOrNull?.industry.appName ?? 'Personal Wellness Trainer';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: const DevQuickLaunchButton(),
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
                  _LogoAndHeader(appName: appName),
                  const SizedBox(height: AppSpacing.xxl),
                  _SignInForm(
                    formKey:          _formKey,
                    emailCtrl:        _emailCtrl,
                    passwordCtrl:     _passwordCtrl,
                    obscurePassword:  _obscurePassword,
                    isLoading:        isLoading,
                    errorMessage:     errorMessage,
                    onToggleObscure:  () => setState(() => _obscurePassword = !_obscurePassword),
                    onSignIn:         _signIn,
                    onForgotPassword: () => context.goNamed(RouteNames.forgotPassword),
                    onLanding:        () => context.goNamed(RouteNames.marketingLanding),
                    onInviteCode:     () => context.goNamed(RouteNames.acceptInvitation),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ── Sign-in Form ──────────────────────────────────────────────────────────────

class _SignInForm extends StatelessWidget {
  const _SignInForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.isLoading,
    required this.errorMessage,
    required this.onToggleObscure,
    required this.onSignIn,
    required this.onForgotPassword,
    required this.onLanding,
    required this.onInviteCode,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onToggleObscure;
  final VoidCallback onSignIn;
  final VoidCallback onForgotPassword;
  final VoidCallback onLanding;
  final VoidCallback onInviteCode;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          AppTextField(
            hint: 'you@example.com', label: 'Email',
            controller: emailCtrl,
            validator: AppValidators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.email_outlined,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            hint: 'Your password', label: 'Password',
            controller: passwordCtrl,
            validator: AppValidators.password,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => onSignIn(),
            suffixIcon: IconButton(
              icon: Icon(obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: onToggleObscure,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (errorMessage != null) ...[
            ErrorDisplay(message: errorMessage!, compact: true),
            const SizedBox(height: AppSpacing.md),
          ],
          PrimaryButton(
            label: 'Sign In',
            onPressed: isLoading ? null : onSignIn,
            isLoading: isLoading,
          ),
          const SizedBox(height: AppSpacing.sm),
          _AuthNavigationButtons(
            onForgotPasswordPressed: onForgotPassword,
            onLandingPressed:        onLanding,
            onInviteCodePressed:     onInviteCode,
          ),
        ],
      ),
    );
  }
}

class _LogoAndHeader extends StatelessWidget {
  const _LogoAndHeader({required this.appName});
  final String appName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Icon(
          Icons.settings_rounded,
          size: AppSpacing.iconSizeXxl,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(appName, style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        const Text('Sign in to continue', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      ],
    );
  }
}

class _AuthNavigationButtons extends StatelessWidget {
  const _AuthNavigationButtons({
    required this.onForgotPasswordPressed,
    required this.onLandingPressed,
    required this.onInviteCodePressed,
  });

  final VoidCallback onForgotPasswordPressed;
  final VoidCallback onLandingPressed;
  final VoidCallback onInviteCodePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: onForgotPasswordPressed,
              child: const Text('Forgot password?'),
            ),
            TextButton(
              onPressed: onInviteCodePressed,
              child: const Text('Have an invite code? Join here'),
            ),
          ],
        ),
        TextButton(
          onPressed: onLandingPressed,
          child: const Text('New here? Visit our home page'),
        ),
      ],
    );
  }
}
