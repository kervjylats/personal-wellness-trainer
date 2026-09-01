import 'package:flutter/material.dart';
// Block 10 — Staff Shell
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/main.dart' as app;
import '../helpers/robot.dart';
typedef Recorder = void Function(String name, bool ok, [String? err]);

void runTests(Recorder rec, List<Map<String,String>> failures) {

  testWidgets('10_01 — Staff dashboard loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('staff');
      final ok = !r.existsText('Sign in to continue');
      rec('10_01 Staff dashboard loads', ok, ok ? null : 'Staff did not land on dashboard');
      await r.signOut();
    } catch (e) { rec('10_01 Staff dashboard loads', false, '$e'); }
  });

  testWidgets('10_02 — Staff cannot see Finance tab', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('staff');
      // Staff should not have a Finance tab in their bottom nav
      final hasFinance = r.existsText('Finance') &&
          find.descendant(of: find.byType(BottomNavigationBar),
              matching: find.text('Finance')).evaluate().isNotEmpty;
      rec('10_02 Staff no Finance tab', !hasFinance,
          !hasFinance ? null : 'Staff should not see Finance tab in bottom nav');
      await r.signOut();
    } catch (e) { rec('10_02 Staff no Finance tab', false, '$e'); }
  });

  testWidgets('10_03 — Staff network loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('staff');
      await r.tapText('Network');
      await r.wait();
      final ok = !r.existsText('Sign in to continue');
      rec('10_03 Staff network loads', ok, ok ? null : 'Staff network screen did not load');
      await r.signOut();
    } catch (e) { rec('10_03 Staff network loads', false, '$e'); }
  });

  testWidgets('10_04 — Staff activities/sessions screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('staff');
      final found = await r.tapText('Activities') || await r.tapText('Sessions') ||
          await r.tapText('Classes') || await r.tapText('Schedule');
      await r.wait();
      rec('10_04 Staff activities loads', found,
          found ? null : 'Activities screen not found for staff');
      await r.signOut();
    } catch (e) { rec('10_04 Staff activities loads', false, '$e'); }
  });
}
