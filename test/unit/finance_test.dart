import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/commission_notifier.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/transaction_notifier.dart';

void main() {
  group('CommissionNotifier', () {
    late ProviderContainer container;
    setUp(() { container = ProviderContainer(); });
    tearDown(() { container.dispose(); });

    test('returns empty list when not authenticated', () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final state = await container.read(commissionNotifierProvider.future);
      // Not signed in → empty list
      expect(state, isEmpty);
    });

    test('returns list after owner sign-in', () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await container.read(authNotifierProvider.notifier)
          .devQuickSignIn(jobId: 'yoga_studio', jobLabel: 'Yoga Studio');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final state = await container.read(commissionNotifierProvider.future);
      expect(state, isA<List>());
    });
  });

  group('TransactionNotifier', () {
    late ProviderContainer container;
    setUp(() { container = ProviderContainer(); });
    tearDown(() { container.dispose(); });

    test('returns empty list when not authenticated', () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final state = await container.read(transactionNotifierProvider.future);
      expect(state, isEmpty);
    });

    test('returns list after owner sign-in', () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await container.read(authNotifierProvider.notifier)
          .devQuickSignIn(jobId: 'yoga_studio', jobLabel: 'Yoga Studio');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final state = await container.read(transactionNotifierProvider.future);
      expect(state, isA<List>());
    });

    test('recordManualTransaction returns bool', () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await container.read(authNotifierProvider.notifier)
          .devQuickSignIn(jobId: 'yoga_studio', jobLabel: 'Yoga Studio');
      final auth = container.read(authNotifierProvider) as AuthAuthenticated;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final result = await container.read(transactionNotifierProvider.notifier)
          .recordManualTransaction(
            businessId:     auth.profile.businessId,
            amount:         99.0,
            currencySymbol: r'$',
            type:           'payment',
            description:    'Unit test payment',
          );
      expect(result, isA<bool>());
    });
  });
}
