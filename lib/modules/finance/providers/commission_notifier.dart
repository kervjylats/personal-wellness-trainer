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

      if (role.isOwner) {
        // Owed BY my business (Mark Paid lives on these) merged with
        // owed TO me — on a marketplace collab the counterparty's
        // payment books a commission whose businessId is their business
        // but partnerId is ME, so without this an owner-role payee
        // would never see money coming to them.
        final owed = await _repo.getCommissions(profile.businessId);
        final payable =
            await _repo.getCommissionsForPartner(profile.userId);
        final all = [...owed, ...payable];
        all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return all;
      }
      if (role.isPartner) {
        return await _repo.getCommissionsForPartner(profile.userId);
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
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return false;
    try {
      // The payout row records who actually sent the money — the
      // signing-in business, not a hardcoded seed name.
      await _repo.markCommissionPaid(
        commissionId,
        payerUserId: auth.profile.userId,
        payerName: auth.profile.businessName ?? auth.profile.displayName,
      );
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
