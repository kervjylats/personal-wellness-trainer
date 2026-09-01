// lib/modules/settings/screens/profile_screen.dart
//
// Profile screen — all roles. P7-09.
// Lets any user edit their display name, email, phone, and optional photo URL.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/validators.dart';
import 'package:personal_wellness_trainer/core/widgets/app_text_field.dart';
import 'package:personal_wellness_trainer/core/widgets/primary_button.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _photoUrlController;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authNotifierProvider);
    final profile =
        auth is AuthAuthenticated ? auth.profile : null;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _photoUrlController = TextEditingController(text: profile?.photoUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(authNotifierProvider.notifier).updateProfile(
          displayName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          photoUrl: _photoUrlController.text.trim(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final profile = auth is AuthAuthenticated ? auth.profile : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        children: [
          const SizedBox(height: AppSpacing.lg),
          // Avatar placeholder.
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.grey200,
              child: Text(
                profile != null && profile.displayName.isNotEmpty
                    ? profile.displayName[0].toUpperCase()
                    : '?',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            hint: 'Your name',
            label: 'Display Name',
            controller: _nameController,
            validator: AppValidators.required(fieldName: 'Display Name'),
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            hint: 'you @example.com',
            label: 'Email',
            controller: _emailController,
            validator: AppValidators.email,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            hint: '+1 555 000 0000',
            label: 'Phone (optional)',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            hint: 'https://example.com/photo.jpg',
            label: 'Profile Photo URL (optional)',
            controller: _photoUrlController,
            keyboardType: TextInputType.url,
            prefixIcon: Icons.photo_camera_outlined,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Save Profile', onPressed: _save),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
