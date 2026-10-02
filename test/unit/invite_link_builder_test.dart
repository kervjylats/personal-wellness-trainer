// test/unit/invite_link_builder_test.dart
//
// Round 6/7 — the canonical invite link builder.
//
// This is the single source of truth that replaced three disagreeing
// representations of "the invite" (a bare token, a hardcoded wellpath.app
// URL, and a const string that printed a literal "$token"). These tests
// pin the two behaviours everything else now depends on: a built link
// round-trips back to its own code, and a pasted/scanned link resolves to
// the code it carries.

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/config/buyer_config.dart';
import 'package:personal_wellness_trainer/engine/invites/invite_link_builder.dart';

void main() {
  group('buildInviteUrl', () {
    test('points at the real accept-invitation route with a token param', () {
      final url = InviteLinkBuilder.buildInviteUrl('wlp_000011');

      expect(url, contains('/accept-invitation'));
      expect(url, contains('?${InviteLinkBuilder.tokenParam}=wlp_000011'));
      // The phantom /join route was never registered — an invite link must
      // never point at it again.
      expect(url, isNot(contains('/join')));
    });

    test('is built from the configured base, with no double slash', () {
      final url = InviteLinkBuilder.buildInviteUrl('wlp_000011');

      expect(url, startsWith(BuyerConfig.inviteBaseUrl));
      expect(url, isNot(contains('//accept-invitation')));
    });

    test('carries no leftover pre-rename brand', () {
      final url = InviteLinkBuilder.buildInviteUrl('wlp_000011').toLowerCase();

      expect(url, isNot(contains('wellpath')));
    });
  });

  group('extractCode', () {
    test('passes a bare token through untouched', () {
      expect(InviteLinkBuilder.extractCode('wlp_000011'), 'wlp_000011');
    });

    test('passes an activation key through untouched', () {
      expect(InviteLinkBuilder.extractCode('DEMO-YOGA-001'), 'DEMO-YOGA-001');
    });

    test('pulls the token out of a full shared invite link', () {
      final url = InviteLinkBuilder.buildInviteUrl('wlp_000011');

      expect(InviteLinkBuilder.extractCode(url), 'wlp_000011');
    });

    test('round-trips: what build produces, extract recovers', () {
      for (final token in ['wlp_000001', 'wlp_000012', 'wlp_999999']) {
        expect(
          InviteLinkBuilder.extractCode(
            InviteLinkBuilder.buildInviteUrl(token),
          ),
          token,
          reason: 'round-trip failed for $token',
        );
      }
    });

    test('tolerates surrounding whitespace from a paste or scan', () {
      expect(
        InviteLinkBuilder.extractCode('  wlp_000011 \n'),
        'wlp_000011',
      );
      expect(
        InviteLinkBuilder.extractCode('  ${InviteLinkBuilder.buildInviteUrl('wlp_000011')}  '),
        'wlp_000011',
      );
    });

    test('returns null for nothing usable', () {
      expect(InviteLinkBuilder.extractCode(null), isNull);
      expect(InviteLinkBuilder.extractCode(''), isNull);
      expect(InviteLinkBuilder.extractCode('   '), isNull);
    });

    test('ignores an empty token param rather than returning empty', () {
      expect(
        InviteLinkBuilder.extractCode('https://x.example/accept-invitation?token='),
        isNull,
      );
    });
  });
}