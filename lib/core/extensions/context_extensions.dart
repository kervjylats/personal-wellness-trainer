// lib/core/extensions/context_extensions.dart
//
// Extension methods on BuildContext for common theme and navigation shortcuts.
// Avoids repetitive Theme.of(context) and MediaQuery... calls.
//
// Core files import nothing from engine/, modules/, or data/.

import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  // ── Theme Shortcuts ───────────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  Color get errorColor => Theme.of(this).colorScheme.error;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ── Media Query Shortcuts ─────────────────────────────────────────────────────
  // Using the modern MediaQuery.sizeOf / paddingOf split APIs (Flutter 3.10+).
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);
  double get bottomInset => MediaQuery.viewInsetsOf(this).bottom;
  double get topPadding => MediaQuery.viewPaddingOf(this).top;

  // ── SnackBar ──────────────────────────────────────────────────────────────────
  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(this).colorScheme.error : null,
        duration: duration,
        action: action,
      ),
    );
  }

  void clearSnackBars() {
    ScaffoldMessenger.of(this).clearSnackBars();
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────────
  /// Shows a standard confirm dialog. Returns true on confirm, false on cancel,
  /// or null if dismissed by tapping outside.
  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: this,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(dialogContext).colorScheme.error,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
