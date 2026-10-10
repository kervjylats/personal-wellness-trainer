// test/modules/team/invite_category_flow_test.dart
//
// Regression tests for the invite→propose dead-end fixed in Phase B.
//
// The Network invite dialog used to call generateLink() WITHOUT a
// categoryId, so invite-linked associates landed with a NULL category
// on their profile, and the Propose Agreement screen silently refused
// to send any deal for them (its partner-category guard returned with
// no error). The dialog now stamps the inviter's own trade onto the
// link; these tests pin that contract at both ends:
//   1. the dialog → link end (widget), and
//   2. the link → member profile end (the accept-invite chain).
// Run with: flutter test test/modules/team/invite_category_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_team_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/invites/invite_link_notifier.dart';
import 'package:personal_wellness_trainer/modules/invites/screens/qr_invite_dialog.dart';
import 'package:personal_wellness_trainer/modules/team/widgets/invite_dialog.dart';

void main() {
  // ── Helpers ─────────────────────────────────────────────────────────────────

  UserProfile ownerProfile({String? categoryId}) => UserProfile(
        userId: 'usr_invite_owner',
        businessId: 'biz_invite_flow_001',
        role: 'owner',
        displayName: 'Invite Flow Owner',
        joinedAt: DateTime(2025),
        isActive: true,
        businessName: 'Robot Yoga Co',
        categoryId: categoryId,
        selectedCategory: categoryId,
      );

  Future<void> openPartnerInviteDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(ownerProfile(categoryId: 'yoga_studio')),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const InviteDialog(role: 'partner'),
                ),
                child: const Text('open-invite'),
              ),
            ),
          ),
        ),
      ),
    );

    // Bounded pumps, not pumpAndSettle: pumpAndSettle spins for up to 10
    // minutes if any widget in the tree keeps scheduling frames, which
    // turned this test into a silent hang. Each step advances a fixed
    // amount of time, so a real regression fails fast with a line number.
    await tester.tap(find.text('open-invite'));
    await tester.pump(); // begin dialog transition
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Invite Associate'), findsOneWidget);

    await tester.tap(find.text('Generate Link'));
    await tester.pump(); // kick off _generate()
    await tester.pump(const Duration(milliseconds: 100)); // link created
    await tester.pump(const Duration(milliseconds: 350)); // QR dialog up
  }

  // ── 1. Dialog → link ────────────────────────────────────────────────────────

  group('InviteDialog stamps the inviter\'s category on the link', () {
    testWidgets('owner with a trade → generated link carries categoryId',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await openPartnerInviteDialog(tester);

      // Success path: the dialog pops itself and shows the QR/link dialog.
      expect(find.byType(QrInviteDialog), findsOneWidget);

      // The link that was actually created must carry the owner's trade —
      // this is the field the whole invite→propose chain depends on.
      final container =
          ProviderScope.containerOf(tester.element(find.byType(QrInviteDialog)));
      // runAsync: the mock source awaits a real 400ms delay, and inside the
      // test's FakeAsync zone nothing pumps time forward after the pumps
      // above, so a plain await would hang until the test timeout.
      final links = await tester.runAsync(
          () => container.read(inviteLinkNotifierProvider.future));
      expect(links, isNotNull);
      final created = links!
          .where((l) =>
              l.invitedByUserId == 'usr_invite_owner' &&
              l.targetRole == 'partner')
          .toList();
      expect(created, isNotEmpty,
          reason: 'the dialog must have created a partner invite link');
      expect(created.last.categoryId, 'yoga_studio',
          reason: 'link must carry the inviter\'s category, not null');
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  // ── 2. Link → member profile (accept-invite chain) ──────────────────────────
  //
  // Mirrors accept_invitation_screen.dart:_acceptAsInvite — inviteMember()
  // copies link.categoryId onto the member row, and the profile built from
  // that member must keep it. This is what the Propose Agreement dropdown
  // reads to decide whether a deal can be sent at all.

  group('accept-invite chain preserves the category', () {
    test('MockTeamSource.inviteMember stores link.categoryId on the member',
        () async {
      final member = await MockTeamSource().inviteMember(
        businessId: 'biz_invite_flow_001',
        invitedByUserId: 'usr_invite_owner',
        role: 'partner',
        displayName: 'Robot Associate',
        email: 'assoc+category_chain@robot.test',
        categoryId: 'yoga_studio',
      );

      expect(member.categoryId, 'yoga_studio');

      // The profile the accept screen builds from this member (same fields):
      final profile = UserProfile(
        userId: member.userId,
        businessId: member.businessId,
        role: member.role,
        displayName: member.displayName,
        joinedAt: member.joinedAt,
        isActive: member.isActive,
        email: member.email,
        categoryId: member.categoryId,
        primaryPartnerId: member.primaryPartnerId,
        featureToggles: member.featureToggles,
      );

      expect(profile.categoryId, 'yoga_studio',
          reason: 'profile must keep the category so Propose Agreement '
              'can target this associate');
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
