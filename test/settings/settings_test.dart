// test/settings/settings_test.dart
//
// Tests for BrandingOverrideNotifier.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/engine/config/branding_override_notifier.dart';

void main() {
  // ── BrandingOverrideNotifier ──────────────────────────────────────────────

  group('BrandingOverrideNotifier', () {
    ProviderContainer makeContainer() => ProviderContainer();

    test('initial state has all nulls', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final branding = container.read(brandingOverrideProvider);
      expect(branding.businessName, isNull);
      expect(branding.primaryColorHex, isNull);
      expect(branding.currency, isNull);
    });

    test('updateBusinessName sets non-empty value', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container
          .read(brandingOverrideProvider.notifier)
          .updateBusinessName('Apex Studio');
      expect(
        container.read(brandingOverrideProvider).businessName,
        'Apex Studio',
      );
    });

    test('updateBusinessName with empty string clears to null', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(brandingOverrideProvider.notifier).updateBusinessName('');
      expect(container.read(brandingOverrideProvider).businessName, isNull);
    });

    test('updatePrimaryColor sets hex string', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container
          .read(brandingOverrideProvider.notifier)
          .updatePrimaryColor('#E74C3C');
      expect(
        container.read(brandingOverrideProvider).primaryColorHex,
        '#E74C3C',
      );
    });

    test('updateCurrency sets non-empty value', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(brandingOverrideProvider.notifier).updateCurrency('€');
      expect(container.read(brandingOverrideProvider).currency, '€');
    });

    test('updateCurrency with empty string clears to null', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(brandingOverrideProvider.notifier).updateCurrency('');
      expect(container.read(brandingOverrideProvider).currency, isNull);
    });

    test('reset clears all overrides', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(brandingOverrideProvider.notifier);
      notifier.updateBusinessName('Test');
      notifier.updatePrimaryColor('#FF0000');
      notifier.updateCurrency('£');
      notifier.reset();

      final state = container.read(brandingOverrideProvider);
      expect(state.businessName, isNull);
      expect(state.primaryColorHex, isNull);
      expect(state.currency, isNull);
    });
  });
}