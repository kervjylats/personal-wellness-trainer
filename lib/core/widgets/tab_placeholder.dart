// lib/core/widgets/tab_placeholder.dart
//
// Shared "coming soon" placeholder used by OwnerShell, PartnerShell,
// and StaffShell for tabs that haven't been wired up yet.
// Extracted to remove the 100%-identical _TabPlaceholder class
// that previously lived as a private copy in each shell file.

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          const Text('Coming soon', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
