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
    test('points at the HASH accept-invitation route with a token param', () {
      final url = InviteLinkBuilder.buildInviteUrl('wlp_000011');

      // The app is a hash router — the route (and its query) must live in
      // the fragment. A path-style link would 404 on a static host and
      // never reach the redemption screen at all.
      final uri = Uri.parse(url);
      expect(uri.fragment, startsWith('/accept-invitation'));
      expect(uri.fragment,
          contains('?${InviteLinkBuilder.tokenParam}=wlp_000011'));
      expect(url, isNot(contains('//accept-invitation')));
      // The phantom /join route was never registered — an invite link must
      // never point at it again.
      expect(url, isNot(contains('/join')));
    });

    test('defaults to a live http origin (config blank = wherever the '
        'app is running)', () {
      final url = InviteLinkBuilder.buildInviteUrl('wlp_000011');

      expect(BuyerConfig.inviteBaseUrl, isEmpty,
          reason: 'blank config = use the live origin by default');
      expect(url, startsWith('http'));
      expect(Uri.parse(url).hasAuthority, isTrue);
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

    test('reads a hash-fragment link (the format the app actually '
        'produces)', () {
      // Where a hash router keeps its location: route + query inside #.
      expect(
        InviteLinkBuilder.extractCode(
          'https://x.example/#/accept-invitation?token=wlp_000011',
        ),
        'wlp_000011',
      );
      // …and a bare fragment with no origin at all.
      expect(
        InviteLinkBuilder.extractCode('#/accept-invitation?token=wlp_000011'),
        'wlp_000011',
      );
      expect(
        InviteLinkBuilder.extractCode('/#/accept-invitation?token=wlp_000011'),
        'wlp_000011',
      );
    });

    test('still reads the old path-style link (back-compat for any link '
        'already shared)', () {
      expect(
        InviteLinkBuilder.extractCode(
          'https://x.example/accept-invitation?token=wlp_000011',
        ),
        'wlp_000011',
      );
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
      expect(
        InviteLinkBuilder.extractCode(
          'https://x.example/#/accept-invitation?token=',
        ),
        isNull,
      );
    });
  });
}