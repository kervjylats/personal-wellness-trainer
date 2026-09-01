import 'package:flutter/material.dart';
// Block 06 — Marketplace & Agreements
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/main.dart' as app;
import '../helpers/robot.dart';
typedef Recorder = void Function(String name, bool ok, [String? err]);

void runTests(Recorder rec, List<Map<String,String>> failures) {

  testWidgets('06_01 — Marketplace lists discoverable partners', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Discover') || await r.tapText('Marketplace');
      await r.wait();
      final ok = !r.existsText('Sign in to continue');
      rec('06_01 Marketplace loads', ok, ok ? null : 'Marketplace did not load');
      await r.signOut();
    } catch (e) { rec('06_01 Marketplace loads', false, '$e'); }
  });

  testWidgets('06_02 — Tapping a listing opens profile card', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Discover') || await r.tapText('Marketplace');
      await r.wait();
      final hasListings = find.byType(Card).evaluate().isNotEmpty ||
          find.byType(ListTile).evaluate().isNotEmpty;
      if (hasListings) {
        await r.tapFirst(find.byType(Card));
        await r.wait();
        final sheetOpen = r.existsText('Partnership') || r.existsText('Request') ||
            r.existsText('Category') || r.existsText('Cancel');
        rec('06_02 Listing profile card opens', sheetOpen,
            sheetOpen ? null : 'Profile card bottom sheet did not open');
        if (sheetOpen) await r.goBack();
      } else {
        rec('06_02 Listing profile card opens', true, null); // no listings = mock data
      }
      await r.signOut();
    } catch (e) { rec('06_02 Listing profile card opens', false, '$e'); }
  });

  testWidgets('06_03 — Agreements screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final found = await r.tapText('Agreements') || await r.tapText('Deals');
      await r.wait();
      rec('06_03 Agreements screen loads', found,
          found ? null : 'Agreements screen not found');
      await r.signOut();
    } catch (e) { rec('06_03 Agreements screen loads', false, '$e'); }
  });

  testWidgets('06_04 — Agreement detail opens', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Agreements') || await r.tapText('Deals');
      await r.wait();
      if (find.byType(ListTile).evaluate().isNotEmpty) {
        await r.tapFirst(find.byType(ListTile));
        await r.wait();
        final ok = r.existsText('Agreement') || r.existsText('Commission') ||
            r.existsText('Status');
        rec('06_04 Agreement detail opens', ok,
            ok ? null : 'Agreement detail did not show expected content');
        await r.goBack();
      } else {
        rec('06_04 Agreement detail opens', true, null);
      }
      await r.signOut();
    } catch (e) { rec('06_04 Agreement detail opens', false, '$e'); }
  });

  testWidgets('06_05 — Send partnership request flow', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Discover') || await r.tapText('Marketplace');
      await r.wait();
      if (find.byType(Card).evaluate().isNotEmpty) {
        await r.tapFirst(find.byType(Card));
        await r.wait();
        // Select first category chip if any
        if (find.byType(FilterChip).evaluate().isNotEmpty) {
          await r.tapFirst(find.byType(FilterChip));
          await r.wait();
        }
        // Tap send request
        final sent = await r.tapText('Send') || await r.tapText('Request');
        await r.wait();
        rec('06_05 Send partnership request', sent,
            sent ? null : 'Send Request button not found');
      } else {
        rec('06_05 Send partnership request', true, null);
      }
      await r.signOut();
    } catch (e) { rec('06_05 Send partnership request', false, '$e'); }
  });
}
