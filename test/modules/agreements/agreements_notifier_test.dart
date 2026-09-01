import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/agreement_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/agreements_notifier.dart';
import '../../helpers/fake_config.dart';

void main() {
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
        authNotifierProvider.overrideWith(() => FakeAuthNotifier(profile)),
        ...fakeEngineOverrides,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AgreementsNotifier — build', () {
    test('owner receives a non-empty agreements list', () async {
      final container = ownerContainer();
      final result = await container.read(agreementsNotifierProvider.future);
      expect(result, isNotEmpty);
      expect(result.first, isA<AgreementModel>());
    });

    test('all agreements belong to the correct business', () async {
      final container = ownerContainer();
      final result = await container.read(agreementsNotifierProvider.future);
      for (final a in result) {
        expect(a.businessId, equals('biz_mock_001'));
      }
    });

    test('seed data contains both active and proposed agreements', () async {
      final container = ownerContainer();
      final result = await container.read(agreementsNotifierProvider.future);
      final statuses = result.map((a) => a.status).toSet();
      expect(statuses, containsAll(['active', 'proposed']));
    });
  });

  group('AgreementsNotifier — proposeAgreement', () {
    test('compatible categories adds new proposed agreement', () async {
      final container = ownerContainer();
      final before = await container.read(agreementsNotifierProvider.future);

      final created = await container
          .read(agreementsNotifierProvider.notifier)
          .proposeAgreement(
            ownerCategoryId: 'yoga_studio',
            partnerUserId: 'usr_partner_001',
            partnerCategoryId: 'pilates_studio',
            ownerCommissionPct: 20.0,
            partnerCommissionPct: 80.0,
          );

      expect(created, isA<AgreementModel>());
      expect(created!.status, equals('proposed'));

      final after = await container.read(agreementsNotifierProvider.future);
      expect(after.length, equals(before.length + 1));
    });
  });

  group('AgreementsNotifier — approveAgreement', () {
    test('approve changes status to active', () async {
      final container = ownerContainer();
      final proposed = await container
          .read(agreementsNotifierProvider.notifier)
          .proposeAgreement(
            ownerCategoryId: 'yoga_studio',
            partnerUserId: 'usr_partner_001',
            partnerCategoryId: 'pilates_studio',
            ownerCommissionPct: 30.0,
            partnerCommissionPct: 70.0,
          );
      expect(proposed, isNotNull);

      final ok = await container
          .read(agreementsNotifierProvider.notifier)
          .approveAgreement(proposed!.id);
      expect(ok, isTrue);

      final after = await container.read(agreementsNotifierProvider.future);
      expect(
        after.firstWhere((a) => a.id == proposed.id).status,
        equals('active'),
      );
    });
  });

  group('AgreementsNotifier — declineAgreement', () {
    test('decline changes status to declined', () async {
      final container = ownerContainer();
      final proposed = await container
          .read(agreementsNotifierProvider.notifier)
          .proposeAgreement(
            ownerCategoryId: 'yoga_studio',
            partnerUserId: 'usr_partner_001',
            partnerCategoryId: 'pilates_studio',
            ownerCommissionPct: 25.0,
            partnerCommissionPct: 75.0,
          );
      expect(proposed, isNotNull);

      final ok = await container
          .read(agreementsNotifierProvider.notifier)
          .declineAgreement(proposed!.id);
      expect(ok, isTrue);

      final after = await container.read(agreementsNotifierProvider.future);
      expect(
        after.firstWhere((a) => a.id == proposed.id).status,
        equals('declined'),
      );
    });
  });

  group('AgreementsNotifier — endAgreement', () {
    test('end changes status to ended and sets endedAt', () async {
      final container = ownerContainer();
      final proposed = await container
          .read(agreementsNotifierProvider.notifier)
          .proposeAgreement(
            ownerCategoryId: 'yoga_studio',
            partnerUserId: 'usr_partner_001',
            partnerCategoryId: 'pilates_studio',
            ownerCommissionPct: 40.0,
            partnerCommissionPct: 60.0,
          );
      expect(proposed, isNotNull);

      await container
          .read(agreementsNotifierProvider.notifier)
          .approveAgreement(proposed!.id);

      final ok = await container
          .read(agreementsNotifierProvider.notifier)
          .endAgreement(proposed.id);
      expect(ok, isTrue);

      final after = await container.read(agreementsNotifierProvider.future);
      final updated = after.firstWhere((a) => a.id == proposed.id);
      expect(updated.status, equals('ended'));
      expect(updated.endedAt, isNotNull);
    });
  });

  group('AgreementsNotifier — read helpers', () {
    test('activeAgreements returns only active items', () async {
      final container = ownerContainer();
      await container.read(agreementsNotifierProvider.future);
      final active = container
          .read(agreementsNotifierProvider.notifier)
          .activeAgreements;
      expect(active, isNotEmpty);
      for (final a in active) {
        expect(a.status, equals('active'));
      }
    });

    test('pendingAgreements returns only proposed items', () async {
      final container = ownerContainer();
      await container.read(agreementsNotifierProvider.future);
      final pending = container
          .read(agreementsNotifierProvider.notifier)
          .pendingAgreements;
      expect(pending, isNotEmpty);
      for (final a in pending) {
        expect(a.status, equals('proposed'));
      }
    });
  });
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._profile);
  final UserProfile _profile;

  @override
  AuthState build() => AuthAuthenticated(profile: _profile);
}