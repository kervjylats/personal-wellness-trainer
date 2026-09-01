import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_wellness_trainer/modules/dashboard/providers/dashboard_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DashboardSlotsProvider — slot lists', () {
    ProviderContainer makeContainer() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('ownerDashboardSlotsProvider resolves without throwing', () {
      final container = makeContainer();
      final slots = container.read(ownerDashboardSlotsProvider);
      expect(slots, isA<List<String>>());
    });

    test('partnerDashboardSlotsProvider returns upgrade_cta when config is null', () {
      final container = makeContainer();
      final slots = container.read(partnerDashboardSlotsProvider);
      expect(slots, contains('upgrade_cta'));
    });

    test('staffDashboardSlotsProvider resolves without throwing', () {
      final container = makeContainer();
      final slots = container.read(staffDashboardSlotsProvider);
      expect(slots, isA<List<String>>());
    });

    test('clientDashboardSlotsProvider resolves without throwing', () {
      final container = makeContainer();
      final slots = container.read(clientDashboardSlotsProvider);
      expect(slots, isA<List<String>>());
    });

    test('DashboardSlots.owner contains all four slot IDs', () {
      expect(DashboardSlots.owner, containsAll([
        'revenue_summary',
        'upcoming_activity',
        'team_count',
        'deal_count',
      ]));
    });

    test('DashboardSlots.partner always includes upgrade_cta', () {
      expect(DashboardSlots.partner, contains('upgrade_cta'));
    });

    test('DashboardSlots.staff contains activity slot IDs', () {
      expect(DashboardSlots.staff, containsAll([
        'my_activities',
        'assigned_count',
      ]));
    });

    test('DashboardSlots.client contains the three client slot IDs', () {
      expect(DashboardSlots.client, containsAll([
        'next_activity',
        'my_balance',
        'content_preview',
      ]));
    });
  });
}