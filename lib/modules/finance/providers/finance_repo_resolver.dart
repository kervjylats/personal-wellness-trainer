// lib/modules/finance/providers/finance_repo_resolver.dart
//
// Single source of truth for resolving the FinanceRepository implementation.
// Previously _resolveRepository() was copy-pasted verbatim in both
// CommissionNotifier and TransactionNotifier (100% identical). Now one place.
//
// Real Supabase backend wired in below — flip DataConfig.useMockData to
// switch, both notifiers (and anything else using this resolver) follow.

import 'package:personal_wellness_trainer/data/repositories/finance_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_finance_source.dart';
import 'package:personal_wellness_trainer/data/sources/supabase/supabase_finance_source.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

/// Returns the appropriate [FinanceRepository] for the current data config.
FinanceRepository resolveFinanceRepository() {
  if (DataConfig.useMockData) return MockFinanceSource();
  return SupabaseFinanceSource();
}
