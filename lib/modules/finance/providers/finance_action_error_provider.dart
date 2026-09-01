// lib/modules/finance/providers/finance_action_error_provider.dart
//
// StateProvider<String?> for finance mutation errors.
// Pattern from Blueprint Section 14, Rule R-09:
//   Every mutation: clear actionError → try → repo call → invalidateSelf → return.
//   Catch exceptions → set actionError → return null.
//   Shells listen to actionError and show SnackBar.
//
// This provider must be wired into ALL FOUR shells.
// Without this, finance errors are silent and the user sees nothing.
//
// Usage in shells:
//   ref.listen(financeActionErrorProvider, (_, error) {
//     if (error != null) {
//       context.showSnackBar(error);
//       ref.read(financeActionErrorProvider.notifier).state = null;
//     }
//   });

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the latest finance mutation error message.
/// null = no error. Non-null = show SnackBar and clear.
final financeActionErrorProvider = StateProvider<String?>((ref) => null);
