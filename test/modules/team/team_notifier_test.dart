// test/modules/team/team_notifier_test.dart
//
// Tests for TeamNotifier — Blueprint Section 16.
// Verifies member loading, invitation, feature toggle, and removal
// against the mock team source.
// Run with: flutter test test/modules/team/team_notifier_test.dart
//
// NOTE: MockTeamSource uses a static in-memory store shared across test runs
// within the same process. Mutation tests use relative assertions (e.g. list
// grows by one, member is gone) rather than exact counts.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';

void main() {
  // ── Helper ─────────────────────────────────────────────────────────────────

  ProviderContainer ownerContainer() {
    final profile = UserProfile(
      userId: 'usr_owner_001',
      businessId: 'biz_mock_001',
      role: 'owner',
      displayName: 'Test Owner',
      joinedAt: DateTime(2025),
      isActive: true,
    );
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => FakeAuthNotifier(profile),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  // ── Build tests ─────────────────────────────────────────────────────────────

  group('TeamNotifier — build', () {
    test('owner receives a non-empty member list', () async {
      final container = ownerContainer();
      final result = await container.read(teamNotifierProvider.future);
      expect(result, isNotEmpty);
      expect(result.first, isA<TeamMemberModel>());
    });

    test('all members belong to the correct business', () async {
      final container = ownerContainer();
      final result = await container.read(teamNotifierProvider.future);
      for (final m in result) {
        expect(m.businessId, equals('biz_mock_001'));
      }
    });

    test('seed data contains partners, staff, and clients', () async {
      final container = ownerContainer();
      final result = await container.read(teamNotifierProvider.future);
      final roles = result.map((m) => m.role).toSet();
      expect(roles, containsAll(['partner', 'staff', 'client']));
    });

    test('partners have a categoryId', () async {
      final container = ownerContainer();
      final result = await container.read(teamNotifierProvider.future);
      final partners = result.where((m) => m.role == 'partner').toList();
      expect(partners, isNotEmpty);
      for (final p in partners) {
        expect(p.categoryId, isNotNull);
      }
    });
  });

  // ── Invite member ─────────────────────────────────────────────────────────────

  group('TeamNotifier — inviteMember', () {
    test('invite staff adds a new member — list grows by one', () async {
      final container = ownerContainer();
      final before = await container.read(teamNotifierProvider.future);

      final member = await container
          .read(teamNotifierProvider.notifier)
          .inviteMember(
            role: 'staff',
            displayName: 'New Staff Member',
            email: 'newstaff@test.com',
          );

      expect(member, isA<TeamMemberModel>());
      expect(member!.role, equals('staff'));
      expect(member.isActive, isTrue);
      expect(member.inviteToken, isNotNull);

      final after = await container.read(teamNotifierProvider.future);
      expect(after.length, equals(before.length + 1));
    });

    test('invite client adds a new client member', () async {
      final container = ownerContainer();
      final before = await container.read(teamNotifierProvider.future);

      final member = await container
          .read(teamNotifierProvider.notifier)
          .inviteMember(
            role: 'client',
            displayName: 'New Client',
          );

      expect(member, isNotNull);
      expect(member!.role, equals('client'));

      final after = await container.read(teamNotifierProvider.future);
      expect(after.length, equals(before.length + 1));
    });

    test('invite partner to an available category succeeds', () async {
      final container = ownerContainer();

      // Use a category not already occupied in the seed data.
      // cat_1 has no partner in the seed (cat_2 and cat_3 are taken).
      final member = await container
          .read(teamNotifierProvider.notifier)
          .inviteMember(
            role: 'partner',
            displayName: 'New Partner',
            categoryId: 'cat_1',
          );

      expect(member, isNotNull);
      expect(member!.categoryId, equals('cat_1'));
    });

    test('invite partner to an occupied category fails with error', () async {
      final container = ownerContainer();

      // cat_2 already has Partner One in the seed data.
      final member = await container
          .read(teamNotifierProvider.notifier)
          .inviteMember(
            role: 'partner',
            displayName: 'Duplicate Partner',
            categoryId: 'cat_2',
          );

      expect(member, isNull);

      final error = container.read(teamActionErrorProvider);
      expect(error, isNotNull);
      expect(error, contains('cat_2'));
    });
  });

  // ── Feature toggle ────────────────────────────────────────────────────────────

  group('TeamNotifier — toggleFeature', () {
    test('toggle updates the feature value for a member', () async {
      final container = ownerContainer();
      final members = await container.read(teamNotifierProvider.future);

      // Use a staff member — they have 'can_view_finance' toggle.
      final staff = members.firstWhere((m) => m.role == 'staff');
      final initialValue = staff.featureToggles['can_view_finance'] ?? false;

      final ok = await container
          .read(teamNotifierProvider.notifier)
          .toggleFeature(
            memberId: staff.userId,
            featureKey: 'can_view_finance',
            value: !initialValue,
          );

      expect(ok, isTrue);

      final after = await container.read(teamNotifierProvider.future);
      final updated = after.firstWhere((m) => m.userId == staff.userId);
      expect(updated.featureToggles['can_view_finance'], equals(!initialValue));
    });
  });

  // ── Remove member ─────────────────────────────────────────────────────────────

  group('TeamNotifier — removeMember', () {
    test('remove deletes the member from the list', () async {
      final container = ownerContainer();

      // Invite a fresh member so we have a clean target to remove
      // without disturbing seeded data other tests may rely on.
      final invited = await container
          .read(teamNotifierProvider.notifier)
          .inviteMember(
            role: 'client',
            displayName: 'Temp Client for Removal',
          );
      expect(invited, isNotNull);

      final before = await container.read(teamNotifierProvider.future);
      expect(before.any((m) => m.userId == invited!.userId), isTrue);

      final ok = await container
          .read(teamNotifierProvider.notifier)
          .removeMember(invited!.userId);

      expect(ok, isTrue);

      final after = await container.read(teamNotifierProvider.future);
      expect(after.any((m) => m.userId == invited.userId), isFalse);
      expect(after.length, equals(before.length - 1));
    });
  });

  // ── Read helpers ──────────────────────────────────────────────────────────────

  group('TeamNotifier — membersForRole', () {
    test('membersForRole returns only the requested role', () async {
      final container = ownerContainer();
      await container.read(teamNotifierProvider.future);

      final partners = container
          .read(teamNotifierProvider.notifier)
          .membersForRole('partner');

      for (final p in partners) {
        expect(p.role, equals('partner'));
      }
      expect(partners, isNotEmpty);
    });
  });
}

// ── Fake auth notifier ────────────────────────────────────────────────────────

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._profile);
  final UserProfile _profile;

  @override
  AuthState build() {
    return AuthAuthenticated(profile: _profile);
  }
}
