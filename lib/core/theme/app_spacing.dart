// lib/core/theme/app_spacing.dart
//
// ALL spacing, sizing, and radius constants for App Engine.
// NEVER write SizedBox(height: 16) or Padding(all: 8) inline.
// Every spacing value comes from this class.

abstract final class AppSpacing {
  // ── Base Scale (use these for most spacing) ──────────────────────────────────
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // ── Screen Layout ────────────────────────────────────────────────────────────
  static const double screenPaddingH = 16.0;
  static const double screenPaddingV = 24.0;

  // ── Cards ────────────────────────────────────────────────────────────────────
  static const double cardPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double cardElevation = 1.0;
  static const double cardShadowBlur = 4.0;

  // ── Buttons ──────────────────────────────────────────────────────────────────
  static const double buttonRadius = 8.0;
  static const double buttonPaddingH = 24.0;
  static const double buttonPaddingV = 14.0;
  static const double buttonMinHeight = 48.0;
  static const double buttonLoaderSize = 20.0;

  // ── Inputs ───────────────────────────────────────────────────────────────────
  static const double inputRadius = 8.0;
  static const double inputPaddingH = 12.0;
  static const double inputPaddingV = 12.0;
  static const double inputPrefixMinWidth = 56.0;

  // ── Icons ────────────────────────────────────────────────────────────────────
  static const double iconSizeXs = 12.0;
  static const double iconSizeSm = 16.0;
  static const double iconSize = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;
  static const double iconSizeXxl = 64.0;

  // ── Navigation ───────────────────────────────────────────────────────────────
  static const double bottomNavHeight = 64.0;
  static const double appBarHeight = 56.0;

  // ── Dividers ─────────────────────────────────────────────────────────────────
  static const double dividerThickness = 1.0;

  // ── List Items ───────────────────────────────────────────────────────────────
  static const double listItemPaddingH = 16.0;
  static const double listItemPaddingV = 12.0;

  // ── Upgrade Prompt ───────────────────────────────────────────────────────────
  static const double upgradePromptRadius = 12.0;
  static const double upgradePromptPaddingH = 16.0;
  static const double upgradePromptPaddingV = 12.0;

  // ── Avatars ──────────────────────────────────────────────────────────────────
  static const double avatarSizeSm = 32.0;
  static const double avatarSize = 40.0;
  static const double avatarSizeLg = 56.0;
  static const double avatarSizeXl = 80.0;
  static const double avatarRadius = 50.0; // circular

  // ── Badges ───────────────────────────────────────────────────────────────────
  static const double badgePaddingH = 8.0;
  static const double badgePaddingV = 3.0;
  static const double badgeRadius = 20.0;

  // ── Layout Limits ────────────────────────────────────────────────────────────
  static const double maxContentWidth = 600.0;
  static const double sectionSpacing = 32.0;
}
