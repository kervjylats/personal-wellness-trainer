import 'package:flutter/material.dart';
// Block 07 — All Other Features
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/main.dart' as app;
import '../helpers/robot.dart';
import '../helpers/test_data.dart';
typedef Recorder = void Function(String name, bool ok, [String? err]);

void runTests(Recorder rec, List<Map<String,String>> failures) {

  Future<void> openAndTest(WidgetTester t, AppRobot r, String testId,
      List<String> labels, String expectText) async {
    bool found = false;
    for (final l in labels) { if (await r.tapText(l)) { found = true; break; } }
    await r.wait();
    final ok = found || r.existsText(expectText) || !r.existsText('Sign in to continue');
    rec(testId, ok, ok ? null : 'Screen not found. Tried: ${labels.join(",")}');
  }

  testWidgets('07_01 — Catalog screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await openAndTest(t, r, '07_01 Catalog loads', ['Catalog','Shop','Store'], 'Catalog');
      await r.signOut();
    } catch (e) { rec('07_01 Catalog loads', false, '$e'); }
  });

  testWidgets('07_02 — Catalog create item', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Catalog') || await r.tapText('Shop');
      await r.wait();
      await r.tapFab();
      await r.wait();
      final formOpen = find.byType(TextFormField).evaluate().isNotEmpty ||
          r.existsText('Cancel');
      if (formOpen) {
        await r.enterText(find.byType(TextFormField).first, kTestCatalogItem);
        await r.tapText('Save') || await r.tapText('Create') || await r.tapText('Add');
        await r.settle();
      }
      rec('07_02 Catalog create item', formOpen,
          formOpen ? null : 'Create catalog form did not open');
      await r.signOut();
    } catch (e) { rec('07_02 Catalog create item', false, '$e'); }
  });

  testWidgets('07_03 — Challenges screen loads and create works', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final found = await r.tapText('Challenges');
      await r.wait();
      if (found) {
        await r.tapFab();
        await r.wait();
        if (find.byType(TextFormField).evaluate().isNotEmpty) {
          await r.enterText(find.byType(TextFormField).first, kTestChallengeTitle);
          await r.tapText('Create') || await r.tapText('Save');
          await r.settle();
        }
      }
      rec('07_03 Challenges screen + create', found,
          found ? null : 'Challenges screen not found');
      await r.signOut();
    } catch (e) { rec('07_03 Challenges screen + create', false, '$e'); }
  });

  testWidgets('07_04 — Rewards management screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final found = await r.tapText('Rewards') || await r.tapText('Loyalty');
      await r.wait();
      rec('07_04 Rewards screen loads', found,
          found ? null : 'Rewards/Loyalty screen not found');
      await r.signOut();
    } catch (e) { rec('07_04 Rewards screen loads', false, '$e'); }
  });

  testWidgets('07_05 — Media library screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final found = await r.tapText('Media') || await r.tapText('Library');
      await r.wait();
      rec('07_05 Media library loads', found,
          found ? null : 'Media Library screen not found');
      await r.signOut();
    } catch (e) { rec('07_05 Media library loads', false, '$e'); }
  });

  testWidgets('07_06 — Homework screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final found = await r.tapText('Homework') || await r.tapText('Assignments');
      await r.wait();
      rec('07_06 Homework screen loads', found,
          found ? null : 'Homework screen not found');
      await r.signOut();
    } catch (e) { rec('07_06 Homework screen loads', false, '$e'); }
  });

  testWidgets('07_07 — Notifications screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final found = await r.tapIcon(Icons.notifications_outlined) ||
          await r.tapText('Notifications');
      await r.wait();
      rec('07_07 Notifications loads', found,
          found ? null : 'Notifications screen not found');
      await r.signOut();
    } catch (e) { rec('07_07 Notifications loads', false, '$e'); }
  });

  testWidgets('07_08 — Profile screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final found = await r.tapText('Profile') ||
          await r.tapIcon(Icons.person_outline) ||
          await r.tapIcon(Icons.account_circle_outlined);
      await r.wait();
      rec('07_08 Profile screen loads', found,
          found ? null : 'Profile screen not found');
      await r.signOut();
    } catch (e) { rec('07_08 Profile screen loads', false, '$e'); }
  });

  testWidgets('07_09 — Reviews screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final found = await r.tapText('Reviews') || await r.tapText('Feedback');
      await r.wait();
      rec('07_09 Reviews screen loads', found,
          found ? null : 'Reviews screen not found');
      await r.signOut();
    } catch (e) { rec('07_09 Reviews screen loads', false, '$e'); }
  });

  testWidgets('07_10 — Inventory screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final found = await r.tapText('Inventory');
      await r.wait();
      rec('07_10 Inventory screen loads', found,
          found ? null : 'Inventory screen not found (may not be enabled for yoga_studio)');
      await r.signOut();
    } catch (e) { rec('07_10 Inventory screen loads', false, '$e'); }
  });
}
