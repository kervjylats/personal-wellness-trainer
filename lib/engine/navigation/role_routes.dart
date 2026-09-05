// lib/engine/navigation/role_routes.dart
//
// Split out of app_router.dart (which had grown to 624 lines) to keep
// the actual router/redirect logic in app_router.dart separate from the
// route *tables* themselves. Nothing here changed — same routes, same
// screens, same QA Console reuse pattern described below.

import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/data/models/agreement_model.dart';
import 'package:personal_wellness_trainer/data/models/conversation_model.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/engine/auth/accept_invitation_screen.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_screen.dart';
import 'package:personal_wellness_trainer/engine/auth/forgot_password_screen.dart';
import 'package:personal_wellness_trainer/engine/auth/onboarding_screen.dart';
import 'package:personal_wellness_trainer/engine/auth/signup_screen.dart';
import 'package:personal_wellness_trainer/engine/shell/client_shell.dart';
import 'package:personal_wellness_trainer/engine/shell/owner_shell.dart';
import 'package:personal_wellness_trainer/engine/shell/partner_shell.dart';
import 'package:personal_wellness_trainer/engine/shell/staff_shell.dart';
import 'package:personal_wellness_trainer/modules/activity/screens/activity_detail_screen.dart';
import 'package:personal_wellness_trainer/modules/activity/screens/create_activity_screen.dart';
import 'package:personal_wellness_trainer/modules/agreements/screens/agreement_detail_screen.dart';
import 'package:personal_wellness_trainer/modules/agreements/screens/marketplace_screen.dart';
import 'package:personal_wellness_trainer/modules/agreements/screens/propose_agreement_screen.dart';
import 'package:personal_wellness_trainer/modules/catalog/screens/catalog_list_screen.dart';
import 'package:personal_wellness_trainer/modules/challenges/screens/challenge_list_screen.dart';
import 'package:personal_wellness_trainer/modules/chat/screens/chat_room_screen.dart';
import 'package:personal_wellness_trainer/modules/chat/screens/conversations_list_screen.dart';
import 'package:personal_wellness_trainer/modules/chat/screens/community_feed_screen.dart';
import 'package:personal_wellness_trainer/modules/chat/screens/create_group_screen.dart';
import 'package:personal_wellness_trainer/modules/delivery_fees/screens/delivery_fees_screen.dart';
import 'package:personal_wellness_trainer/modules/gps/screens/gps_tracking_screen.dart';
import 'package:personal_wellness_trainer/modules/homework/screens/homework_list_screen.dart';
import 'package:personal_wellness_trainer/modules/inventory/screens/inventory_screen.dart';
import 'package:personal_wellness_trainer/modules/loyalty/screens/rewards_screen.dart';
import 'package:personal_wellness_trainer/modules/media/screens/media_library_screen.dart';
import 'package:personal_wellness_trainer/modules/notifications/screens/notifications_list_screen.dart';
import 'package:personal_wellness_trainer/modules/reservations/screens/reservation_list_screen.dart';
import 'package:personal_wellness_trainer/modules/reviews/screens/review_list_screen.dart';
import 'package:personal_wellness_trainer/modules/scheduling/screens/schedule_screen.dart';
import 'package:personal_wellness_trainer/modules/settings/screens/branding_screen.dart';
import 'package:personal_wellness_trainer/modules/settings/screens/business_features_screen.dart';
import 'package:personal_wellness_trainer/modules/settings/screens/own_business_screen.dart';
import 'package:personal_wellness_trainer/modules/settings/screens/profile_screen.dart';
import 'package:personal_wellness_trainer/modules/team/screens/member_profile_screen.dart';

// ── Reusable per-role route tables ───────────────────────────────────────────
//
// Extracted so the SAME route definitions (and ALL their sub-routes — every
// Create/Detail/screen each role can push to) are used both by the main app's
// single global router AND by the QA Console (lib/dev_tools/qa_console_screen.dart),
// which gives each of the 4 role panels its own independent, isolated GoRouter
// instance. Single source of truth — editing a route here updates both places,
// nothing can drift out of sync between "real" navigation and the QA Console.

List<RouteBase> ownerRoutes() => [
      GoRoute(
        path: RouteNames.ownerPath,
        name: RouteNames.ownerShell,
        builder: (_, __) => const OwnerShell(),
        routes: [
          GoRoute(
            path: RouteNames.activityDetailPath,
            name: RouteNames.ownerActivityDetail,
            builder: (_, state) {
              final id = state.extra! as String;
              return ActivityDetailScreen(activityId: id);
            },
          ),
          GoRoute(
            path: RouteNames.activityCreatePath,
            name: RouteNames.ownerActivityCreate,
            builder: (_, __) => const CreateActivityScreen(),
          ),
          GoRoute(
            path: RouteNames.memberDetailPath,
            name: RouteNames.ownerMemberDetail,
            builder: (_, state) {
              final member = state.extra! as TeamMemberModel;
              return MemberProfileScreen(member: member);
            },
          ),
          GoRoute(
            path: RouteNames.agreementDetailPath,
            name: RouteNames.ownerAgreementDetail,
            builder: (_, state) {
              final agreement = state.extra! as AgreementModel;
              return AgreementDetailScreen(agreement: agreement);
            },
          ),
          GoRoute(
            path: RouteNames.marketplacePath,
            name: RouteNames.ownerMarketplace,
            builder: (_, __) => const MarketplaceScreen(),
          ),
          GoRoute(
            // Owner-only, by design: proposing a NEW agreement is an Owner
            // right. A non-Pro Partner can still reach agreement DETAIL
            // (above) to approve/decline one already proposed to them —
            // this route is deliberately absent from partnerRoutes().
            path: RouteNames.agreementCreatePath,
            name: RouteNames.ownerAgreementCreate,
            builder: (_, __) => const ProposeAgreementScreen(),
          ),
          GoRoute(
            path: RouteNames.messageListPath,
            name: RouteNames.ownerMessageList,
            builder: (_, __) => const ConversationsListScreen(),
          ),
          GoRoute(
            path: RouteNames.notificationsPath,
            name: RouteNames.ownerNotifications,
            builder: (_, __) => const NotificationsListScreen(),
          ),
          GoRoute(
            path: RouteNames.messageThreadPath,
            name: RouteNames.ownerMessageThread,
            builder: (_, state) {
              final conv = state.extra! as ConversationModel;
              return ChatRoomScreen(conversation: conv);
            },
          ),
          GoRoute(
            path: RouteNames.messageGroupCreatePath,
            name: RouteNames.ownerMessageGroupCreate,
            builder: (_, __) => const CreateGroupScreen(),
          ),
          GoRoute(
            path: RouteNames.profilePath,
            name: RouteNames.ownerProfile,
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: RouteNames.brandingPath,
            name: RouteNames.ownerBranding,
            builder: (_, __) => const BrandingScreen(),
          ),
          GoRoute(
            path: RouteNames.businessFeaturesPath,
            name: RouteNames.ownerBusinessFeatures,
            builder: (_, __) => const BusinessFeaturesScreen(),
          ),
          GoRoute(
            path: RouteNames.ownBusinessPath,
            name: 'owner-own-business',
            builder: (_, __) => const OwnBusinessScreen(),
          ),
          GoRoute(
            path: RouteNames.reviewListPath,
            name: RouteNames.reviewList,
            builder: (context, state) => const ReviewListScreen(),
          ),
          GoRoute(
            path: RouteNames.mediaLibraryPath,
            name: RouteNames.mediaLibrary,
            builder: (context, state) => const MediaLibraryScreen(),
          ),
          GoRoute(
            path: RouteNames.scheduleListPath,
            name: RouteNames.schedule,
            builder: (context, state) => const ScheduleScreen(),
          ),
          GoRoute(
            path: RouteNames.catalogListPath,
            name: RouteNames.catalogList,
            builder: (context, state) => const CatalogListScreen(),
          ),
          GoRoute(
            path: RouteNames.inventoryListPath,
            name: RouteNames.inventory,
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: RouteNames.gpsTrackingPath,
            name: RouteNames.gpsTracking,
            builder: (context, state) => const GpsTrackingScreen(),
          ),
          GoRoute(
            path: RouteNames.deliveryFeesPath,
            name: RouteNames.deliveryFees,
            builder: (context, state) => const DeliveryFeesScreen(),
          ),
          GoRoute(
            path: RouteNames.reservationListPath,
            name: RouteNames.reservationList,
            builder: (context, state) => const ReservationListScreen(),
          ),
          GoRoute(
            path: RouteNames.communityFeedPath,
            name: RouteNames.ownerCommunityFeed,
            builder: (_, __) => const CommunityFeedScreen(),
          ),
          GoRoute(
            path: 'challenges',
            name: 'owner-challenges',
            builder: (_, __) => const ChallengeListScreen(),
          ),
          GoRoute(
            path: 'homework',
            name: 'owner-homework',
            builder: (_, __) => const HomeworkListScreen(),
          ),
          GoRoute(
            path: 'rewards',
            name: 'owner-rewards',
            builder: (_, __) => const RewardsManageScreen(),
          ),
        ],
      ),
];

List<RouteBase> partnerRoutes() => [
      GoRoute(
        path: RouteNames.partnerPath,
        name: RouteNames.partnerShell,
        builder: (_, __) => const PartnerShell(),
        routes: [
          GoRoute(
            path: RouteNames.activityDetailPath,
            name: RouteNames.partnerActivityDetail,
            builder: (_, state) {
              final id = state.extra! as String;
              return ActivityDetailScreen(activityId: id);
            },
          ),
          GoRoute(
            path: RouteNames.activityCreatePath,
            name: RouteNames.partnerActivityCreate,
            builder: (_, __) => const CreateActivityScreen(),
          ),
          GoRoute(
            path: RouteNames.memberDetailPath,
            name: RouteNames.partnerMemberDetail,
            builder: (_, state) {
              final member = state.extra! as TeamMemberModel;
              return MemberProfileScreen(member: member);
            },
          ),
          GoRoute(
            path: RouteNames.agreementDetailPath,
            name: RouteNames.partnerAgreementDetail,
            builder: (_, state) {
              final agreement = state.extra! as AgreementModel;
              return AgreementDetailScreen(agreement: agreement);
            },
          ),
          GoRoute(
            path: RouteNames.notificationsPath,
            name: RouteNames.partnerNotifications,
            builder: (_, __) => const NotificationsListScreen(),
          ),
          GoRoute(
            path: RouteNames.messageThreadPath,
            name: RouteNames.partnerMessageThread,
            builder: (_, state) {
              final conv = state.extra! as ConversationModel;
              return ChatRoomScreen(conversation: conv);
            },
          ),
          GoRoute(
            path: RouteNames.messageGroupCreatePath,
            name: RouteNames.partnerMessageGroupCreate,
            builder: (_, __) => const CreateGroupScreen(),
          ),
          GoRoute(
            path: RouteNames.profilePath,
            name: RouteNames.partnerProfile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
];

List<RouteBase> staffRoutes() => [
      GoRoute(
        path: RouteNames.staffPath,
        name: RouteNames.staffShell,
        builder: (_, __) => const StaffShell(),
        routes: [
          GoRoute(
            path: RouteNames.activityDetailPath,
            name: RouteNames.staffActivityDetail,
            builder: (_, state) {
              final id = state.extra! as String;
              return ActivityDetailScreen(activityId: id);
            },
          ),
          GoRoute(
            path: RouteNames.activityCreatePath,
            name: RouteNames.staffActivityCreate,
            builder: (_, __) => const CreateActivityScreen(),
          ),
          GoRoute(
            path: RouteNames.memberDetailPath,
            name: RouteNames.staffMemberDetail,
            builder: (_, state) {
              final member = state.extra! as TeamMemberModel;
              return MemberProfileScreen(member: member);
            },
          ),
          GoRoute(
            path: RouteNames.agreementDetailPath,
            name: RouteNames.staffAgreementDetail,
            builder: (_, state) {
              final agreement = state.extra! as AgreementModel;
              return AgreementDetailScreen(agreement: agreement);
            },
          ),
          GoRoute(
            path: RouteNames.notificationsPath,
            name: RouteNames.staffNotifications,
            builder: (_, __) => const NotificationsListScreen(),
          ),
          GoRoute(
            path: RouteNames.messageThreadPath,
            name: RouteNames.staffMessageThread,
            builder: (_, state) {
              final conv = state.extra! as ConversationModel;
              return ChatRoomScreen(conversation: conv);
            },
          ),
          GoRoute(
            path: RouteNames.messageGroupCreatePath,
            name: RouteNames.staffMessageGroupCreate,
            builder: (_, __) => const CreateGroupScreen(),
          ),
          GoRoute(
            path: RouteNames.deliveryFeesPath,
            name: RouteNames.staffDeliveryFees,
            builder: (context, state) => const DeliveryFeesScreen(),
          ),
          GoRoute(
            path: RouteNames.profilePath,
            name: RouteNames.staffProfile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
];

List<RouteBase> clientRoutes() => [
      GoRoute(
        path: RouteNames.clientPath,
        name: RouteNames.clientShell,
        builder: (_, __) => const ClientShell(),
        routes: [
          GoRoute(
            path: RouteNames.activityDetailPath,
            name: RouteNames.clientActivityDetail,
            builder: (_, state) {
              final id = state.extra! as String;
              return ActivityDetailScreen(activityId: id);
            },
          ),
          GoRoute(
            path: RouteNames.activityCreatePath,
            name: RouteNames.clientActivityCreate,
            builder: (_, __) => const CreateActivityScreen(),
          ),
          GoRoute(
            path: RouteNames.memberDetailPath,
            name: RouteNames.clientMemberDetail,
            builder: (_, state) {
              final member = state.extra! as TeamMemberModel;
              return MemberProfileScreen(member: member);
            },
          ),
          GoRoute(
            path: RouteNames.agreementDetailPath,
            name: RouteNames.clientAgreementDetail,
            builder: (_, state) {
              final agreement = state.extra! as AgreementModel;
              return AgreementDetailScreen(agreement: agreement);
            },
          ),
          GoRoute(
            path: RouteNames.notificationsPath,
            name: RouteNames.clientNotifications,
            builder: (_, __) => const NotificationsListScreen(),
          ),
          GoRoute(
            path: RouteNames.messageThreadPath,
            name: RouteNames.clientMessageThread,
            builder: (_, state) {
              final conv = state.extra! as ConversationModel;
              return ChatRoomScreen(conversation: conv);
            },
          ),
          GoRoute(
            path: RouteNames.messageGroupCreatePath,
            name: RouteNames.clientMessageGroupCreate,
            builder: (_, __) => const CreateGroupScreen(),
          ),
          GoRoute(
            path: RouteNames.profilePath,
            name: RouteNames.clientProfile,
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'challenges',
            name: RouteNames.clientChallenges,
            builder: (_, __) => const ChallengeListScreen(),
          ),
        ],
      ),
];

// ── Reusable auth-flow route table ───────────────────────────────────────────
//
// The full sign-in / sign-up / onboarding / invite-accept / own-business
// route set, in one reusable list. Used by the QA Console so every panel
// (including Owner) starts at the real sign-in screen — no pre-loaded
// mock session, no fake data, completely fresh. The QA Console adds this
// PLUS the role-specific shell routes via ownerRoutes() etc., giving each
// panel a self-contained router that covers every possible navigation
// destination the user might reach.
List<RouteBase> authFlowRoutes() => [
  GoRoute(
    path: RouteNames.loginPath,
    name: RouteNames.login,
    builder: (_, __) => const AuthScreen(),
  ),
  GoRoute(
    path: RouteNames.signupPath,
    name: RouteNames.signup,
    builder: (_, __) => const SignupScreen(),
  ),
  GoRoute(
    path: '/forgot-password',
    name: RouteNames.forgotPassword,
    builder: (_, __) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: RouteNames.onboardingPath,
    name: RouteNames.onboarding,
    builder: (_, __) => const OnboardingScreen(),
  ),
  GoRoute(
    path: RouteNames.acceptInvitationPath,
    name: RouteNames.acceptInvitation,
    builder: (_, __) => const AcceptInvitationScreen(),
  ),
  GoRoute(
    path: '/own-business',
    name: RouteNames.ownBusiness,
    builder: (_, __) => const OwnBusinessScreen(),
  ),
];
