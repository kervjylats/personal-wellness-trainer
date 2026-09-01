// Block 09 — Client Shell
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/main.dart' as app;
import '../helpers/robot.dart';
typedef Recorder = void Function(String name, bool ok, [String? err]);

void runTests(Recorder rec, List<Map<String,String>> failures) {

  testWidgets('09_01 — Client dashboard loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('client');
      final ok = !r.existsText('Sign in to continue');
      rec('09_01 Client dashboard loads', ok, ok ? null : 'Client did not land on dashboard');
      await r.signOut();
    } catch (e) { rec('09_01 Client dashboard loads', false, '$e'); }
  });

  testWidgets('09_02 — Client loyalty/rewards screen', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('client');
      final found = await r.tapText('Rewards') || await r.tapText('Loyalty') ||
          await r.tapText('Points');
      await r.wait();
      rec('09_02 Client loyalty screen', found,
          found ? null : 'Client loyalty screen not found');
      await r.signOut();
    } catch (e) { rec('09_02 Client loyalty screen', false, '$e'); }
  });

  testWidgets('09_03 — Client homework screen', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('client');
      final found = await r.tapText('Homework') || await r.tapText('Assignments');
      await r.wait();
      rec('09_03 Client homework screen', found,
          found ? null : 'Homework screen not found for client');
      await r.signOut();
    } catch (e) { rec('09_03 Client homework screen', false, '$e'); }
  });

  testWidgets('09_04 — Client media library', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('client');
      final found = await r.tapText('Media') || await r.tapText('Library');
      await r.wait();
      rec('09_04 Client media library', found,
          found ? null : 'Media library not found for client');
      await r.signOut();
    } catch (e) { rec('09_04 Client media library', false, '$e'); }
  });

  testWidgets('09_05 — Client payment history', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('client');
      final found = await r.tapText('Finance') || await r.tapText('Payments') ||
          await r.tapText('History');
      await r.wait();
      rec('09_05 Client payment history', found,
          found ? null : 'Payment history not found for client');
      await r.signOut();
    } catch (e) { rec('09_05 Client payment history', false, '$e'); }
  });

  testWidgets('09_06 — Client can leave a review', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('client');
      final found = await r.tapText('Reviews') || await r.tapText('Leave a Review');
      await r.wait();
      rec('09_06 Client reviews screen', found,
          found ? null : 'Reviews screen not found for client');
      await r.signOut();
    } catch (e) { rec('09_06 Client reviews screen', false, '$e'); }
  });

  testWidgets('09_07 — Client challenges screen', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('client');
      final found = await r.tapText('Challenges');
      await r.wait();
      rec('09_07 Client challenges screen', found,
          found ? null : 'Challenges not accessible for client');
      await r.signOut();
    } catch (e) { rec('09_07 Client challenges screen', false, '$e'); }
  });
}
