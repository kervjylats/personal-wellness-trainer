// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/theme/app_theme.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/branding_override_notifier.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/navigation/app_router.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart'; 
import 'package:personal_wellness_trainer/config/buyer_config.dart'; // ◄ Fixed: Removed "/lib/" segment!
import 'package:personal_wellness_trainer/modules/activity/registry/activity_registry.dart';
import 'package:personal_wellness_trainer/modules/agreements/registry/agreements_registry.dart';
import 'package:personal_wellness_trainer/modules/finance/registry/finance_registry.dart';
import 'package:personal_wellness_trainer/modules/team/registry/team_registry.dart';
import 'package:personal_wellness_trainer/modules/reviews/registry/reviews_registry.dart';
import 'package:personal_wellness_trainer/modules/media/registry/media_registry.dart';
import 'package:personal_wellness_trainer/modules/scheduling/registry/scheduling_registry.dart';
import 'package:personal_wellness_trainer/modules/catalog/registry/catalog_registry.dart';
import 'package:personal_wellness_trainer/modules/inventory/registry/inventory_registry.dart';
import 'package:personal_wellness_trainer/modules/gps/registry/gps_registry.dart';
import 'package:personal_wellness_trainer/modules/delivery_fees/registry/delivery_fees_registry.dart';
import 'package:personal_wellness_trainer/modules/chat/registry/chat_registry.dart';
import 'package:personal_wellness_trainer/modules/reservations/registry/reservations_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerModuleWidgets();

  if (!DataConfig.useMockData) {
    await Supabase.initialize(
      url: BuyerConfig.supabaseUrl,
      // supabase_flutter renamed `anonKey` to `publishableKey` (same value,
      // matches Supabase's newer API-key terminology). BuyerConfig's field
      // is still called supabaseAnonKey since that's what buyers will find
      // labeled in their own Supabase dashboard.
      publishableKey: BuyerConfig.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: AppEngine()));
}

void _registerModuleWidgets() {
  ActivityRegistry.register();
  AgreementsRegistry.register();
  FinanceRegistry.register();
  TeamRegistry.register();
  ReviewsRegistry.register();
  MediaRegistry.register();
  SchedulingRegistry.register();
  CatalogRegistry.register();
  InventoryRegistry.register();
  GpsRegistry.register();
  DeliveryFeesRegistry.register();
  ReservationsRegistry.register();
  ChatRegistry.register();
}

class AppEngine extends ConsumerWidget {
  const AppEngine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(configProvider);

    return configAsync.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.fallback,
        home: const FullScreenLoader(message: 'Loading configuration…'),
      ),
      error: (error, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.fallback,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: AppSpacing.iconSizeXxl,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Failed to load configuration',
                    style: AppTextStyles.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Check that assets/config/industry_config.json '
                    'and assets/config/app_config.json exist and are valid.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (config) {
        final branding = ref.watch(brandingOverrideProvider);
        final jobConfig = ref.watch(activeJobConfigProvider);

        final hexColor =
            branding.primaryColorHex ?? jobConfig.primaryColor;
        final primaryColor = _colorFromHex(hexColor);
        final appName = branding.businessName ?? config.industry.appName;
        final router = ref.watch(goRouterProvider);

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: appName,
          theme: AppTheme.build(
            primaryColor: primaryColor,
            jobTheme: jobConfig.theme,
          ),
          routerConfig: router,
        );
      },
    );
  }

  Color _colorFromHex(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      if (cleaned.length != 6) return AppTheme.fallback.colorScheme.primary;
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppTheme.fallback.colorScheme.primary;
    }
  }
}