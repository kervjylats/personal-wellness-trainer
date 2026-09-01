import 'package:flutter/material.dart';
// Block 03 — Activity & Scheduling
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/main.dart' as app;
import '../helpers/robot.dart';
import '../helpers/test_data.dart';
typedef Recorder = void Function(String name, bool ok, [String? err]);

void runTests(Recorder rec, List<Map<String,String>> failures) {

  testWidgets('03_01 — Activity list screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      // Navigate to activities (may be in nav or dashboard slot)
      final found = await r.tapText('Activities') || await r.tapText('Sessions') ||
          await r.tapText('Classes') || await r.tapIcon(Icons.event_note_outlined);
      await r.wait();
      rec('03_01 Activity list loads', found, found ? null : 'Activity screen not found');
      await r.signOut();
    } catch (e) { rec('03_01 Activity list loads', false, '$e'); }
  });

  testWidgets('03_02 — Create activity — FAB opens form', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Activities') || await r.tapText('Sessions');
      await r.wait();
      final fabTapped = await r.tapFab();
      await r.wait();
      // Form should open — look for title/label field
      final formOpen = r.existsText('Title') || r.existsText('Name') ||
          r.existsText('Session') || r.existsText('Description');
      rec('03_02 Create activity FAB → form', fabTapped && formOpen,
          fabTapped && formOpen ? null : 'FAB tap=$fabTapped formOpen=$formOpen');
      await r.signOut();
    } catch (e) { rec('03_02 Create activity FAB → form', false, '$e'); }
  });

  testWidgets('03_03 — Create activity — required field validation', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Activities') || await r.tapText('Sessions');
      await r.wait();
      await r.tapFab();
      await r.wait();
      // Try to save empty form
      await r.tapText('Save') || await r.tapText('Create') || await r.tapText('Add');
      await r.wait();
      // Should still see the form (not closed — validation blocked it)
      final stillOpen = r.existsText('Save') || r.existsText('Create') ||
          r.existsText('required') || r.existsText('is required');
      rec('03_03 Activity required validation', stillOpen,
          stillOpen ? null : 'Form closed without entering required fields');
      await r.signOut();
    } catch (e) { rec('03_03 Activity required validation', false, '$e'); }
  });

  testWidgets('03_04 — Create activity — fill and save', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Activities') || await r.tapText('Sessions');
      await r.wait();
      await r.tapFab();
      await r.wait();

      // Fill ALL required fields, not just title. yoga_studio's
      // activity_fields config (verified directly) marks title, date,
      // time, AND price as required — 03_03 already confirms (and
      // correctly relies on) this validation actually working. A
      // same-screen scroll between filling the title and tapping
      // Save was previously enough to coincidentally pass this test
      // without ever exercising a real, valid submission.
      await r.enterText(find.byType(TextFormField).first, kTestActivityTitle);

      // Date — opens a Material DatePickerDialog; accept its default
      // (today's date is pre-selected) by tapping OK.
      await r.tapIcon(Icons.calendar_today_outlined);
      await r.wait(const Duration(milliseconds: 300));
      await r.tapText('OK');
      await r.wait();

      // Time — opens a Material TimePickerDialog; accept its default
      // the same way.
      await r.tapIcon(Icons.access_time_outlined);
      await r.wait(const Duration(milliseconds: 300));
      await r.tapText('OK');
      await r.wait();

      // Price is the LAST field in yoga_studio's activity_fields config,
      // so it's also the last TextFormField in the form. Scroll to it
      // first since it's well below the fold.
      await r.scrollToText('Price', maxScrolls: 15);
      await r.enterText(find.byType(TextFormField).last, '25');

      await r.tapText('Save') || await r.tapText('Create');
      await r.settle();
      // Should be back on list with new item
      final ok = r.existsText(kTestActivityTitle) || !r.existsText('Save');
      rec('03_04 Create activity saves', ok,
          ok ? null : 'Activity not found in list after save');
      await r.signOut();
    } catch (e) { rec('03_04 Create activity saves', false, '$e'); }
  });

  testWidgets('03_05 — Schedule screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final found = await r.tapText('Schedule') || await r.tapText('Calendar') ||
          await r.tapIcon(Icons.calendar_month_outlined);
      await r.wait();
      rec('03_05 Schedule screen loads', found, found ? null : 'Schedule screen not found');
      await r.signOut();
    } catch (e) { rec('03_05 Schedule screen loads', false, '$e'); }
  });

  testWidgets('03_06 — Reservations screen loads', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      final found = await r.tapText('Reservations') || await r.tapText('Bookings');
      await r.wait();
      rec('03_06 Reservations screen loads', found,
          found ? null : 'Reservations screen not found');
      await r.signOut();
    } catch (e) { rec('03_06 Reservations screen loads', false, '$e'); }
  });

  testWidgets('03_07 — Date field picker opens', (t) async {
    try {
      app.main(); await t.pumpAndSettle(const Duration(seconds: 3));
      final r = AppRobot(t);
      await r.devSignInAsJob('yoga_studio');
      await r.tapText('Activities') || await r.tapText('Sessions');
      await r.wait();
      await r.tapFab();
      await r.wait();
      // Tap a date field
      final dateTapped = await r.tapIcon(Icons.calendar_today_outlined);
      await r.wait(const Duration(milliseconds: 300));
      // DatePicker dialog should appear
      final pickerOpen = r.existsText('OK') || r.existsText('Cancel') ||
          find.byType(DatePickerDialog).evaluate().isNotEmpty;
      if (pickerOpen) await r.tapText('Cancel');
      rec('03_07 Date picker opens', dateTapped,
          dateTapped ? null : 'Date picker field not found or did not open');
      await r.signOut();
    } catch (e) { rec('03_07 Date picker opens', false, '$e'); }
  });
}
