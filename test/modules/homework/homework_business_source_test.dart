// test/modules/homework/homework_business_source_test.dart
//
// The coach management view reads getHomeworkForBusiness (Phase D);
// these tests cover the new read path and its business scoping.

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_homework_source.dart';

void main() {
  group('MockHomeworkSource business-wide reads', () {
    test('getHomeworkForBusiness returns every assignment in the business',
        () async {
      final source = MockHomeworkSource();
      final all = await source.getHomeworkForBusiness('biz_mock_001');
      final forClient = await source.getHomeworkForClient(
        'biz_mock_001',
        'usr_client_001',
      );
      // The seeded store assigns everything to one client, so the
      // business-wide read must be a superset of the per-client read.
      expect(all.length, greaterThanOrEqualTo(forClient.length));
      expect(all.every((h) => h.businessId == 'biz_mock_001'), isTrue);
    });

    test('assign then delete round-trips through the business view', () async {
      final source = MockHomeworkSource();
      final before = await source.getHomeworkForBusiness('biz_mock_001');
      final hw = await source.assignHomework(
        businessId: 'biz_mock_001',
        assignedByUserId: 'usr_owner_001',
        assignedToUserId: 'usr_client_001',
        assignedToUserName: 'Sam Client',
        title: 'Round-trip check',
      );
      final during = await source.getHomeworkForBusiness('biz_mock_001');
      expect(during.length, before.length + 1);
      expect(during.any((h) => h.id == hw.id), isTrue);

      await source.deleteHomework(hw.id);
      final after = await source.getHomeworkForBusiness('biz_mock_001');
      expect(after.length, before.length);
      expect(after.any((h) => h.id == hw.id), isFalse);
    });

    test('business reads are scoped to the given business', () async {
      final source = MockHomeworkSource();
      final other = await source.getHomeworkForBusiness('biz_other_999');
      expect(other, isEmpty);
    });
  });
}
