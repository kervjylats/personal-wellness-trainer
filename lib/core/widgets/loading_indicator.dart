// lib/core/widgets/loading_indicator.dart
//
// The ONE loading indicator for App Engine.
// Use LoadingIndicator for inline spinners.
// Use FullScreenLoader for full-page loading states.

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

/// A circular progress indicator sized and coloured consistently.
/// When [color] is null, uses the theme's primary color automatically.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = AppSpacing.iconSizeXl,
    this.color,
    this.strokeWidth = 3.0,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color,
      ),
    );
  }
}

/// Full-screen loading state. Used while async providers are loading
/// (e.g. config loading, initial auth check).
class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({super.key, this.message});

  /// Optional message shown below the spinner.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
