// test/modules/finance/finance_test.dart
//
// Tests for Finance module providers — Blueprint Section 16.
// Verifies that the mock data source returns the correct shape and filters.
// Run with: flutter test test/modules/finance/finance_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/commission_model.dart';
import 'package:personal_wellness_trainer/data/models/revenue_summary_model.dart';
import 'package:personal_wellness_trainer/data/models/transaction_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/commission_notifier.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/revenue_summary_provider.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/transaction_notifier.dart';

void main() {
  // ── Helper ───────────────────────────────────────────────────────────────────

  ProviderContainer containerFor(String role) {
    final profile = UserProfile(
      userId: 'usr_${role}_001',
      businessId: 'biz_mock_001',
      role: role,
      displayName: 'Test $role',
      joinedAt: DateTime(2025),
      isActive: true,
    );
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => FakeAuthNotifier(profile),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  // ── TransactionNotifier ───────────────────────────────────────────────────────

  group('TransactionNotifier', () {
    test('owner receives a non-empty transaction list', () async {
      final container = containerFor('owner');
      final result = await container.read(transactionNotifierProvider.future);
      expect(result, isNotEmpty);
      expect(result.first, isA<TransactionModel>());
    });

    test('every transaction belongs to the correct business', () async {
      final container = containerFor('owner');
      final result = await container.read(transactionNotifierProvider.future);
      for (final t in result) {
        expect(t.businessId, equals('biz_mock_001'));
      }
    });

    test('all transactions have a positive amount', () async {
      final container = containerFor('owner');
      final result = await container.read(transactionNotifierProvider.future);
      for (final t in result) {
        expect(t.amount, greaterThan(0));
      }
    });
  });

  // ── CommissionNotifier ────────────────────────────────────────────────────────

  group('CommissionNotifier', () {
    test('owner receives commission records', () async {
      final container = containerFor('owner');
      final result = await container.read(commissionNotifierProvider.future);
      expect(result, isNotEmpty);
      expect(result.first, isA<CommissionModel>());
    });

    test('partner receives only their own commission records', () async {
      final container = containerFor('partner');
      final result = await container.read(commissionNotifierProvider.future);
      for (final c in result) {
        expect(c.partnerId, equals('usr_partner_001'));
      }
    });

    test('staff receives an empty commission list', () async {
      final container = containerFor('staff');
      final result = await container.read(commissionNotifierProvider.future);
      expect(result, isEmpty);
    });
  });

  // ── RevenueSummaryProvider ────────────────────────────────────────────────────
  // revenueSummaryProvider is a sync Provider<RevenueSummaryModel> — read directly.

  group('RevenueSummaryProvider', () {
    test('owner receives a revenue summary with non-negative totals', () async {
      final container = containerFor('owner');
      // Wait for transactions to load first (summary derives from them).
      await container.read(transactionNotifierProvider.future);
      final result = container.read(revenueSummaryProvider);
      expect(result, isA<RevenueSummaryModel>());
      expect(result.totalRevenue, greaterThanOrEqualTo(0.0));
      expect(result.netRevenue, isNotNull);
    });

    test('revenue summary period label is not empty', () async {
      final container = containerFor('owner');
      await container.read(transactionNotifierProvider.future);
      final result = container.read(revenueSummaryProvider);
      expect(result.periodLabel, isNotEmpty);
    });
  });
}

// ── Fake auth notifier ────────────────────────────────────────────────────────
// AuthNotifier extends Notifier<AuthState> — build() is synchronous.

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._profile);
  final UserProfile _profile;

  @override
  AuthState build() {
    return AuthAuthenticated(profile: _profile);
  }
}
