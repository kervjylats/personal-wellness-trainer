// lib/modules/activity/providers/activity_action_error_provider.dart
//
// StateProvider<String?> for activity mutation errors.
// Pattern from Blueprint Section 14, Rule R-09:
//   Every mutation: clear actionError → try → repo call → invalidateSelf → return.
//   Catch exceptions → set actionError → return null.
//   Shells listen to actionError and show SnackBar.
//
// This provider must be wired into ALL FOUR shells.
// Without this, activity errors are silent and the user sees nothing.
//
// Usage in shells (add alongside financeActionErrorProvider):
//   ref.listen(activityActionErrorProvider, (_, error) {
//     if (error != null && mounted) {
//       context.showSnackBar(error, isError: true);
//       ref.read(activityActionErrorProvider.notifier).state = null;
//     }
//   });

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the latest activity mutation error message.
/// null = no error. Non-null = show SnackBar and clear.
final activityActionErrorProvider = StateProvider<String?>((ref) => null);
