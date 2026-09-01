import 'package:personal_wellness_trainer/data/models/progress_entry_model.dart';
import 'package:personal_wellness_trainer/data/repositories/progress_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockProgressSource with MockSourceMixin implements ProgressRepository {
  static const String _businessId = 'biz_mock_001';

  static final List<ProgressEntryModel> _entries = [
    ProgressEntryModel(
      id: 'prog_001',
      businessId: _businessId,
      clientUserId: 'usr_client_001',
      date: DateTime.now().subtract(const Duration(days: 14)),
      photoUrls: const ['mock://photos/front_week1.jpg', 'mock://photos/side_week1.jpg'],
      metrics: const {'weight': 82.5, 'body_fat': 22.0},
      notes: 'Starting point. Feeling good.',
    ),
    ProgressEntryModel(
      id: 'prog_002',
      businessId: _businessId,
      clientUserId: 'usr_client_001',
      date: DateTime.now().subtract(const Duration(days: 7)),
      photoUrls: const ['mock://photos/front_week2.jpg'],
      metrics: const {'weight': 81.0, 'body_fat': 21.0},
      notes: 'Dropped 1.5 kg this week!',
    ),
  ];

  static int _idCounter = 10;

  @override
  Future<List<ProgressEntryModel>> getEntries(
    String businessId,
    String clientUserId,
  ) async {
    await simulateNetworkDelay();
    return _entries
        .where((e) => e.businessId == businessId && e.clientUserId == clientUserId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<ProgressEntryModel> addEntry({
    required String businessId,
    required String clientUserId,
    List<String> photoUrls = const [],
    Map<String, double> metrics = const {},
    String? notes,
  }) async {
    await simulateNetworkDelay();
    _idCounter++;
    final entry = ProgressEntryModel(
      id: 'prog_$_idCounter',
      businessId: businessId,
      clientUserId: clientUserId,
      date: DateTime.now(),
      photoUrls: photoUrls,
      metrics: metrics,
      notes: notes,
    );
    _entries.add(entry);
    return entry;
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    await simulateNetworkDelay();
    _entries.removeWhere((e) => e.id == entryId);
  }
}