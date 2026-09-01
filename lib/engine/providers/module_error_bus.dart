// lib/engine/providers/module_error_bus.dart
//
// Shared error-state providers for module action errors.
// Both producers (modules) and consumers (shells/modules) import from here.
// Engine → module cross-imports are never permitted; this bus eliminates the need.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Agreements ────────────────────────────────────────────────────────────────

/// Written by: AgreementsNotifier.
/// Read by: NetworkScreen, OwnerShell.
final agreementActionErrorProvider = StateProvider<String?>((ref) => null);

// ── Messaging ─────────────────────────────────────────────────────────────────

/// Written by: MessagingNotifier, ConversationNotifier.
/// Read by: All shells (conversation + send errors).
final messagingActionErrorProvider = StateProvider<String?>((ref) => null);
