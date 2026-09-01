// lib/modules/activity/screens/create_activity_screen.dart
//
// The dynamic activity creation form.
// ALL form fields are driven by activity_fields from the active job config.
//
// CRITICAL TEST: Change jobs_config.json activity_fields for your job,
// hot restart → the form updates automatically with zero code change.
//
// Phase 9 fix (CRITICAL): activityFields and terminology.activity now read
// from activeJobConfigProvider instead of configProvider. Previously the
// create form always showed the platform-level fields, ignoring the
// job-specific fields entirely (e.g. a Pilates owner saw no Pilates fields).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/core/widgets/primary_button.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_profiles.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/engine/widgets/field_renderer.dart';
import 'package:personal_wellness_trainer/modules/activity/providers/activity_notifier.dart';

class CreateActivityScreen extends ConsumerStatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  ConsumerState<CreateActivityScreen> createState() =>
      _CreateActivityScreenState();
}

class _CreateActivityScreenState extends ConsumerState<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _values = {};
  bool _isSaving = false;

  List<PickerOption> _staffOptions   = [];
  List<PickerOption> _clientOptions  = [];

  @override
  void initState() {
    super.initState();
    _loadPickerOptions();
  }

  Future<void> _loadPickerOptions() async {
    if (!DataConfig.useMockData) return;

    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    final businessId = authState.profile.businessId;
    final staffProfiles  = await MockProfiles.getTeamForBusiness(businessId);
    final clientProfiles = await MockProfiles.getClientsForBusiness(businessId);

    if (!mounted) return;
    setState(() {
      _staffOptions = staffProfiles
          .where((p) => AppRole.fromString(p.role).isStaff)
          .map((p) => PickerOption(id: p.userId, label: p.displayName))
          .toList();
      _clientOptions = clientProfiles
          .map((p) => PickerOption(id: p.userId, label: p.displayName))
          .toList();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      setState(() => _isSaving = false);
      return;
    }

    final activity = await ref
        .read(activityNotifierProvider.notifier)
        .create(fields: Map<String, dynamic>.from(_values));

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (activity != null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    // Phase 9: read job-specific config — fields and terminology.
    final jobConfig = ref.watch(activeJobConfigProvider);
    final fields    = jobConfig.activityFields;
    final currency  = jobConfig.payment.currencyDefault;
    final label     = jobConfig.terminology.activity;

    if (fields.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('New $label')),
        body: const Center(
          child: Text(
            'No activity fields configured.\nAdd activity_fields to jobs_config.json.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('New $label')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
          children: [
            const SizedBox(height: AppSpacing.md),
            ...fields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FieldRenderer(
                  field: field,
                  value: _values[field.name],
                  currencySymbol: currency,
                  staffOptions: _staffOptions,
                  clientOptions: _clientOptions,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (v) => setState(() => _values[field.name] = v),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _isSaving
                ? const LoadingIndicator()
                : PrimaryButton(
                    label: 'Save $label',
                    onPressed: _submit,
                  ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
