// lib/engine/auth/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  
  // Set default signup role as 'client'
  String _selectedRole = 'client';

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
          role: _selectedRole, // ◄ Passes 'client' or 'partner' dynamically
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
                  _RoleSelector(
                    selectedRole: _selectedRole,
                    onChanged: (role) => setState(() => _selectedRole = role),
                  ),
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
        Icon(Icons.person_add_outlined, size: AppSpacing.iconSizeXxl,
             color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.md),
        Text('Join $appName', style: AppTextStyles.displayMedium,
             textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        const Text('Create your free account to get started',
            style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selectedRole, required this.onChanged});
  final String selectedRole;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'client',  label: Text('Join as Client'),  icon: Icon(Icons.person_outline)),
          ButtonSegment(value: 'partner', label: Text('Join as Partner'), icon: Icon(Icons.handshake_outlined)),
        ],
        selected: {selectedRole},
        onSelectionChanged: (val) => onChanged(val.first),
      ),
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
            hint: 'Your name or business name', label: 'Display Name',
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