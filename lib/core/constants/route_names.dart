// lib/core/constants/route_names.dart
//
// ALL route name strings for App Engine.
// NEVER write a route string inline anywhere in the project.
// Every navigation call uses context.goNamed(RouteNames.x).
// Never use context.go('/raw/path') — named routes only.

abstract final class RouteNames {
  // ── Bootstrap ────────────────────────────────────────────────────────────────
  static const String splash = 'splash';
  static const String error = 'error';

  // ── Authentication ────────────────────────────────────────────────────────────
  static const String login = 'login';
  static const String signup = 'signup';
  static const String forgotPassword = 'forgot-password';
  static const String onboarding = 'onboarding';
  static const String acceptInvitation = 'accept-invitation';

  // ── Settings ──────────────────────────────────────────────────────────────────
  static const String ownerBranding = 'owner-branding';
  static const String ownerBusinessFeatures = 'owner-business-features';
  static const String ownBusiness = 'own-business';

  // Role-prefixed settings routes (GoRouter requires unique names across shells)
  static const String ownerSettingsScreen = 'owner-settings-screen';
  static const String ownerPreferences = 'owner-preferences';
  static const String partnerSettingsScreen = 'partner-settings-screen';
  static const String staffSettingsScreen = 'staff-settings-screen';
  static const String clientSettingsScreen = 'client-settings-screen';

  // ── Owner Shell & Screens ─────────────────────────────────────────────────────
  static const String ownerShell = 'owner-shell';
  static const String ownerDashboard = 'owner-dashboard';
  static const String ownerSettings = 'owner-settings';
  static const String controlPanel = 'control-panel';
  static const String ownerProfile = 'owner-profile';
  static const String ownerNotifications = 'owner-notifications';

  // ── Partner Shell & Screens ───────────────────────────────────────────────────
  static const String partnerShell = 'partner-shell';
  static const String partnerDashboard = 'partner-dashboard';
  static const String partnerSettings = 'partner-settings';
  static const String partnerProfile = 'partner-profile';
  static const String partnerNotifications = 'partner-notifications';

  // ── Staff Shell & Screens ─────────────────────────────────────────────────────
  static const String staffShell = 'staff-shell';
  static const String staffDashboard = 'staff-dashboard';
  static const String staffSettings = 'staff-settings';
  static const String staffProfile = 'staff-profile';
  static const String staffNotifications = 'staff-notifications';

  // ── Client Shell & Screens ────────────────────────────────────────────────────
  static const String clientShell = 'client-shell';
  static const String clientDashboard = 'client-dashboard';
  static const String clientSettings = 'client-settings';
  static const String clientProfile = 'client-profile';
  static const String clientNotifications = 'client-notifications';

  // ── Module: Finance ───────────────────────────────────────────────────────────
  static const String financeOwner = 'finance-owner';
  static const String financePartner = 'finance-partner';
  static const String financeClient = 'finance-client';
  static const String transactionDetail = 'transaction-detail';

  // ── Module: Activity ──────────────────────────────────────────────────────────
  static const String activityList = 'activity-list';
  static const String activityDetail = 'activity-detail';
  static const String activityCreate = 'activity-create';
  static const String activityEdit = 'activity-edit';

  // Role-prefixed route NAMES to avoid global name collisions in GoRouter.
  // Use these when registering routes or navigating from role-specific screens.
  static const String ownerActivityDetail = 'owner-activity-detail';
  static const String ownerActivityCreate = 'owner-activity-create';
  static const String partnerActivityDetail = 'partner-activity-detail';
  static const String partnerActivityCreate = 'partner-activity-create';
  static const String staffActivityDetail = 'staff-activity-detail';
  static const String staffActivityCreate = 'staff-activity-create';
  static const String clientActivityDetail = 'client-activity-detail';
  static const String clientActivityCreate = 'client-activity-create';

  // ── Module: Team / Network ────────────────────────────────────────────────────
  static const String network = 'network';
  static const String memberDetail = 'member-detail';
  static const String inviteMember = 'invite-member';

  static const String ownerMemberDetail = 'owner-member-detail';
  static const String partnerMemberDetail = 'partner-member-detail';
  static const String staffMemberDetail = 'staff-member-detail';
  static const String clientMemberDetail = 'client-member-detail';

  // ── Module: Messaging ─────────────────────────────────────────────────────────
  static const String messageList = 'message-list';
  static const String messageThread = 'message-thread';
  static const String messageGroupCreate = 'message-group-create';
  static const String notifications = 'notifications';

  // Full conversations list, reached from the chat icon in the app bar
  // (parallel to the notification bell → ownerNotifications).
  static const String ownerMessageList = 'owner-message-list';

  static const String ownerMessageThread = 'owner-message-thread';
  static const String partnerMessageThread = 'partner-message-thread';
  static const String staffMessageThread = 'staff-message-thread';
  static const String clientMessageThread = 'client-message-thread';

  static const String ownerMessageGroupCreate = 'owner-message-group-create';
  static const String partnerMessageGroupCreate = 'partner-message-group-create';
  static const String staffMessageGroupCreate = 'staff-message-group-create';
  static const String clientMessageGroupCreate = 'client-message-group-create';

  // ── Module: Agreements ────────────────────────────────────────────────────────
  static const String agreementList = 'agreement-list';
  static const String agreementDetail = 'agreement-detail';
  static const String agreementCreate = 'agreement-create';

  // Role-prefixed agreement detail names (GoRouter requires unique names across shells)
  static const String ownerAgreementDetail = 'owner-agreement-detail';
  static const String partnerAgreementDetail = 'partner-agreement-detail';
  static const String staffAgreementDetail = 'staff-agreement-detail';
  static const String clientAgreementDetail = 'client-agreement-detail';

  // Phase 4b — Partnership Marketplace
  static const String ownerMarketplace = 'owner-marketplace';
  static const String ownerAgreementCreate = 'owner-agreement-create';

  // ── Module: Media ─────────────────────────────────────────────────────────────
  static const String mediaLibrary = 'media-library';
  static const String mediaDetail = 'media-detail';
  static const String mediaUpload = 'media-upload';

  // ── Module: Catalog ───────────────────────────────────────────────────────────
  static const String catalogList = 'catalog-list';
  static const String catalogItemDetail = 'catalog-item-detail';

  // ── Module: GPS ───────────────────────────────────────────────────────────────
  static const String gpsTracking = 'gps-tracking';
  static const String inventory = 'inventory';
  static const String deliveryFees = 'delivery-fees';
  static const String staffDeliveryFees = 'staff-delivery-fees';
  static const String reviewList = 'review-list';

  // ── Module: Scheduling ────────────────────────────────────────────────────────
  static const String schedule = 'schedule';
  static const String availability = 'availability';

  // ── Module: Reservations ──────────────────────────────────────────────────────
  static const String reservationList = 'reservation-list';
  static const String reservationDetail = 'reservation-detail';

  // ── Route Paths ───────────────────────────────────────────────────────────────
  // Raw URL path strings used by:
  //   1. GoRoute(path:) declarations in app_router.dart
  //   2. Redirect logic location comparisons in app_router.dart
  // NEVER write '/owner', '/login', etc. inline anywhere else in the project.
  // Named route constants above are for context.goNamed() — use those for all
  // navigation calls. These path constants are an internal engine concern only.
  static const String rootPath = '/';
  static const String loadingPath = '/loading';
  static const String loginPath = '/login';
  static const String signupPath = '/signup';
  static const String onboardingPath = '/onboarding';
  static const String acceptInvitationPath = '/accept-invitation';
  static const String ownerPath = '/owner';
  static const String partnerPath = '/partner';
  static const String staffPath = '/staff';
  static const String clientPath = '/client';

  // ── Nested route path segments (relative, no leading slash) ──────────────────
  // Used only inside app_router.dart GoRoute(path:) declarations.
  // These are relative to their parent shell route.
  static const String activityDetailPath = 'activity-detail';
  static const String activityCreatePath = 'activity-create';
  static const String memberDetailPath = 'member-detail';
  static const String agreementDetailPath = 'agreement-detail';
  static const String notificationsPath = 'notifications';
  static const String messageThreadPath = 'message-thread';
  static const String messageListPath = 'message-list';
  static const String messageGroupCreatePath = 'message-group-create';
  static const String settingsPath = 'settings';
  static const String profilePath = 'profile';
  static const String controlPanelPath = 'control-panel';
  static const String brandingPath = 'branding';
  static const String businessFeaturesPath = 'business-features';
  static const String preferencesPath = 'preferences';
  static const String ownBusinessPath = 'own-business';
  static const String marketplacePath = 'marketplace';
  static const String agreementCreatePath = 'agreement-create';

  // ── Phase 8 module path segments ──────────────────────────────────────────
  static const String reviewListPath = 'reviews';
  static const String mediaLibraryPath = 'media';
  static const String scheduleListPath = 'schedule';
  static const String catalogListPath = 'catalog';
  static const String inventoryListPath = 'inventory';
  static const String gpsTrackingPath = 'gps-tracking';
  static const String deliveryFeesPath = 'delivery-fees';
  static const String reservationListPath = 'reservations';

  // ── Community Feed ─────────────────────────────────────────────────────────
  static const String communityFeedPath = 'community-feed';

  static const String ownerCommunityFeed = 'owner-community-feed';
  static const String partnerCommunityFeed = 'partner-community-feed';
  static const String staffCommunityFeed = 'staff-community-feed';
  static const String clientCommunityFeed = 'client-community-feed';

  // ── Challenges ─────────────────────────────────────────────────────────────
  static const String challengeDetail = 'challenge-detail';
  static const String ownerChallenges   = 'owner-challenges';
  static const String staffChallenges   = 'staff-challenges';
  static const String clientChallenges  = 'client-challenges';

  static const String ownerHomework     = 'owner-homework';
  static const String ownerRewards      = 'owner-rewards';
}
