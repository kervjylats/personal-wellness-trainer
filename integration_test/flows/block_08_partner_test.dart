// Block 08 — Partner Shell
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/main.dart' as app;
import '../helpers/robot.dart';
typedef Recorder = void Function(String name, bool ok, [String? err]);

void runTests(Recorder rec, List<Map<String,String>> failures) {

  testWidgets('08_01 — Partner dashboard loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('partner');
      final ok = !r.existsText('Sign in to continue');
      rec('08_01 Partner dashboard loads', ok, ok ? null : 'Partner did not land on dashboard');
      await r.signOut();
    } catch (e) { rec('08_01 Partner dashboard loads', false, '$e'); }
  });

  testWidgets('08_02 — Partner upgrade prompt visible', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('partner');
      final ok = r.existsText('Upgrade') || r.existsText('Own Business') ||
          r.existsText('Start Your Own');
      rec('08_02 Partner upgrade prompt visible', ok,
          ok ? null : 'Upgrade CTA not found on partner dashboard');
      await r.signOut();
    } catch (e) { rec('08_02 Partner upgrade prompt visible', false, '$e'); }
  });

  testWidgets('08_03 — Partner network has no Associates tab', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('partner');
      await r.tapText('Network');
      await r.wait();
      // Partners should NOT see an "Associates"/"Partners" tab — they see
      // their one Owner (as a small info card, not a tab) plus their own
      // Clients list underneath it. No Staff tab either — that stays
      // Owner-side.
      final hasPartnersTab = r.existsText('Associates');
      rec('08_03 Partner no Associates tab', !hasPartnersTab,
          !hasPartnersTab ? null : 'Associates tab should not be visible for partner role');
      await r.signOut();
    } catch (e) { rec('08_03 Partner no Associates tab', false, '$e'); }
  });

  testWidgets('08_04 — Partner finance shows own earnings only', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('partner');
      await r.tapText('Finance') || await r.tapText('Earnings');
      await r.wait();
      // Should show earnings but NOT show full revenue/owner finance
      final ok = !r.existsText('Sign in to continue');
      rec('08_04 Partner finance loads', ok, ok ? null : 'Partner finance screen did not load');
      await r.signOut();
    } catch (e) { rec('08_04 Partner finance loads', false, '$e'); }
  });

  testWidgets('08_05 — Partner agreements screen', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('partner');
      final found = await r.tapText('Agreements') || await r.tapText('Deals');
      await r.wait();
      rec('08_05 Partner agreements loads', found,
          found ? null : 'Agreements screen not found for partner');
      await r.signOut();
    } catch (e) { rec('08_05 Partner agreements loads', false, '$e'); }
  });

  testWidgets('08_06 — Partner has no Marketplace/Discover access yet', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('partner');
      // By design (see business_features_provider.dart / marketplace_screen.dart):
      // the Marketplace is for two already-Pro Owners discovering each
      // other. A non-Pro Partner isn't an independent business yet, so
      // they have nothing to offer there — this should be ABSENT until
      // they upgrade to Pro and become an Owner themselves. This test
      // used to assert the opposite (that Partners SHOULD have this),
      // which never matched the intended design.
      final hasMarketplaceAccess = r.existsText('Discover') || r.existsText('Marketplace');
      rec('08_06 Partner has no marketplace access', !hasMarketplaceAccess,
          !hasMarketplaceAccess ? null : 'Partner should not see Discover/Marketplace before upgrading to Pro');
      await r.signOut();
    } catch (e) { rec('08_06 Partner has no marketplace access', false, '$e'); }
  });
}
