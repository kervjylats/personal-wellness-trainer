// lib/modules/agreements/providers/agreements_notifier.dart
//
// Riverpod AsyncNotifier for partnership agreements.
// Validates compatibility before proposing — uses the existing
// PermissionsEngine.areCategoriesCompatible() which reads the
// compatibility_matrix from industry_config.json.
//
// Throws/surfaces IncompatibleCategoriesException via agreementActionErrorProvider
// so the UI can display a human-readable message without crashing.
//
// Error provider lives in lib/engine/providers/module_error_bus.dart so that
// the team module (network_screen) can consume it without a cross-module import.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/agreement_model.dart';
import 'package:personal_wellness_trainer/data/models/partnership_request.dart';
import 'package:personal_wellness_trainer/data/repositories/agreements_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_agreements_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/engine/permissions/permissions_engine.dart';
import 'package:personal_wellness_trainer/engine/providers/module_error_bus.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final _agreementsRepositoryProvider = Provider<AgreementsRepository>((ref) {
  if (DataConfig.useMockData) return MockAgreementsSource();
  throw UnimplementedError('Supabase agreements source — Phase 10 only.');
});

// ── Notifier provider ─────────────────────────────────────────────────────────

final agreementsNotifierProvider =
    AsyncNotifierProvider<AgreementsNotifier, List<AgreementModel>>(
  AgreementsNotifier.new,
  dependencies: [authNotifierProvider],
);

// ── AgreementsNotifier ────────────────────────────────────────────────────────

class AgreementsNotifier extends AsyncNotifier<List<AgreementModel>> {
  static const String _tag = 'AgreementsNotifier';

  AgreementsRepository get _repo => ref.read(_agreementsRepositoryProvider);

  String get _businessId {
    final auth = ref.read(authNotifierProvider);
    if (auth is AuthAuthenticated) return auth.profile.businessId;
    throw StateError('AgreementsNotifier accessed without authenticated user.');
  }

  @override
  Future<List<AgreementModel>> build() async {
    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) return [];
    AppLogger.info('Loading agreements…', tag: _tag);
    return _repo.getAgreements(auth.profile.businessId);
  }

  // ── Read helpers ──────────────────────────────────────────────────────────────

  List<AgreementModel> get activeAgreements =>
      state.valueOrNull?.where((a) => a.isActive).toList() ?? [];

  List<AgreementModel> get pendingAgreements =>
      state.valueOrNull?.where((a) => a.isPending).toList() ?? [];

  // ── Propose ───────────────────────────────────────────────────────────────────

  /// Proposes a new agreement. Blocks if categories are not compatible.
  /// Owner category is the owner's selectedCategory from their profile.
  Future<AgreementModel?> proposeAgreement({
    required String ownerCategoryId,
    required String partnerUserId,
    required String partnerCategoryId,
    required double ownerCommissionPct,
    required double partnerCommissionPct,
    String? notes,
  }) async {
    // ── Role gate ──────────────────────────────────────────────────────────────
    // Only Owners (Pro) can initiate a deal. A non-Pro Partner can discuss,
    // accept, or decline an agreement already on the table (see
    // approveAgreement/declineAgreement below) but never propose one — that
    // right only exists once they've upgraded to Pro and become an Owner
    // themselves.
    final authForGate = ref.read(authNotifierProvider);
    if (authForGate is! AuthAuthenticated || authForGate.profile.role != 'owner') {
      ref.read(agreementActionErrorProvider.notifier).state =
          'Only Owners can propose a new agreement. Partners can discuss, '
          'accept, or decline agreements already proposed to them.';
      return null;
    }

    // ── Compatibility check (Blueprint §14 — compatibility_matrix is authority) ──
    final engine = ref.read(permissionsEngineProvider);
    final compatible = engine.areCategoriesCompatible(
      ownerCategoryId,
      partnerCategoryId,
    );
    if (!compatible) {
      ref.read(agreementActionErrorProvider.notifier).state =
          'These two categories are not compatible for a partnership agreement. '
          'Check the compatibility settings in your configuration.';
      return null;
    }

    final prevState = state;
    state = const AsyncLoading();
    try {
      final auth = ref.read(authNotifierProvider) as AuthAuthenticated;
      final agreement = await _repo.proposeAgreement(
        businessId: _businessId,
        ownerUserId: auth.profile.userId,
        partnerUserId: partnerUserId,
        partnerBusinessId: _businessId,
        categoryId: partnerCategoryId,
        ownerCommissionPct: ownerCommissionPct,
        partnerCommissionPct: partnerCommissionPct,
        notes: notes,
      );
      state = AsyncData([...prevState.valueOrNull ?? [], agreement]);
      AppLogger.info('Agreement proposed: ${agreement.id}', tag: _tag);
      return agreement;
    } catch (e, st) {
      AppLogger.error(
          'proposeAgreement failed', tag: _tag, error: e, stackTrace: st);
      ref.read(agreementActionErrorProvider.notifier).state =
          'Could not propose agreement. Please try again.';
      state = prevState;
      return null;
    }
  }

  // ── Approve ───────────────────────────────────────────────────────────────────

  Future<bool> approveAgreement(String agreementId) async {
    return _changeStatus(
      agreementId: agreementId,
      action: () => _repo.approveAgreement(
        agreementId: agreementId,
        businessId: _businessId,
      ),
      errorMessage: 'Could not approve agreement.',
    );
  }

  // ── Decline ───────────────────────────────────────────────────────────────────

  Future<bool> declineAgreement(String agreementId) async {
    return _changeStatus(
      agreementId: agreementId,
      action: () => _repo.declineAgreement(
        agreementId: agreementId,
        businessId: _businessId,
      ),
      errorMessage: 'Could not decline agreement.',
    );
  }

  // ── End ───────────────────────────────────────────────────────────────────────

  Future<bool> endAgreement(String agreementId) async {
    return _changeStatus(
      agreementId: agreementId,
      action: () => _repo.endAgreement(
        agreementId: agreementId,
        businessId: _businessId,
      ),
      errorMessage: 'Could not end agreement.',
    );
  }

  // ── Helper ────────────────────────────────────────────────────────────────────

  Future<bool> _changeStatus({
    required String agreementId,
    required Future<AgreementModel> Function() action,
    required String errorMessage,
  }) async {
    try {
      final updated = await action();
      final current = state.valueOrNull ?? [];
      final index = current.indexWhere((a) => a.id == agreementId);
      if (index != -1) {
        final next = List<AgreementModel>.from(current);
        next[index] = updated;
        state = AsyncData(next);
      }
      AppLogger.info(
          'Agreement $agreementId → ${updated.status}', tag: _tag);
      return true;
    } catch (e, st) {
      AppLogger.error(errorMessage, tag: _tag, error: e, stackTrace: st);
      ref.read(agreementActionErrorProvider.notifier).state = errorMessage;
      return false;
    }
  }

  // ── Marketplace hand-off ─────────────────────────────────────────────────────

  /// Called after an owner accepts a marketplace [PartnershipRequest].
  /// Creates TWO agreement records, one per business, since a partnership
  /// is inherently mutual — the request already carries both a
  /// senderCategoryId and a receiverCategoryId, i.e. both sides are
  /// exchanging access to a category, not just one.
  ///
  ///  - The accepting owner's own side is created AND immediately
  ///    approved, using the rates they set in the confirmation step —
  ///    it's their own business, their own decision, no reason to make
  ///    them wait on anyone else.
  ///  - The sender's side is created as 'proposed' under the SENDER's
  ///    own business, starting from the same rates as a default. The
  ///    sender sees it appear in their own Agreements list next time
  ///    they check — through the exact same approve/decline flow that
  ///    already exists for the within-business case — and can adjust
  ///    the rates for their own business before approving.
  ///
  /// PHASE 10 NOTE: writing directly into another tenant's (the
  /// sender's) business data only works here because mock mode uses one
  /// shared in-memory store. Once real per-tenant Supabase RLS is in
  /// place, that second write needs to go through a secure backend
  /// function instead of a direct client-side repository call — a
  /// client should never be able to write into another tenant's rows
  /// directly.
  Future<bool> createMutualAgreementFromRequest({
    required PartnershipRequest request,
    required double ownerCommissionPct,
    required double partnerCommissionPct,
  }) async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return false;

    final prevState = state;
    state = const AsyncLoading();
    try {
      // My own side: propose then immediately approve.
      final proposed = await _repo.proposeAgreement(
        businessId: _businessId,
        ownerUserId: auth.profile.userId,
        partnerUserId: request.senderOwnerUserId,
        partnerBusinessId: request.senderBusinessId,
        categoryId: request.senderCategoryId,
        ownerCommissionPct: ownerCommissionPct,
        partnerCommissionPct: partnerCommissionPct,
        notes: 'Formed via marketplace request ${request.id}.',
      );
      final approved = await _repo.approveAgreement(
        agreementId: proposed.id,
        businessId: _businessId,
      );

      // The sender's side: proposed, waiting for their own review.
      await _repo.proposeAgreement(
        businessId: request.senderBusinessId,
        ownerUserId: request.senderOwnerUserId,
        partnerUserId: auth.profile.userId,
        partnerBusinessId: _businessId,
        categoryId: request.receiverCategoryId,
        ownerCommissionPct: partnerCommissionPct,
        partnerCommissionPct: ownerCommissionPct,
        notes: 'Formed via marketplace request ${request.id}.',
      );

      state = AsyncData([...prevState.valueOrNull ?? [], approved]);
      AppLogger.info(
          'Mutual agreement created from request ${request.id}', tag: _tag);
      return true;
    } catch (e, st) {
      AppLogger.error('createMutualAgreementFromRequest failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(agreementActionErrorProvider.notifier).state =
          'Could not finalize the partnership. Please try again.';
      state = prevState;
      return false;
    }
  }
}

