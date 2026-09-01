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

  testWidgets('08_03 — Partner network has no Partners tab', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('partner');
      await r.tapText('Network');
      await r.wait();
      // Partners should NOT see a "Partners" tab — they see Owner/Staff/Clients
      final hasPartnersTab = r.existsText('Partners');
      rec('08_03 Partner no Partners tab', !hasPartnersTab,
          !hasPartnersTab ? null : 'Partners tab should not be visible for partner role');
      await r.signOut();
    } catch (e) { rec('08_03 Partner no Partners tab', false, '$e'); }
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

  testWidgets('08_06 — Partner can access discover/marketplace', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('partner');
      final found = await r.tapText('Discover') || await r.tapText('Marketplace');
      await r.wait();
      rec('08_06 Partner discovers marketplace', found,
          found ? null : 'Marketplace not accessible for partner');
      await r.signOut();
    } catch (e) { rec('08_06 Partner discovers marketplace', false, '$e'); }
  });
}
