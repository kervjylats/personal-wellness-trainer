// lib/modules/finance/providers/finance_repo_resolver.dart
//
// Single source of truth for resolving the FinanceRepository implementation.
// Previously _resolveRepository() was copy-pasted verbatim in both
// CommissionNotifier and TransactionNotifier (100% identical). Now one place.
//
// In Phase 10: replace MockFinanceSource() with SupabaseFinanceSource() here
// and both notifiers automatically get the real backend.

import 'package:personal_wellness_trainer/data/repositories/finance_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_finance_source.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

/// Returns the appropriate [FinanceRepository] for the current data config.
/// Phase 10: swap MockFinanceSource() → SupabaseFinanceSource() here only.
FinanceRepository resolveFinanceRepository() {
  if (DataConfig.useMockData) return MockFinanceSource();
  throw UnimplementedError(
    'Real finance source not available until Phase 10. '
    'Set DataConfig.useMockData = true for development.',
  );
}
