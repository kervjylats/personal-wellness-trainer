// lib/core/theme/app_text_styles.dart
//
// ALL text styles for App Engine.
// NEVER write TextStyle(...) inline in any screen or widget file.
// Every text style comes from this class.
//
// Naming convention: [category][Size]
// Categories: display, headline, title, body, label, caption + specialised sets.
//
// On-dark variants (e.g. headlineMediumOnDark) are used when text appears
// on a colored or dark background. They mirror their base style but with
// white text.

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';

abstract final class AppTextStyles {
  // ── Display ─────────────────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // ── Headlines ────────────────────────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ── Titles ───────────────────────────────────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  // ── Body ─────────────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // ── Labels ───────────────────────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 1.0,
    color: AppColors.textSecondary,
  );

  // ── Caption ───────────────────────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // ── Buttons ───────────────────────────────────────────────────────────────────
  // Color is intentionally absent — the button's foreground color from the
  // colorScheme determines text color at runtime.
  static const TextStyle buttonText = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.3,
  );

  // ── Currency / Amounts ────────────────────────────────────────────────────────
  static const TextStyle currencyLarge = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle currencyMedium = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle currencySmall = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // ── Inputs ────────────────────────────────────────────────────────────────────
  static const TextStyle inputText = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle hintText = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textDisabled,
  );

  // ── Semantic ──────────────────────────────────────────────────────────────────
  static const TextStyle errorText = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.error,
  );

  static const TextStyle successText = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.success,
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primary,
  );

  // ── On-Dark Variants ──────────────────────────────────────────────────────────
  // Use when text appears on primary-colored or dark backgrounds.
  static const TextStyle headlineMediumOnDark = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textOnDark,
  );

  static const TextStyle titleLargeOnDark = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textOnDark,
  );

  static const TextStyle bodyMediumOnDark = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textOnDark,
  );

  static const TextStyle bodySmallOnDark = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textOnDark,
  );

  // ── Upgrade Prompt ────────────────────────────────────────────────────────────
  // Pre-defined styles for the always-visible partner upgrade prompt.
  // These avoid .copyWith() calls in the widget file.
  static const TextStyle upgradeTitle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.upgradeText,
  );

  static const TextStyle upgradeSubtitle = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.upgradeText,
  );

  static const TextStyle upgradeButtonLabel = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
    color: AppColors.white,
  );

  // ── Status Badges ─────────────────────────────────────────────────────────────
  static const TextStyle badgeLabel = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.3,
  );

  // ── Destructive Actions ───────────────────────────────────────────────────────
  // For destructive list tile titles (Sign Out, Delete, Remove).
  // Overrides only the color — all other properties inherit from the theme.
  // Used instead of inline TextStyle(color: AppColors.error) in shell files.
  static const TextStyle listTileDestructive = TextStyle(
    color: AppColors.error,
  );
}
