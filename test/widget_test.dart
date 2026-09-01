// test/widget_test.dart
//
// Smoke test — verifies the app boots without crashing.
// AppEngine is a ConsumerStatefulWidget so it must be wrapped in ProviderScope.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/main.dart';

void main() {
  testWidgets('Phase 0 — App launches and shows placeholder', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AppEngine(),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
