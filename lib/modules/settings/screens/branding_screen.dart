// lib/modules/settings/screens/branding_screen.dart
//
// Branding settings screen. P7-08. Owner only.
// Changes here update BrandingOverrideNotifier, which main.dart watches.
// ThemeData and app title rebuild immediately — visible instantly.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/validators.dart';
import 'package:personal_wellness_trainer/core/widgets/app_text_field.dart';
import 'package:personal_wellness_trainer/core/widgets/primary_button.dart';
import 'package:personal_wellness_trainer/engine/config/branding_override_notifier.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';

// Preset brand colors.
const List<_SwatchEntry> _kSwatches = [
  _SwatchEntry('#2471A3', 'Ocean Blue'),
  _SwatchEntry('#1ABC9C', 'Teal'),
  _SwatchEntry('#8E44AD', 'Violet'),
  _SwatchEntry('#E74C3C', 'Crimson'),
  _SwatchEntry('#E67E22', 'Amber'),
  _SwatchEntry('#27AE60', 'Forest'),
  _SwatchEntry('#2C3E50', 'Midnight'),
  _SwatchEntry('#C0392B', 'Ruby'),
  _SwatchEntry('#16A085', 'Emerald'),
  _SwatchEntry('#D35400', 'Pumpkin'),
];

class BrandingScreen extends ConsumerStatefulWidget {
  const BrandingScreen({super.key});

  @override
  ConsumerState<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends ConsumerState<BrandingScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _currencyController;

  @override
  void initState() {
    super.initState();
    final config = ref.read(configProvider).valueOrNull;
    final branding = ref.read(brandingOverrideProvider);
    _nameController = TextEditingController(
      text: branding.businessName ?? config?.industry.appName ?? '',
    );
    _currencyController = TextEditingController(
      text: branding.currency ?? config?.industry.payment.currencyDefault ?? r'$',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _save() {
    final notifier = ref.read(brandingOverrideProvider.notifier);
    notifier.updateBusinessName(_nameController.text);
    notifier.updateCurrency(_currencyController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Branding updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingOverrideProvider);
    final config = ref.watch(configProvider).valueOrNull;
    final currentHex =
        branding.primaryColorHex ?? config?.industry.primaryColor ?? '#2471A3';

    return Scaffold(
      appBar: AppBar(title: const Text('Branding')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        children: [
          const SizedBox(height: AppSpacing.sm),
          const Text('Business Name', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            hint: 'Your business or app name',
            label: 'Business Name',
            controller: _nameController,
            validator: AppValidators.required(fieldName: 'Business Name'),
            prefixIcon: Icons.storefront_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Currency Symbol', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            hint: r'$',
            label: 'Currency',
            controller: _currencyController,
            prefixIcon: Icons.attach_money_outlined,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Brand Colour', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _kSwatches
                .map((s) => _Swatch(
                      hex: s.hex,
                      label: s.label,
                      isSelected: currentHex == s.hex,
                      onTap: () => ref
                          .read(brandingOverrideProvider.notifier)
                          .updatePrimaryColor(s.hex),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Save Changes', onPressed: _save),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () {
              ref.read(brandingOverrideProvider.notifier).reset();
              final config2 = ref.read(configProvider).valueOrNull;
              _nameController.text = config2?.industry.appName ?? '';
              _currencyController.text =
                  config2?.industry.payment.currencyDefault ?? r'$';
            },
            child: const Text('Reset to Defaults'),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.hex,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String hex;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _color {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: _color.withValues(alpha: 0.5), blurRadius: 8)]
                : null,
          ),
          child: isSelected
              ? const Icon(Icons.check, color: AppColors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}

class _SwatchEntry {
  const _SwatchEntry(this.hex, this.label);
  final String hex;
  final String label;
}
