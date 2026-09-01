import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/main.dart' as app;
import '../helpers/robot.dart';
import '../helpers/test_data.dart';
typedef Recorder = void Function(String name, bool ok, [String? err]);

void runTests(Recorder rec, List<Map<String,String>> failures) {

  testWidgets('01_01 — App launches without crash', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 4));
      final r = AppRobot(t);
      final ok = r.existsKey('dev_quick_launch_btn') || r.existsText('Sign in to continue');
      rec('01_01 App launches', ok, ok ? null : 'Auth screen not found');
    } catch (e) { rec('01_01 App launches', false, '$e'); }
  });

  testWidgets('01_02 — Dev Quick Launch button visible', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      final ok = r.existsKey('dev_quick_launch_btn');
      rec('01_02 Dev Quick Launch visible', ok,
          ok ? null : 'Key dev_quick_launch_btn not found — check DataConfig.useMockData');
    } catch (e) { rec('01_02 Dev Quick Launch visible', false, '$e'); }
  });

  testWidgets('01_03 — Sign-in form validates empty fields', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.tapText('Sign In');
      await r.wait();
      final ok = r.existsText('Sign In');
      rec('01_03 Sign-in validates empty', ok,
          ok ? null : 'Navigated away with empty form — validation not working');
    } catch (e) { rec('01_03 Sign-in validates empty', false, '$e'); }
  });

  testWidgets('01_04 — Sign-in shows error on wrong password', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.enterText(find.byType(TextFormField).first, 'wrong@test.com');
      await r.enterText(find.byType(TextFormField).last,  'WrongPass99!');
      await r.tapText('Sign In');
      await r.settle();
      final ok = r.existsText('Sign In');
      rec('01_04 Wrong password shows error', ok,
          ok ? null : 'Navigated away despite wrong credentials');
    } catch (e) { rec('01_04 Wrong password shows error', false, '$e'); }
  });

  for (final job in kAllJobs) {
    final jobId = job.$1; final jobLabel = job.$2;
    final testName = '01_05_$jobId — devQuickSignIn';
    testWidgets(testName, (t) async {
      try {
        app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
        final r = AppRobot(t);
        await r.devSignInAsJob(jobId);
        final onApp = !r.existsText('Sign in to continue');
        rec(testName, onApp, onApp ? null : 'Still on auth after devQuickSignIn for $jobLabel');
        if (onApp) await r.signOut();
        await r.settle();
      } catch (e) { rec(testName, false, '$e'); }
    });
  }

  testWidgets('01_06 — No onboarding after devQuickSignIn', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final onOnboarding = r.existsText('Set up your business') || r.existsText('Onboarding');
      rec('01_06 No onboarding after devQuickSignIn', !onOnboarding,
          !onOnboarding ? null : 'Onboarding appeared — isNewOwner not false');
      await r.signOut();
    } catch (e) { rec('01_06 No onboarding after devQuickSignIn', false, '$e'); }
  });

  testWidgets('01_07 — Sign out returns to auth screen', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.signOut();
      final ok = r.existsText('Sign in to continue') || r.existsKey('dev_quick_launch_btn');
      rec('01_07 Sign out → auth screen', ok, ok ? null : 'Did not return to auth after sign-out');
    } catch (e) { rec('01_07 Sign out → auth screen', false, '$e'); }
  });
}
