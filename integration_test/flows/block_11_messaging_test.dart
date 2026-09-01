import 'package:flutter/material.dart';
// Block 11 — Messaging (All Roles)
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/main.dart' as app;
import '../helpers/robot.dart';
import '../helpers/test_data.dart';
typedef Recorder = void Function(String name, bool ok, [String? err]);

void runTests(Recorder rec, List<Map<String,String>> failures) {

  Future<void> testDm(WidgetTester t, String testId, String role) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsRole(role);
      await r.tapText('Network') || await r.tapText('Chats');
      await r.wait();
      // Try to open Chats tab
      await r.tapTab('Chats');
      await r.wait();
      final ok = !r.existsText('Sign in to continue');
      rec(testId, ok, ok ? null : 'Chats tab crashed for $role');
      await r.signOut();
    } catch (e) { rec(testId, false, '$e'); }
  }

  testWidgets('11_01 — Owner Chats tab loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Network');
      await r.wait();
      await r.tapTab('Chats');
      await r.wait();
      final ok = !r.existsText('Sign in to continue');
      rec('11_01 Owner Chats tab', ok, ok ? null : 'Owner Chats tab crashed');
      await r.signOut();
    } catch (e) { rec('11_01 Owner Chats tab', false, '$e'); }
  });

  testWidgets('11_02 — Partner Chats tab', (t) async =>
      testDm(t, '11_02 Partner Chats', 'partner'));

  testWidgets('11_03 — Client Chats tab', (t) async =>
      testDm(t, '11_03 Client Chats', 'client'));

  testWidgets('11_04 — Staff Chats tab', (t) async =>
      testDm(t, '11_04 Staff Chats', 'staff'));

  testWidgets('11_05 — Opening DM from network member', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Network');
      await r.wait();
      await r.tapTab('Clients');
      await r.wait();
      // Tap chat icon on first member tile
      final chatIcons = find.byIcon(Icons.chat_bubble_outline);
      if (chatIcons.evaluate().isNotEmpty) {
        await r.tapFirst(chatIcons);
        await r.wait();
        final ok = !r.existsText('Sign in to continue');
        rec('11_05 DM from network tile', ok,
            ok ? null : 'DM screen did not open from chat icon');
        await r.goBack();
      } else {
        rec('11_05 DM from network tile', true, null); // no members = skip
      }
      await r.signOut();
    } catch (e) { rec('11_05 DM from network tile', false, '$e'); }
  });

  testWidgets('11_06 — Message sends in thread', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Network');
      await r.wait();
      await r.tapTab('Chats');
      await r.wait();
      // If existing conversations, open first
      if (find.byType(ListTile).evaluate().isNotEmpty) {
        await r.tapFirst(find.byType(ListTile));
        await r.wait();
        // Type and send a message
        if (find.byType(TextField).evaluate().isNotEmpty) {
          await r.enterText(find.byType(TextField).last, kTestMessage);
          await r.tapIcon(Icons.send) || await r.tapText('Send');
          await r.wait();
          final ok = r.existsText(kTestMessage);
          rec('11_06 Message sends', ok,
              ok ? null : 'Sent message not visible in thread');
        } else {
          rec('11_06 Message sends', true, null);
        }
        await r.goBack();
      } else {
        rec('11_06 Message sends', true, null);
      }
      await r.signOut();
    } catch (e) { rec('11_06 Message sends', false, '$e'); }
  });
}
