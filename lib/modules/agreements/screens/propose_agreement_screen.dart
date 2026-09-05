// lib/modules/agreements/screens/propose_agreement_screen.dart
//
// Form for proposing a new partnership agreement.
// Owner selects their category, the partner, and the commission split.
// AgreementsNotifier validates compatibility before submitting —
// incompatible pairs are blocked with a clear error message.
//
// Partners are loaded via _activePartnersProvider — a private provider that
// reads TeamRepository from the data layer directly. This avoids a
// cross-module import of the team module (Blueprint §14).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/data/repositories/team_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_team_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/agreements_notifier.dart';
import 'package:personal_wellness_trainer/modules/team/providers/business_features_provider.dart';
import 'package:personal_wellness_trainer/core/widgets/app_empty_state.dart';

// ── Private partner data provider ─────────────────────────────────────────────
//
// Reads directly from the TeamRepository (data layer) — no team module import.
// Returns only active partners so the dropdown shows valid proposal targets.

final _teamRepoForAgreementsProvider = Provider<TeamRepository>((ref) {
  if (DataConfig.useMockData) return MockTeamSource();
  throw UnimplementedError('Supabase team source — Phase 10 only.');
});

final _activePartnersProvider =
    FutureProvider.autoDispose<List<TeamMemberModel>>(
  (ref) async {
    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) return [];
    final repo = ref.read(_teamRepoForAgreementsProvider);
    final all = await repo.getMembers(auth.profile.businessId, role: 'partner');
    return all.where((m) => m.isActive).toList();
  },
  // Riverpod requires any provider whose body reads another provider to
  // declare that as a dependency, so the override correctly cascades
  // when this provider is used somewhere that overrides authNotifierProvider
  // (e.g. lib/dev_tools/qa_console_screen.dart's per-role panels). Without
  // this, Riverpod throws: "Tried to read Provider<...> from a place where
  // one of its dependencies were overridden but the provider is not."
  dependencies: [authNotifierProvider],
);

// ── Screen ────────────────────────────────────────────────────────────────────

class ProposeAgreementScreen extends ConsumerStatefulWidget {
  const ProposeAgreementScreen({super.key});

  @override
  ConsumerState<ProposeAgreementScreen> createState() =>
      _ProposeAgreementScreenState();
}

class _ProposeAgreementScreenState
    extends ConsumerState<ProposeAgreementScreen> {
  String? _ownerCategory;
  String? _selectedPartnerId;
  String? _selectedPartnerCategoryId;
  double _ownerPct = 20.0;
  double _partnerPct = 80.0;
  final _notesController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Defensive re-check — see marketplace_screen.dart's identical guard
    // for why: nav already hides the entry point, this just stops a stale
    // deep link or a flag flip from a live session actually rendering the
    // form. Only Owners reach this screen at all, and the notifier-level
    // gate in agreements_notifier.dart backs this up either way.
    final features = ref.watch(businessFeaturesProvider);
    if (!features.partnersEnabled || !features.agreementsEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Propose Agreement')),
        body: const AppEmptyState(
          icon: Icons.receipt_long_outlined,
          headline: 'Agreements are turned off',
          subtext: 'This business has Agreements & Deals disabled.',
        ),
      );
    }

    final config        = ref.watch(configProvider).valueOrNull;
    final categories    = config?.industry.categories ?? [];
    final partnersAsync = ref.watch(_activePartnersProvider);
    final partners      = partnersAsync.valueOrNull ?? [];

    final auth = ref.watch(authNotifierProvider);
    if (auth is AuthAuthenticated) {
      _ownerCategory ??= auth.profile.selectedCategory ??
          (categories.isNotEmpty ? categories.first.id : null);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Propose Agreement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            _buildOwnerCategoryField(categories),
            const SizedBox(height: AppSpacing.md),
            _buildPartnerField(partnersAsync, partners),
            const SizedBox(height: AppSpacing.md),
            _buildCommissionSliders(),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildSubmitButton(),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerCategoryField(List<dynamic> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your category', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: _ownerCategory,
          decoration: const InputDecoration(labelText: 'Your category'),
          items: categories.map((c) => DropdownMenuItem<String>(
            value: c.id, child: Text(c.label),
          )).toList(),
          onChanged: (v) => setState(() => _ownerCategory = v),
        ),
      ],
    );
  }

  Widget _buildPartnerField(AsyncValue<dynamic> partnersAsync, List<dynamic> partners) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Partner', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        if (partnersAsync.isLoading)
          const LinearProgressIndicator()
        else if (partners.isEmpty)
          Text('No active partners found. Invite a partner first.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600))
        else
          DropdownButtonFormField<String>(
            initialValue: _selectedPartnerId,
            decoration: const InputDecoration(labelText: 'Select partner'),
            items: partners.map((p) => DropdownMenuItem<String>(
              value: p.userId,
              child: Text('${p.displayName} (${p.categoryId ?? 'no category'})'),
            )).toList(),
            onChanged: (v) => setState(() {
              _selectedPartnerId = v;
              _selectedPartnerCategoryId = partners.firstWhere((p) => p.userId == v).categoryId;
            }),
          ),
      ],
    );
  }

  Widget _buildCommissionSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Commission split', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You: ${_ownerPct.round()}%', style: AppTextStyles.bodyMedium),
                Slider(
                  value: _ownerPct, min: 0, max: 100, divisions: 20,
                  onChanged: (v) => setState(() { _ownerPct = v; _partnerPct = 100 - v; }),
                ),
              ],
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Partner: ${_partnerPct.round()}%', style: AppTextStyles.bodyMedium),
                Slider(
                  value: _partnerPct, min: 0, max: 100, divisions: 20,
                  onChanged: (v) => setState(() { _partnerPct = v; _ownerPct = 100 - v; }),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _loading || _selectedPartnerId == null ? null : _propose,
        child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Send Proposal'),
      ),
    );
  }

  Future<void> _propose() async {
    if (_ownerCategory == null || _selectedPartnerCategoryId == null) return;
    setState(() => _loading = true);
    final result = await ref
        .read(agreementsNotifierProvider.notifier)
        .proposeAgreement(
          ownerCategoryId: _ownerCategory!,
          partnerUserId: _selectedPartnerId!,
          partnerCategoryId: _selectedPartnerCategoryId!,
          ownerCommissionPct: _ownerPct,
          partnerCommissionPct: _partnerPct,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
    if (mounted) {
      setState(() => _loading = false);
      if (result != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agreement proposed successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}
