// lib/core/utils/icon_lookup.dart
//
// String → IconData lookups used across the app.
//
// These two functions used to be defined separately, in two different
// files, under the exact same name (`iconDataFromString`) — one in
// engine/navigation/app_router.dart (for nav-tab icons) and one in
// engine/auth/onboarding_screen.dart (for industry/job-category icons).
// They happened to never be imported into the same file together, so it
// never surfaced as a compile error — but it was a latent landmine: the
// moment any file needed both, Dart would reject the ambiguous import.
// Consolidated here under distinct names instead.

import 'package:flutter/material.dart';

/// Resolves a nav-tab icon name (from IndustryConfig navigation tabs) to
/// its Material icon. Falls back to a generic circle for unknown names.
IconData navTabIconFromString(String iconName) {
  const map = <String, IconData>{
    'home':                   Icons.home,
    'home_outlined':          Icons.home_outlined,
    'people':                 Icons.people,
    'people_outline':         Icons.people_outline,
    'event':                  Icons.event,
    'event_note':             Icons.event_note,
    'event_note_outlined':    Icons.event_note_outlined,
    'payments':               Icons.payments,
    'payments_outlined':      Icons.payments_outlined,
    'chat':                   Icons.chat,
    'chat_outlined':          Icons.chat_bubble_outline,
    'chat_bubble_outline':    Icons.chat_bubble_outline,
    'notifications':          Icons.notifications,
    'notifications_outlined': Icons.notifications_outlined,
    'handshake':              Icons.handshake,
    'handshake_outlined':     Icons.handshake_outlined,
    'video_library':          Icons.video_library,
    'video_library_outlined': Icons.video_library_outlined,
    'inventory':              Icons.inventory_2,
    'inventory_outlined':     Icons.inventory_2_outlined,
    'gps_fixed':              Icons.gps_fixed,
    'map_outlined':           Icons.map_outlined,
    'star':                   Icons.star,
    'star_outlined':          Icons.star_outline,
    'calendar_month':         Icons.calendar_month,
    'calendar_outlined':      Icons.calendar_month_outlined,
    'table_bar':              Icons.table_bar,
    'settings':               Icons.settings,
    'settings_outlined':      Icons.settings_outlined,
    'dashboard':              Icons.dashboard,
    'dashboard_outlined':     Icons.dashboard_outlined,
    'store':                  Icons.store,
    'store_outlined':         Icons.storefront_outlined,
    'emoji_events':           Icons.emoji_events,
    'assignment':             Icons.assignment,
    'card_giftcard':          Icons.card_giftcard,
    'explore':                Icons.explore,
    'trending_up':            Icons.trending_up,
    'auto_awesome':           Icons.auto_awesome,
  };
  return map[iconName] ?? Icons.circle_outlined;
}

/// Resolves an industry/job-category icon name (used on the onboarding
/// screen's category and job pickers) to its Material icon. Falls back
/// to a generic business icon for unknown names.
IconData industryIconFromString(String iconName) {
  const map = <String, IconData>{
    'self_improvement':   Icons.self_improvement,
    'fitness_center':     Icons.fitness_center,
    'spa':                Icons.spa,
    'air':                Icons.air,
    'psychology':         Icons.psychology,
    'restaurant':         Icons.restaurant,
    'eco':                Icons.eco,
    'accessibility_new':  Icons.accessibility_new,
    'touch_app':          Icons.touch_app,
    'accessibility':      Icons.accessibility,
    'music_note':         Icons.music_note,
    'sports':             Icons.sports,
    'business_center':    Icons.business_center,
  };
  return map[iconName] ?? Icons.business_center;
}
