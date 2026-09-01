// integration_test/app_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personal_wellness_trainer/main.dart' as app;

import 'flows/block_01_auth_test.dart'        as b01;
import 'flows/block_02_owner_shell_test.dart'  as b02;
import 'flows/block_03_activity_test.dart'     as b03;
import 'flows/block_04_team_test.dart'         as b04;
import 'flows/block_05_finance_test.dart'      as b05;
import 'flows/block_06_marketplace_test.dart'  as b06;
import 'flows/block_07_features_test.dart'     as b07;
import 'flows/block_08_partner_test.dart'      as b08;
import 'flows/block_09_client_test.dart'       as b09;
import 'flows/block_10_staff_test.dart'        as b10;
import 'flows/block_11_messaging_test.dart'    as b11;
import 'flows/block_12_navigation_test.dart'   as b12;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final results  = <String, dynamic>{};
  final failures = <Map<String, String>>[];
  int passed = 0, failed = 0, skipped = 0;

  void record(String name, bool ok, [String? err]) {
    results[name] = ok ? '✅ PASS' : '❌ FAIL: $err';
    if (ok) { passed++; } else { failed++; failures.add({'test': name, 'error': err ?? ''}); }
  }

  group('Personal Wellness Trainer Full Test Suite', () {
    setUpAll(() async {
      // Clear any mock session persisted from a previous test run.
      // MockAuthSource saves the signed-in email to SharedPreferences under
      // 'ae_mock_session_email'. If it isn't cleared, restoreSession() auto-
      // signs the user in and the auth screen is never shown, which breaks
      // every test that checks for the dev quick-launch button.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('ae_mock_session_email');
      } catch (_) {}

      app.main();
      await Future<void>.delayed(const Duration(seconds: 3));
    });

    group('Block 01 — Auth & Onboarding',           () { b01.runTests(record, failures); });
    group('Block 02 — Owner Shell',                  () { b02.runTests(record, failures); });
    group('Block 03 — Activity & Scheduling',        () { b03.runTests(record, failures); });
    group('Block 04 — Team Management',              () { b04.runTests(record, failures); });
    group('Block 05 — Finance',                      () { b05.runTests(record, failures); });
    group('Block 06 — Marketplace & Agreements',     () { b06.runTests(record, failures); });
    group('Block 07 — Features',                     () { b07.runTests(record, failures); });
    group('Block 08 — Partner Shell',                () { b08.runTests(record, failures); });
    group('Block 09 — Client Shell',                 () { b09.runTests(record, failures); });
    group('Block 10 — Staff Shell',                  () { b10.runTests(record, failures); });
    group('Block 11 — Messaging',                    () { b11.runTests(record, failures); });
    group('Block 12 — Navigation & Edge Cases',      () { b12.runTests(record, failures); });

    tearDownAll(() async {
      final report = {
        'timestamp': DateTime.now().toIso8601String(),
        'summary': {'total': passed+failed+skipped, 'passed': passed, 'failed': failed, 'skipped': skipped},
        'failures': failures,
        'all_results': results,
      };
      final json = const JsonEncoder.withIndent('  ').convert(report);
      try {
        await File('/sdcard/personal_wellness_trainer_test_results.json').writeAsString(json);
      } catch (_) {}
      debugPrint('===PERSONAL_WELLNESS_TRAINER_RESULTS_START===');
      debugPrint(json);
      debugPrint('===PERSONAL_WELLNESS_TRAINER_RESULTS_END===');
    });
  });
}
