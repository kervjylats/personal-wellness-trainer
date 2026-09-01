// lib/modules/finance/providers/commission_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/commission_model.dart';
import 'package:personal_wellness_trainer/data/repositories/finance_repository.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/finance_action_error_provider.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/finance_repo_resolver.dart';

final commissionNotifierProvider =
    AsyncNotifierProvider<CommissionNotifier, List<CommissionModel>>(
  CommissionNotifier.new,
  dependencies: [authNotifierProvider],
);

class CommissionNotifier extends AsyncNotifier<List<CommissionModel>> {
  static const String _tag = 'CommissionNotifier';
  late FinanceRepository _repo; // ◄ Fixed: Removed 'final' to allow safe re-initialization

  @override
  Future<List<CommissionModel>> build() async {
    try {
      _repo = resolveFinanceRepository();
      final authState = ref.watch(authNotifierProvider);
      if (authState is! AuthAuthenticated) return [];

      final profile = authState.profile;
      final role    = AppRole.fromString(profile.role);

      AppLogger.debug('CommissionNotifier: loading for ${role.value}', tag: _tag);

      if (role.isOwner) return await _repo.getCommissions(profile.businessId);
      if (role.isPartner) {
        return await _repo.getCommissionsForPartner(
            profile.businessId, profile.userId);
      }
      return [];
    } catch (e, st) {
      AppLogger.error(
        'CommissionNotifier build failed critically. Check logs.',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<bool> markPaid(String commissionId) async {
    ref.read(financeActionErrorProvider.notifier).state = null;
    try {
      await _repo.markCommissionPaid(commissionId);
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      AppLogger.error(
        'CommissionNotifier: markPaid failed', tag: _tag, error: e, stackTrace: st);
      ref.read(financeActionErrorProvider.notifier).state =
          'Failed to mark commission as paid. Please try again.';
      return false;
    }
  }
}
