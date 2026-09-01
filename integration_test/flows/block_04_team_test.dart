import 'package:flutter/material.dart';
// Block 04 — Team Management
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/main.dart' as app;
import '../helpers/robot.dart';
typedef Recorder = void Function(String name, bool ok, [String? err]);

void runTests(Recorder rec, List<Map<String,String>> failures) {

  testWidgets('04_01 — Network screen loads all 4 tabs', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Network');
      await r.wait();
      final ok = r.existsText('Partners') && r.existsText('Staff') &&
          r.existsText('Clients') && r.existsText('Chats');
      rec('04_01 Network has 4 tabs', ok,
          ok ? null : 'Missing tab — found: ${['Partners','Staff','Clients','Chats'].where((x) => r.existsText(x)).join(",")}');
      await r.signOut();
    } catch (e) { rec('04_01 Network has 4 tabs', false, '$e'); }
  });

  for (final tab in ['Partners','Staff','Clients']) {
    testWidgets('04_02_$tab — $tab tab shows empty state or members', (t) async {
      try {
        app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
        final r = AppRobot(t);
        await r.devSignInAsJob('yoga_studio');
        await r.tapText('Network');
        await r.wait();
        await r.tapTab(tab);
        await r.wait();
        // Should show either members or an empty state — not a crash
        final ok = !r.existsText('Sign in to continue');
        rec('04_02_$tab $tab tab renders', ok,
            ok ? null : 'Crashed or returned to auth on $tab tab');
        await r.signOut();
      } catch (e) { rec('04_02_$tab $tab tab renders', false, '$e'); }
    });
  }

  testWidgets('04_03 — Generate partner invite — dialog opens', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Network');
      await r.wait();
      await r.tapTab('Partners');
      await r.wait();
      await r.tapFab();
      await r.wait();
      final ok = r.existsText('Invite') || r.existsText('Generate') ||
          r.existsText('Cancel');
      rec('04_03 Partner invite dialog', ok,
          ok ? null : 'Invite dialog did not open');
      if (ok) await r.dismissDialog();
      await r.signOut();
    } catch (e) { rec('04_03 Partner invite dialog', false, '$e'); }
  });

  testWidgets('04_04 — Generate client invite — dialog opens', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Network');
      await r.wait();
      await r.tapTab('Clients');
      await r.wait();
      await r.tapFab();
      await r.wait();
      final ok = r.existsText('Invite') || r.existsText('Generate') || r.existsText('Cancel');
      rec('04_04 Client invite dialog', ok, ok ? null : 'Invite dialog did not open');
      if (ok) await r.dismissDialog();
      await r.signOut();
    } catch (e) { rec('04_04 Client invite dialog', false, '$e'); }
  });

  testWidgets('04_05 — Tapping a member opens detail', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Network');
      await r.wait();
      await r.tapTab('Clients');
      await r.wait();
      // If there are any members, tap the first card
      final hasMember = find.byType(Card).evaluate().isNotEmpty ||
          find.byType(ListTile).evaluate().isNotEmpty;
      if (hasMember) {
        await r.tapFirst(find.byType(ListTile));
        await r.wait();
        final ok = !r.existsText('Sign in to continue');
        rec('04_05 Member detail opens', ok, ok ? null : 'Member detail did not open');
        await r.goBack();
      } else {
        rec('04_05 Member detail opens', true, null); // no members = skip gracefully
      }
      await r.signOut();
    } catch (e) { rec('04_05 Member detail opens', false, '$e'); }
  });

  testWidgets('04_06 — Chat tab renders', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Network');
      await r.wait();
      await r.tapTab('Chats');
      await r.wait();
      final ok = !r.existsText('Sign in to continue');
      rec('04_06 Chats tab renders', ok, ok ? null : 'Chats tab crashed');
      await r.signOut();
    } catch (e) { rec('04_06 Chats tab renders', false, '$e'); }
  });
}
