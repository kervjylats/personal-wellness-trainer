import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/main.dart' as app;
import '../helpers/robot.dart';
typedef Recorder = void Function(String name, bool ok, [String? err]);

void runTests(Recorder rec, List<Map<String,String>> failures) {

  testWidgets('02_01 — Owner dashboard loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final ok = !r.existsText('Sign in to continue');
      rec('02_01 Owner dashboard loads', ok, ok ? null : 'Still on auth screen');
      await r.signOut();
    } catch (e) { rec('02_01 Owner dashboard loads', false, '$e'); }
  });

  testWidgets('02_02 — Owner Network tab loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Network');
      await r.wait();
      final ok = r.existsText('Partners') || r.existsText('Staff') || r.existsText('Clients');
      rec('02_02 Network tab loads', ok, ok ? null : 'Network tab content not found');
      await r.signOut();
    } catch (e) { rec('02_02 Network tab loads', false, '$e'); }
  });

  testWidgets('02_03 — Owner Finance tab loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Finance');
      await r.wait();
      final ok = !r.existsText('Sign in to continue');
      rec('02_03 Finance tab loads', ok, ok ? null : 'Finance tab did not load');
      await r.signOut();
    } catch (e) { rec('02_03 Finance tab loads', false, '$e'); }
  });

  testWidgets('02_04 — Owner Control Panel tab loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final found = await r.tapText('Control') || await r.tapText('Settings') ||
          await r.tapIcon(Icons.settings_outlined);
      await r.wait();
      rec('02_04 Control Panel tab loads', found, found ? null : 'Control Panel tab not found');
      await r.signOut();
    } catch (e) { rec('02_04 Control Panel tab loads', false, '$e'); }
  });

  testWidgets('02_05 — Owner Discover tab loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final found = await r.tapText('Discover') || await r.tapText('Marketplace');
      await r.wait();
      rec('02_05 Discover tab loads', found, found ? null : 'Discover/Marketplace tab not found');
      await r.signOut();
    } catch (e) { rec('02_05 Discover tab loads', false, '$e'); }
  });

  testWidgets('02_06 — Pull-to-refresh on dashboard', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.pullToRefresh();
      final ok = !r.existsText('Sign in to continue');
      rec('02_06 Pull-to-refresh dashboard', ok, ok ? null : 'App crashed on pull-to-refresh');
      await r.signOut();
    } catch (e) { rec('02_06 Pull-to-refresh dashboard', false, '$e'); }
  });

  for (final job in [('yoga_studio','Yoga Studio'),('sound_healer','Sound Healer'),('nutritionist','Nutritionist')]) {
    final testId = '02_07_${job.$1}';
    testWidgets('$testId — Dashboard loads for ${job.$1}', (t) async {
      try {
        app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
        final r = AppRobot(t);
        await r.devSignInAsJob(job.$1);
        final ok = !r.existsText('Sign in to continue');
        rec(testId, ok, ok ? null : 'Did not land on dashboard for ${job.$1}');
        await r.signOut();
      } catch (e) { rec(testId, false, '$e'); }
    });
  }
}
