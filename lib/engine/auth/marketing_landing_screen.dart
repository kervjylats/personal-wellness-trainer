// lib/engine/auth/marketing_landing_screen.dart
//
// The one page a buyer's QR code, personal shared link, or social media
// post should always point to — built to serve three different visitors
// from the same URL, so the buyer never needs to juggle two links:
//   - Someone with no code yet sees the pitch and taps Contact to reach
//     the buyer directly (however BuyerConfig.marketingLandingSettings'
//     contact_url is set — mailto:, WhatsApp, a form, anything a device
//     can open). Payment and handing over a key happen entirely outside
//     the app, on the buyer's own terms.
//   - Someone who already has a code enters it in the SAME single form.
//     One code field handles every way someone gets in — an invite-link
//     token (wlp_..., joining an existing business), an activation key
//     (brand-new Pro business), or a blank field (brand-new Free Owner).
//     Resolution mirrors real mode's server-side handle_new_user()
//     trigger (see mock_auth_source.dart's signUp for the mock twin).
//   - An already-signed-in free Owner browsing this page can upgrade
//     to Pro immediately, using the same upgrade flow as the Settings
//     screen's button (see BuyerConfig.proUpgradeSettings for that
//     button's text — kept as one shared source of copy).
//
// Content and which of the 3 sections show are entirely buyer-configured
// in lib/config/buyer_config.dart — this file has no marketing copy of
// its own to edit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:personal_wellness_trainer/config/buyer_config.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/validators.dart';
import 'package:personal_wellness_trainer/core/widgets/app_text_field.dart';
import 'package:personal_wellness_trainer/core/widgets/primary_button.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';

class MarketingLandingScreen extends ConsumerStatefulWidget {
  const MarketingLandingScreen({super.key});

  @override
  ConsumerState<MarketingLandingScreen> createState() =>
      _MarketingLandingScreenState();
}

class _MarketingLandingScreenState
    extends ConsumerState<MarketingLandingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSaving = false;
  bool _isUpgrading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Live-update the submit button (Activate vs Get started) as the
    // visitor types or clears the code field.
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() => setState(() {});

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final code = _codeController.text.trim();
    setState(() {
      _isSaving = true;
      _error = null;
    });

    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          redemptionCode: code.isEmpty ? null : code,
        );

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthUnauthenticated) {
      setState(() {
        _isSaving = false;
        _error =
            authState.errorMessage ?? 'Could not create your account. Please try again.';
      });
      return;
    }
    // AuthAuthenticated → the router's own redirect logic takes it from
    // here, same as every other successful sign-in in this app.
  }

  Future<void> _upgrade() async {
    setState(() => _isUpgrading = true);
    await ref.read(authNotifierProvider.notifier).upgradeToPremium();
    if (!mounted) return;
    setState(() => _isUpgrading = false);
  }

  Future<void> _openContact() async {
    final configured =
        BuyerConfig.marketingLandingSettings['contact_url'] as String?;
    final url = (configured == null || configured.isEmpty)
        ? 'mailto:${BuyerConfig.supportEmail}'
        : configured;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const settings = BuyerConfig.marketingLandingSettings;
    final showKeyField = settings['show_activation_key_field'] as bool? ?? true;
    final showUpgradeButton = settings['show_upgrade_button'] as bool? ?? true;
    final showContact = settings['show_contact_section'] as bool? ?? true;

    final authState = ref.watch(authNotifierProvider);
    final canUpgrade = showUpgradeButton &&
        authState is AuthAuthenticated &&
        AppRole.fromString(authState.profile.role).isPartner;

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: authState is AuthUnauthenticated
                ? () => context.goNamed(RouteNames.login)
                : null,
            child: const Text('Sign in'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingH,
            vertical: AppSpacing.screenPaddingV,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    settings['headline'] as String? ?? '',
                    style: AppTextStyles.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    settings['subtitle'] as String? ?? '',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (canUpgrade) ...[
                    _UpgradeSection(
                      isUpgrading: _isUpgrading,
                      onUpgrade: _upgrade,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  if (showKeyField) ...[
                    _ActivationKeySection(
                      formKey: _formKey,
                      codeController: _codeController,
                      nameController: _nameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      isSaving: _isSaving,
                      hasCode: _codeController.text.trim().isNotEmpty,
                      error: _error,
                      onSubmit: _submit,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  if (showContact)
                    _ContactSection(
                      buttonLabel:
                          settings['contact_button_label'] as String? ?? 'Contact',
                      onContact: _openContact,
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

class _UpgradeSection extends StatelessWidget {
  const _UpgradeSection({required this.isUpgrading, required this.onUpgrade});
  final bool isUpgrading;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    const proSettings = BuyerConfig.proUpgradeSettings;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            proSettings['subtitle'] as String? ?? '',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: proSettings['button_label'] as String? ?? 'Upgrade to Pro',
            onPressed: isUpgrading ? null : onUpgrade,
            isLoading: isUpgrading,
          ),
        ],
      ),
    );
  }
}

class _ActivationKeySection extends StatelessWidget {
  const _ActivationKeySection({
    required this.formKey,
    required this.codeController,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isSaving,
    required this.hasCode,
    required this.error,
    required this.onSubmit,
    required this.onTogglePassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController codeController;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isSaving;
  final bool hasCode;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hasCode ? 'Activate your code' : 'Create your account',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            hint: 'Activation key or invite code (optional)',
            label: 'Code (optional)',
            controller: codeController,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.vpn_key_outlined,
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(error!, style: AppTextStyles.bodySmall),
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
            hint: 'you@example.com',
            label: 'Email',
            controller: emailController,
            validator: AppValidators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.email_outlined,
            autofillHints: const [AutofillHints.email],
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
            onFieldSubmitted: (_) => onSubmit(),
            suffixIcon: IconButton(
              icon: Icon(obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: onTogglePassword,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: hasCode ? 'Activate' : 'Get started',
            onPressed: isSaving ? null : onSubmit,
            isLoading: isSaving,
          ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.buttonLabel, required this.onContact});
  final String buttonLabel;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onContact,
      icon: const Icon(Icons.mail_outline),
      label: Text(buttonLabel),
    );
  }
}
