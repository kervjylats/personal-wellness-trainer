// lib/engine/auth/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/icon_lookup.dart';
import 'package:personal_wellness_trainer/core/utils/validators.dart';
import 'package:personal_wellness_trainer/core/widgets/app_text_field.dart';
import 'package:personal_wellness_trainer/core/widgets/primary_button.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/config/job_definition.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/industry_config.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/core/extensions/context_extensions.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bioController = TextEditingController();

  int _step = 0;                // 0 = category/job, 1 = business details, 2 = bio
  JobDefinition? _selectedJob;
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_selectedJob == null) return;
    setState(() => _isSaving = true);
    final primaryColorHex = _selectedJob!.primaryColor;
    final ok = await ref.read(authNotifierProvider.notifier).completeOnboarding(
          businessName: _businessNameController.text.trim(),
          category: _selectedJob!.id,
          primaryColorHex: primaryColorHex,
          jobId: _selectedJob!.id,
        );
    if (!mounted) return;

    if (ok) {
      if (_bioController.text.isNotEmpty) {
        ref.read(authNotifierProvider.notifier).updateProfile(
              displayName: _businessNameController.text.trim(),
            );
      }
      context.goNamed(RouteNames.ownerShell);
    } else {
      setState(() => _isSaving = false);
      context.showSnackBar(
        'Could not save your profile. Please try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final registryAsync = ref.watch(jobsRegistryProvider);
    final configAsync = ref.watch(configProvider); 
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: registryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
              child: Text('Could not load job types.\n$e',
                  style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            ),
          ),
          data: (registry) {
            final categories = configAsync.valueOrNull?.industry.jobCategories ?? [];
            return _buildStepper(context, registry, categories);
          },
        ),
      ),
    );
  }

  Widget _buildStepper(BuildContext context, JobsRegistry registry, List<JobCategory> categories) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH, vertical: AppSpacing.md),
          child: _StepIndicator(currentStep: _step, totalSteps: 3),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey<int>(_step),
              child: _stepContent(registry, categories),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepContent(JobsRegistry registry, List<JobCategory> categories) {
    switch (_step) {
      case 0:
        return _JobSelectionStep(
          registry: registry,
          categories: categories,
          selectedCategoryId: _selectedCategoryId,
          selectedJobId: _selectedJob?.id,
          onCategorySelected: (catId) => setState(() => _selectedCategoryId = catId),
          onJobSelected: (job) => setState(() => _selectedJob = job),
          onNext: _selectedJob != null
              ? () => setState(() => _step = 1)
              : null,
          onBackToCategories: _selectedCategoryId != null
              ? () => setState(() => _selectedCategoryId = null)
              : null,
        );
      case 1:
        return _BusinessDetailsStep(
          formKey: _formKey,
          nameController: _businessNameController,
          taglineController: _taglineController,
          descriptionController: _descriptionController,
          jobLabel: _selectedJob?.label ?? 'Business',
          onBack: () => setState(() => _step = 0),
          onNext: () {
            if (_formKey.currentState?.validate() ?? false) {
              setState(() => _step = 2);
            }
          },
        );
      case 2:
        return _PersonalBioStep(
          bioController: _bioController,
          isSaving: _isSaving,
          onBack: () => setState(() => _step = 1),
          onFinish: _finish,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: List.generate(totalSteps, (i) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            decoration: BoxDecoration(
              color: i <= currentStep ? colorScheme.primary : colorScheme.outline.withAlpha(40),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      )),
    );
  }
}

// ── Step 0: Category then Job selection ──────────────────────────────────────

class _JobSelectionStep extends StatelessWidget {
  const _JobSelectionStep({
    required this.registry, required this.categories,
    required this.selectedCategoryId, required this.selectedJobId,
    required this.onCategorySelected, required this.onJobSelected,
    required this.onNext, required this.onBackToCategories,
  });
  final JobsRegistry registry;
  final List<JobCategory> categories;
  final String? selectedCategoryId;
  final String? selectedJobId;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<JobDefinition> onJobSelected;
  final VoidCallback? onNext;
  final VoidCallback? onBackToCategories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (selectedCategoryId == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Icon(Icons.auto_awesome, size: 48, color: colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            const Text('What type of practice do you run?',
                style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            const Text('Choose a category to see available jobs.',
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.3,
                children: categories.map((cat) {
                  Color catColor = colorScheme.primary;
                  try {
                    catColor = Color(int.parse('FF${cat.color.replaceAll('#', '')}', radix: 16));
                  } catch (_) {}
                  return GestureDetector(
                    onTap: () => onCategorySelected(cat.id),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [catColor.withAlpha(30), catColor.withAlpha(10)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: catColor.withAlpha(40)),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: catColor.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(industryIconFromString(cat.icon), color: catColor, size: 28),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(cat.label, style: AppTextStyles.titleSmall,
                              textAlign: TextAlign.center, maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    } else {
      final jobs = registry.all.where((j) => j.category == selectedCategoryId).toList();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: onBackToCategories,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to Categories'),
              style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemCount: jobs.length,
                itemBuilder: (context, i) {
                  final job = jobs[i];
                  final isSelected = selectedJobId == job.id;
                  Color jobColor;
                  try {
                    jobColor = Color(int.parse('FF${job.primaryColor.replaceAll('#', '')}', radix: 16));
                  } catch (_) {
                    jobColor = colorScheme.primary;
                  }
                  return GestureDetector(
                    onTap: () => onJobSelected(job),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        border: Border.all(
                          color: isSelected ? jobColor : colorScheme.outline.withAlpha(40),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: jobColor.withAlpha(40), blurRadius: 6)]
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: jobColor.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(industryIconFromString(job.icon), color: jobColor, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(job.label,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    )),
                                if (job.description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(job.description,
                                      style: AppTextStyles.caption.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AnimatedScale(
                            scale: isSelected ? 1.0 : 0.8,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? jobColor : colorScheme.outline.withAlpha(60),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Continue',
              onPressed: onNext,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      );
    }
  }
}

// ── Step 1: Business details ───────────────────────────────────────────────────

class _BusinessDetailsStep extends StatelessWidget {
  const _BusinessDetailsStep({
    required this.formKey,
    required this.nameController,
    required this.taglineController,
    required this.descriptionController,
    required this.jobLabel,
    required this.onBack,
    required this.onNext,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController taglineController;
  final TextEditingController descriptionController;
  final String jobLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH, vertical: AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.storefront_outlined, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text('Tell us about your $jobLabel',
                style: AppTextStyles.headlineLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xxl),
            AppTextField(
              hint: 'Your business name',
              label: 'Business Name',
              controller: nameController,
              validator: AppValidators.required(fieldName: 'Business Name'),
              prefixIcon: Icons.business,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              hint: 'A short tagline (optional)',
              label: 'Tagline',
              controller: taglineController,
              prefixIcon: Icons.short_text,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              hint: 'Describe your services, philosophy...',
              label: 'Description (optional)',
              controller: descriptionController,
              maxLines: 3,
              minLines: 2,
              maxLength: 200,
              prefixIcon: Icons.description,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(label: 'Continue', onPressed: onNext),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onBack, child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Personal bio ──────────────────────────────────────────────────────

class _PersonalBioStep extends StatelessWidget {
  const _PersonalBioStep({
    required this.bioController,
    required this.isSaving,
    required this.onBack,
    required this.onFinish,
  });
  final TextEditingController bioController;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.person_outline, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          const Text('About you',
              style: AppTextStyles.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          const Text('Your clients will see this on your profile.',
              style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            hint: 'Write a short bio (optional)',
            label: 'Your Bio',
            controller: bioController,
            maxLines: 4,
            minLines: 2,
            maxLength: 300,
            prefixIcon: Icons.edit_note,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(
            label: 'Finish Setup',
            onPressed: isSaving ? null : onFinish,
            isLoading: isSaving,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: isSaving ? null : onBack, child: const Text('Back')),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}