// lib/core/theme/app_theme.dart
//
// Builds the Material 3 ThemeData for App Engine.
//
// Usage:
//   AppTheme.build(primaryColor: Color(0xFF2471A3))
//   AppTheme.build(primaryColor: Color(0xFF4CAF50), jobTheme: jobConfig.theme)

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/theme/job_theme.dart';

abstract final class AppTheme {
  /// Builds a light [ThemeData] using the given [primaryColor] and
  /// optional [jobTheme] for per-job visual personality.
  static ThemeData build({
    required Color primaryColor,
    JobTheme jobTheme = JobTheme.defaults,
  }) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    // Resolves the TextTheme from locally bundled font assets
    final textTheme = _textThemeFor(jobTheme.fontPersonality);

    final density = switch (jobTheme.spacingPreset) {
      SpacingPreset.compact  => VisualDensity.compact,
      SpacingPreset.relaxed  => VisualDensity.comfortable,
      SpacingPreset.standard => VisualDensity.standard,
    };

    final appBarBg = jobTheme.appBarStyle == AppBarStyle.colored
        ? primaryColor
        : AppColors.surface;
    final appBarFg = jobTheme.appBarStyle == AppBarStyle.colored
        ? AppColors.textOnPrimary
        : AppColors.textPrimary;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      visualDensity: density,

      // ── AppBar ───────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: appBarFg),
        iconTheme: IconThemeData(
          color: appBarFg,
          size: AppSpacing.iconSize,
        ),
        actionsIconTheme: IconThemeData(
          color: appBarFg,
          size: AppSpacing.iconSize,
        ),
      ),

      // ── Cards ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: AppSpacing.cardElevation,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(jobTheme.cardRadius),
          ),
        ),
      ),

      // ── Inputs ───────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inputPaddingH,
          vertical: AppSpacing.inputPaddingV,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(jobTheme.inputRadius),
          ),
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(jobTheme.inputRadius),
          ),
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(jobTheme.inputRadius),
          ),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(jobTheme.inputRadius),
          ),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(jobTheme.inputRadius),
          ),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTextStyles.hintText,
        labelStyle: AppTextStyles.labelMedium,
        errorStyle: AppTextStyles.errorText,
        errorMaxLines: 2,
      ),

      // ── Filled Buttons (primary action) ──────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(double.infinity, AppSpacing.buttonMinHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.buttonPaddingH,
              vertical: AppSpacing.buttonPaddingV,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(jobTheme.buttonRadius),
              ),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(AppTextStyles.buttonText),
        ),
      ),

      // ── Outlined Buttons ─────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(double.infinity, AppSpacing.buttonMinHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.buttonPaddingH,
              vertical: AppSpacing.buttonPaddingV,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(jobTheme.buttonRadius),
              ),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(AppTextStyles.buttonText),
        ),
      ),

      // ── Text Buttons ─────────────────────────────────────────────────────────
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          textStyle: WidgetStatePropertyAll(AppTextStyles.labelLarge),
        ),
      ),

      // ── Navigation Bar (Material 3) ───────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            jobTheme.navBarColored ? primaryColor : AppColors.surface,
        elevation: 3,
        height: AppSpacing.bottomNavHeight,
        indicatorColor: jobTheme.navBarColored
            ? AppColors.white.withAlpha(51) // Equivalent to withValues(alpha: 0.2)
            : colorScheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.labelSmall.copyWith(
            color: jobTheme.navBarColored
                ? AppColors.textOnPrimary
                : AppColors.textPrimary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = jobTheme.navBarColored
              ? AppColors.textOnPrimary
              : AppColors.textPrimary;
          return IconThemeData(color: color);
        }),
      ),

      // ── Divider ───────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: AppSpacing.dividerThickness,
        space: AppSpacing.dividerThickness,
      ),

      // ── Snack Bar ─────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.grey900,
        contentTextStyle: AppTextStyles.bodyMediumOnDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
      ),

      // ── List Tile ─────────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.listItemPaddingH,
          vertical: AppSpacing.listItemPaddingV,
        ),
      ),

      // ── Icon Theme ────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppSpacing.iconSize,
      ),
    );
  }

  /// Resolves the TextTheme based on local font assets.
  static TextTheme _textThemeFor(FontPersonality personality) {
    const TextTheme base = TextTheme(
      displayLarge:  AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge:    AppTextStyles.titleLarge,
      titleMedium:   AppTextStyles.titleMedium,
      titleSmall:    AppTextStyles.titleSmall,
      bodyLarge:     AppTextStyles.bodyLarge,
      bodyMedium:    AppTextStyles.bodyMedium,
      bodySmall:     AppTextStyles.bodySmall,
      labelLarge:    AppTextStyles.labelLarge,
      labelMedium:   AppTextStyles.labelMedium,
      labelSmall:    AppTextStyles.labelSmall,
    );

    // Map your font personalities to the locally compiled .ttf assets!
    return switch (personality) {
      FontPersonality.rounded => base.apply(fontFamily: 'Nunito'),
      _                       => base.apply(fontFamily: 'Inter'),
    };
  }

  static ThemeData get fallback => build(primaryColor: AppColors.primary);
}