// integration_test/helpers/test_data.dart
// All constants used across integration tests.

const String kOwnerEmail    = 'owner@test.com';
const String kOwnerPass     = 'Test1234!';
const String kPartnerEmail  = 'partner@test.com';
const String kPartnerPass   = 'Test1234!';
const String kStaffEmail    = 'staff@test.com';
const String kStaffPass     = 'Test1234!';
const String kClientEmail   = 'client@test.com';
const String kClientPass    = 'Test1234!';

const List<(String id, String label)> kAllJobs = [
  ('yoga_studio',        'Yoga Studio'),
  ('pilates_studio',     'Pilates Studio'),
  ('sound_healer',       'Sound Healer'),
  ('reiki_practitioner', 'Reiki Practitioner'),
  ('nutritionist',       'Nutritionist'),
  ('personal_trainer',   'Personal Trainer'),
  ('life_coach',         'Life Coach'),
  ('massage_therapist',  'Massage Therapist'),
  ('meditation_teacher', 'Meditation Teacher'),
  ('dance_instructor',   'Dance Instructor'),
  ('fitness_coach',      'Fitness Coach'),
  ('wellness_coach',     'Wellness Coach'),
  ('naturopath',         'Naturopath'),
  ('acupuncturist',      'Acupuncturist'),
  ('physiotherapist',    'Physiotherapist'),
];

const Duration kShortWait  = Duration(milliseconds: 600);
const Duration kMedWait    = Duration(seconds: 2);
const Duration kLongWait   = Duration(seconds: 5);

const String kTestActivityTitle   = 'Test Session Alpha';
const String kTestCatalogItem     = 'Test Catalog Item';
const String kTestChallengeTitle  = 'Test Challenge';
const String kTestRewardTitle     = 'Test Reward';
const String kTestMessage         = 'Hello automated test';
const String kTestNotes           = 'Automated test notes 1234';
const int    kTestRewardCost      = 50;
const int    kTestChallengeDays   = 7;
