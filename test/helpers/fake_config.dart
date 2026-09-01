// test/helpers/fake_config.dart
//
// Shared test helpers for providers that depend on configProvider.
//
// Keep this file in sync with assets/config/industry_config.json
// and assets/config/app_config.json.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/job_theme.dart';
import 'package:personal_wellness_trainer/engine/config/industry_config.dart';
import 'package:personal_wellness_trainer/engine/permissions/permissions_engine.dart';

const appBuildConfig = AppBuildConfig(
  buildName: 'Personal Wellness Trainer – Test Build',
  version: '1.0.0',
  modulesIncluded: ModulesIncluded(
    activity:      true,
    finance:       true,
    team:          true,
    messaging:     true,
    notifications: true,
    agreements:    true,
    media:         true,
    catalog:       true,
    gps:           false,
    deliveryFees:  true,
    scheduling:    true,
    reservations:  true,
    inventory:     true,
    reviews:       true,
  ),
  mediaTypes: MediaTypes(
    video:  true,
    audio:  true,
    pdf:    true,
    images: true,
  ),
  paymentProviders: PaymentProviders(
    stripe: true,
    paypal: false,
    manual: true,
  ),
  ownerHasControlPanel:        true,
  ownerCanInvitePartners:      true,
  ownerCanManageClientContent: true,
);

const List<ConfigCategory> fakeCategories = [
  ConfigCategory(id: 'yoga_studio', label: 'Yoga Studio', group: 'movement'),
  ConfigCategory(id: 'pilates_studio', label: 'Pilates Studio', group: 'movement'),
  ConfigCategory(id: 'strength_coach', label: 'Strength Coach', group: 'movement'),
  ConfigCategory(id: 'gym_coach', label: 'Gym Coach', group: 'movement'),
  ConfigCategory(id: 'meditation_teacher', label: 'Meditation Teacher', group: 'mind_breath'),
  ConfigCategory(id: 'breathwork_facilitator', label: 'Breathwork Facilitator', group: 'mind_breath'),
  ConfigCategory(id: 'life_coach', label: 'Life Coach', group: 'mind_breath'),
  ConfigCategory(id: 'nutritionist', label: 'Nutritionist', group: 'nutrition'),
  ConfigCategory(id: 'herbalist', label: 'Herbalist', group: 'nutrition'),
  ConfigCategory(id: 'ayurveda_consultant', label: 'Ayurveda Consultant', group: 'nutrition'),
  ConfigCategory(id: 'somatic_therapist', label: 'Somatic Therapist', group: 'integrative'),
  ConfigCategory(id: 'eft_tapping_coach', label: 'EFT Tapping Coach', group: 'integrative'),
  ConfigCategory(id: 'fascia_release_coach', label: 'Fascia Release Coach', group: 'integrative'),
  ConfigCategory(id: 'reiki_practitioner', label: 'Reiki Practitioner', group: 'integrative'),
  ConfigCategory(id: 'sound_healer', label: 'Sound Healer', group: 'integrative'),
];

const List<List<String>> fakeCompatibilityMatrix = [
  ["yoga_studio", "pilates_studio"],
  ["yoga_studio", "strength_coach"],
  ["yoga_studio", "gym_coach"],
  ["yoga_studio", "meditation_teacher"],
  ["yoga_studio", "breathwork_facilitator"],
  ["yoga_studio", "life_coach"],
  ["yoga_studio", "nutritionist"],
  ["yoga_studio", "herbalist"],
  ["yoga_studio", "ayurveda_consultant"],
  ["yoga_studio", "somatic_therapist"],
  ["yoga_studio", "eft_tapping_coach"],
  ["yoga_studio", "fascia_release_coach"],
  ["yoga_studio", "reiki_practitioner"],
  ["yoga_studio", "sound_healer"],

  ["pilates_studio", "strength_coach"],
  ["pilates_studio", "gym_coach"],
  ["pilates_studio", "meditation_teacher"],
  ["pilates_studio", "breathwork_facilitator"],
  ["pilates_studio", "life_coach"],
  ["pilates_studio", "nutritionist"],
  ["pilates_studio", "herbalist"],
  ["pilates_studio", "ayurveda_consultant"],
  ["pilates_studio", "somatic_therapist"],
  ["pilates_studio", "eft_tapping_coach"],
  ["pilates_studio", "fascia_release_coach"],
  ["pilates_studio", "reiki_practitioner"],
  ["pilates_studio", "sound_healer"],

  ["strength_coach", "gym_coach"],
  ["strength_coach", "meditation_teacher"],
  ["strength_coach", "breathwork_facilitator"],
  ["strength_coach", "life_coach"],
  ["strength_coach", "nutritionist"],
  ["strength_coach", "herbalist"],
  ["strength_coach", "ayurveda_consultant"],
  ["strength_coach", "somatic_therapist"],
  ["strength_coach", "eft_tapping_coach"],
  ["strength_coach", "fascia_release_coach"],
  ["strength_coach", "reiki_practitioner"],
  ["strength_coach", "sound_healer"],

  ["gym_coach", "meditation_teacher"],
  ["gym_coach", "breathwork_facilitator"],
  ["gym_coach", "life_coach"],
  ["gym_coach", "nutritionist"],
  ["gym_coach", "herbalist"],
  ["gym_coach", "ayurveda_consultant"],
  ["gym_coach", "somatic_therapist"],
  ["gym_coach", "eft_tapping_coach"],
  ["gym_coach", "fascia_release_coach"],
  ["gym_coach", "reiki_practitioner"],
  ["gym_coach", "sound_healer"],

  ["meditation_teacher", "breathwork_facilitator"],
  ["meditation_teacher", "life_coach"],
  ["meditation_teacher", "nutritionist"],
  ["meditation_teacher", "herbalist"],
  ["meditation_teacher", "ayurveda_consultant"],
  ["meditation_teacher", "somatic_therapist"],
  ["meditation_teacher", "eft_tapping_coach"],
  ["meditation_teacher", "fascia_release_coach"],
  ["meditation_teacher", "reiki_practitioner"],
  ["meditation_teacher", "sound_healer"],

  ["breathwork_facilitator", "life_coach"],
  ["breathwork_facilitator", "nutritionist"],
  ["breathwork_facilitator", "herbalist"],
  ["breathwork_facilitator", "ayurveda_consultant"],
  ["breathwork_facilitator", "somatic_therapist"],
  ["breathwork_facilitator", "eft_tapping_coach"],
  ["breathwork_facilitator", "fascia_release_coach"],
  ["breathwork_facilitator", "reiki_practitioner"],
  ["breathwork_facilitator", "sound_healer"],

  ["life_coach", "nutritionist"],
  ["life_coach", "herbalist"],
  ["life_coach", "ayurveda_consultant"],
  ["life_coach", "somatic_therapist"],
  ["life_coach", "eft_tapping_coach"],
  ["life_coach", "fascia_release_coach"],
  ["life_coach", "reiki_practitioner"],
  ["life_coach", "sound_healer"],

  ["nutritionist", "herbalist"],
  ["nutritionist", "ayurveda_consultant"],
  ["nutritionist", "somatic_therapist"],
  ["nutritionist", "eft_tapping_coach"],
  ["nutritionist", "fascia_release_coach"],
  ["nutritionist", "reiki_practitioner"],
  ["nutritionist", "sound_healer"],

  ["herbalist", "ayurveda_consultant"],
  ["herbalist", "somatic_therapist"],
  ["herbalist", "eft_tapping_coach"],
  ["herbalist", "fascia_release_coach"],
  ["herbalist", "reiki_practitioner"],
  ["herbalist", "sound_healer"],

  ["ayurveda_consultant", "somatic_therapist"],
  ["ayurveda_consultant", "eft_tapping_coach"],
  ["ayurveda_consultant", "fascia_release_coach"],
  ["ayurveda_consultant", "reiki_practitioner"],
  ["ayurveda_consultant", "sound_healer"],

  ["somatic_therapist", "eft_tapping_coach"],
  ["somatic_therapist", "fascia_release_coach"],
  ["somatic_therapist", "reiki_practitioner"],
  ["somatic_therapist", "sound_healer"],

  ["eft_tapping_coach", "fascia_release_coach"],
  ["eft_tapping_coach", "reiki_practitioner"],
  ["eft_tapping_coach", "sound_healer"],

  ["fascia_release_coach", "reiki_practitioner"],
  ["fascia_release_coach", "sound_healer"],

  ["reiki_practitioner", "sound_healer"]
];

const industryConfig = IndustryConfig(
  appName:             'Personal Wellness Trainer',
  industryId:          'wellness',
  industryDisplayName: 'Wellness',
  tagline:             'Your journey to whole-body wellbeing',
  primaryColor:        '#4CAF50',
  accentColor:         '#26A69A',
  iconPath:            'assets/images/icon.png',
  terminology: ConfigTerminology(
    owner:      'Practitioner',
    partner:    'Partner',
    staff:      'Team Member',
    client:     'Client',
    activity:   'Session',
    activities: 'Sessions',
    network:    'Network',
    agreement:  'Partnership',
    finance:    'Revenue',
    team:       'Team',
    media:      'Content',
    catalog:    'Shop',
    dashboard:  'Dashboard',
  ),
  modules: ConfigModules(
    activity:      true,
    finance:       true,
    team:          true,
    messaging:     true,
    notifications: true,
    agreements:    true,
    media:         true,
    catalog:       true,
    gps:           false,
    deliveryFees:  false,
    scheduling:    true,
    reservations:  false,
    inventory:     false,
    reviews:       true,
  ),
  navigation: ConfigNavigation(
    tabs: [
      NavTab(id: 'dashboard', icon: 'home_outlined',       label: 'Home'),
      NavTab(id: 'network',   icon: 'people_outline',      label: 'Network'),
      NavTab(id: 'activity',  icon: 'event_note_outlined', label: 'Sessions'),
      NavTab(id: 'finance',   icon: 'payments_outlined',   label: 'Revenue'),
    ],
  ),
  activityFields: [],
  categories: fakeCategories,
  compatibilityMatrix: fakeCompatibilityMatrix,
  payment: ConfigPayment(
    model:           'upfront',
    currencyDefault: r'$',
    commissionType:  'percentage',
    clientPaysVia:   'in_app',
  ),
  permissions: ConfigPermissions(
    staff: {
      'can_create_activity':     PermissionRule(defaultValue: true,  ownerCanToggle: true,  locked: false),
      'can_view_finance':        PermissionRule(defaultValue: false, ownerCanToggle: true,  locked: false),
      'can_manage_clients':      PermissionRule(defaultValue: false, ownerCanToggle: true,  locked: false),
      'can_view_all_activities': PermissionRule(defaultValue: true,  ownerCanToggle: false, locked: false),
    },
    partner: {
      'can_create_agreements': PermissionRule(defaultValue: false, ownerCanToggle: false, locked: true),
      'can_upload_media':      PermissionRule(defaultValue: false, ownerCanToggle: true,  locked: false),
      'can_view_client_list':  PermissionRule(defaultValue: false, ownerCanToggle: true,  locked: false),
      'sees_upgrade_prompt':   PermissionRule(defaultValue: true,  ownerCanToggle: false, locked: true),
    },
    client: {
      'can_book_activity':   PermissionRule(defaultValue: true, ownerCanToggle: false, locked: true),
      'can_view_free_media': PermissionRule(defaultValue: true, ownerCanToggle: false, locked: true),
      'can_purchase_media':  PermissionRule(defaultValue: true, ownerCanToggle: true,  locked: false),
    },
  ),
  upgrade: ConfigUpgrade(
    enabled:     true,
    url:         'https://example.com/upgrade',
    buttonLabel: 'Launch Your Own Practice',
    subtitle:    'Get your own fully branded platform with all features unlocked.',
  ),
  theme: JobTheme.defaults,
  jobCategories: [],
);

const fakeEngineConfig = AppEngineConfig(
  build: appBuildConfig,
  industry: industryConfig,
);

const fakePermissionsEngine = PermissionsEngine(
  config: fakeEngineConfig,
);

final List<Override> fakeEngineOverrides = [
  permissionsEngineProvider.overrideWithValue(fakePermissionsEngine),
];