// lib/core/theme/app_colors.dart
//
// ALL color constants for App Engine.
// NEVER write Color(0xFF...) inline anywhere in the project.
// Every color used in any file comes from this class.
//
// Note: primary/accent are fallback defaults. At runtime, AppTheme.build()
// receives primary_color from industry_config.json and overrides the
// MaterialApp colorScheme. These constants are used as static fallbacks
// and for semantic color names (error, success, etc.) that do not change.

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand Defaults ──────────────────────────────────────────────────────────
  // Fallback values before industry_config.json is loaded.
  // Runtime primary is set via AppTheme.build(primaryColor: ...).
  static const Color primary = Color(0xFF2471A3);
  static const Color accent = Color(0xFF1ABC9C);

  // ── Neutrals ────────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFD5F5E3);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF9E7);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFDECEA);
  static const Color info = Color(0xFF2980B9);
  static const Color infoLight = Color(0xFFD6EAF8);

  // ── Surface & Background ─────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shimmer = Color(0xFFE8E8E8);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ── Text ────────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFF212121);

  // ── Partner Shell — Locked Features ──────────────────────────────────────────
  static const Color lockedOverlay = Color(0xBEF5F5F5);
  static const Color lockedIcon = Color(0xFFBDBDBD);
  static const Color lockedText = Color(0xFFBDBDBD);
  static const Color lockedBorder = Color(0xFFE0E0E0);

  // ── Upgrade Prompt ───────────────────────────────────────────────────────────
  static const Color upgradeBackground = Color(0xFFFFFDE7);
  static const Color upgradeBorder = Color(0xFFFFD54F);
  static const Color upgradeText = Color(0xFF5D4037);
  static const Color upgradeButtonBackground = Color(0xFF5D4037);

  // ── Status Badges ────────────────────────────────────────────────────────────
  static const Color statusActive = Color(0xFF27AE60);
  static const Color statusActiveBackground = Color(0xFFD5F5E3);
  static const Color statusPending = Color(0xFFF39C12);
  static const Color statusPendingBackground = Color(0xFFFEF9E7);
  static const Color statusInactive = Color(0xFF9E9E9E);
  static const Color statusInactiveBackground = Color(0xFFF5F5F5);
  static const Color statusCancelled = Color(0xFFE74C3C);
  static const Color statusCancelledBackground = Color(0xFFFDECEA);

  // ── Module Identity Colors ────────────────────────────────────────────────────
  static const Color moduleScheduling   = Color(0xFF2471A3);
  static const Color moduleReservations = Color(0xFF8E44AD);
  static const Color moduleCatalog      = Color(0xFF27AE60);
  static const Color moduleReviews      = Color(0xFFF39C12);
  static const Color moduleInventory    = Color(0xFFE74C3C);
  static const Color moduleMedia        = Color(0xFF1ABC9C);
  static const Color moduleGps          = Color(0xFFE67E22);
  static const Color moduleDelivery     = Color(0xFF2C3E50);

  // ── Role colors ───────────────────────────────────────────────────────────────
  static const Color rolePartner = Color(0xFF8E44AD);
  static const Color roleStaff   = Color(0xFF27AE60);

  // ── Status Helper ─────────────────────────────────────────────────────────────
  // Single canonical place for activity/reservation/review status → color mapping.
  // Previously duplicated as _statusColor() in activity_dashboard_slots.dart
  // and reservation_list_screen.dart. Use this everywhere instead.
  static Color forStatus(String status) {
    switch (status) {
      case 'completed':
      case 'active':
        return success;
      case 'cancelled':
      case 'rejected':
        return error;
      case 'pending':
      default:
        return warning;
    }
  }
}
