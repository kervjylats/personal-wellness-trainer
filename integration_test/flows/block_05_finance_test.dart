import 'package:flutter/material.dart';
// Block 05 — Finance
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/main.dart' as app;
import '../helpers/robot.dart';
typedef Recorder = void Function(String name, bool ok, [String? err]);

void runTests(Recorder rec, List<Map<String,String>> failures) {

  testWidgets('05_01 — Finance screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Finance');
      await r.wait();
      final ok = !r.existsText('Sign in to continue');
      rec('05_01 Finance screen loads', ok, ok ? null : 'Finance screen did not load');
      await r.signOut();
    } catch (e) { rec('05_01 Finance screen loads', false, '$e'); }
  });

  testWidgets('05_02 — Revenue summary cards render', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Finance');
      await r.wait();
      final ok = find.byType(Card).evaluate().isNotEmpty;
      rec('05_02 Revenue summary cards render', ok,
          ok ? null : 'No cards found on finance screen');
      await r.signOut();
    } catch (e) { rec('05_02 Revenue summary cards render', false, '$e'); }
  });

  testWidgets('05_03 — Transaction list renders', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Finance');
      await r.wait();
      // Scroll to transaction section
      await r.scrollToText('Transactions');
      final ok = r.existsText('Transactions') || r.existsText('No transactions');
      rec('05_03 Transaction list renders', ok,
          ok ? null : 'Transaction list section not found');
      await r.signOut();
    } catch (e) { rec('05_03 Transaction list renders', false, '$e'); }
  });

  testWidgets('05_04 — Commission list renders', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Finance');
      await r.wait();
      await r.scrollToText('Commission');
      final ok = r.existsText('Commission') || r.existsText('No commission');
      rec('05_04 Commission list renders', ok,
          ok ? null : 'Commission section not found');
      await r.signOut();
    } catch (e) { rec('05_04 Commission list renders', false, '$e'); }
  });

  testWidgets('05_05 — Active deals renders', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Finance');
      await r.wait();
      await r.scrollToText('Deals');
      final ok = r.existsText('Deals') || r.existsText('Agreements') ||
          r.existsText('No active deals');
      rec('05_05 Active deals renders', ok,
          ok ? null : 'Deals section not found on finance screen');
      await r.signOut();
    } catch (e) { rec('05_05 Active deals renders', false, '$e'); }
  });

  testWidgets('05_06 — Finance pull-to-refresh', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Finance');
      await r.wait();
      await r.pullToRefresh();
      final ok = !r.existsText('Sign in to continue');
      rec('05_06 Finance pull-to-refresh', ok,
          ok ? null : 'Crashed on pull-to-refresh in Finance');
      await r.signOut();
    } catch (e) { rec('05_06 Finance pull-to-refresh', false, '$e'); }
  });

  testWidgets('05_07 — Client payments screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole('client');
      await r.tapText('Finance') || await r.tapText('Payments');
      await r.wait();
      final ok = !r.existsText('Sign in to continue');
      rec('05_07 Client payments screen loads', ok,
          ok ? null : 'Client payments did not load');
      await r.signOut();
    } catch (e) { rec('05_07 Client payments screen loads', false, '$e'); }
  });
}
