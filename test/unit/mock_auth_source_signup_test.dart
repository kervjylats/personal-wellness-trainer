import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/core/constants/app_constants.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_auth_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<String> signUpWithCode(String? code) async {
    SharedPreferences.setMockInitialValues({});
    final source = MockAuthSource();
    final profile = await source.signUp(
      email: 'test_${DateTime.now().microsecondsSinceEpoch}@test.com',
      password: 'Password1!',
      displayName: 'Test Owner',
      redemptionCode: code,
    );
    return '${profile.role}|${profile.planTier}|${profile.businessName}';
  }

  group('MockAuthSource.signUp redemption-resolution', () {
    test('null code → Free Owner', () async {
      expect(await signUpWithCode(null), 'owner|free|Test Owner');
    });

    test('blank code → Free Owner (not an invalid-key error)', () async {
      expect(await signUpWithCode(''), 'owner|free|Test Owner');
    });

    test('whitespace code → Free Owner', () async {
      expect(await signUpWithCode('   '), 'owner|free|Test Owner');
    });

    test('valid demo activation key → Pro Owner with business', () async {
      final result = await signUpWithCode('DEMO-YOGA-001');
      expect(result, 'owner|premium|Sunrise Yoga');
    });

    test('reused activation key → error', () async {
      await signUpWithCode('DEMO-NUTRITION-001');
      await expectLater(signUpWithCode('DEMO-NUTRITION-001'), throwsException);
    });

    test('invalid activation key → error', () async {
      await expectLater(signUpWithCode('ZZZ-BOGUS-001'), throwsException);
    });

    test('client invite token (wlp_000001) → joins as Client', () async {
      SharedPreferences.setMockInitialValues({});
      final source = MockAuthSource();
      final profile = await source.signUp(
        email: 'test_client_${DateTime.now().microsecondsSinceEpoch}@test.com',
        password: 'Password1!',
        displayName: 'Invited Client',
        redemptionCode: 'wlp_000001',
      );
      expect(profile.role, AppConstants.roleClient);
      expect(profile.businessId, 'biz_mock_001');
      expect(profile.displayName, 'Invited Client');
    });

    test('partner invite token (wlp_000002) → joins as Partner', () async {
      SharedPreferences.setMockInitialValues({});
      final source = MockAuthSource();
      final profile = await source.signUp(
        email: 'test_partner_${DateTime.now().microsecondsSinceEpoch}@test.com',
        password: 'Password1!',
        displayName: 'Invited Partner',
        redemptionCode: 'wlp_000002',
      );
      expect(profile.role, AppConstants.rolePartner);
    });

    test('invite-joined account can sign back in with same email', () async {
      SharedPreferences.setMockInitialValues({});
      final email = 'sign_back_${DateTime.now().microsecondsSinceEpoch}@test.com';
      final source = MockAuthSource();
      final profile = await source.signUp(
        email: email,
        password: 'Password1!',
        displayName: 'Invited Client',
        redemptionCode: 'wlp_000001',
      );

      final source2 = MockAuthSource();
      final restored = await source2.signIn(email, 'Password1!');
      expect(restored.userId, profile.userId);
    });
  });
}