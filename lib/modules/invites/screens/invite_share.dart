// lib/modules/invites/screens/invite_share.dart
// ═══════════════════════════════════════════════════════════════
// INVITE SHARE — real native sharing for invite links.
//
// The chat screen's Share button used to open an in-app grid whose every
// option just showed a SnackBar reading "coming in Phase 10", and invite
// links could only leave the device via "Copy code". Both now route here.
//
// Wraps share_plus so callers never touch the plugin directly, and
// degrades gracefully to a clipboard copy when sharing isn't available
// (e.g. a desktop VM with no share-sheet-capable app installed) — the
// link still gets to the other person.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

abstract final class InviteShare {
  /// Share [inviteUrl] through the platform share sheet (WhatsApp, SMS,
  /// email, …). [subject] is used by targets that support a subject line
  /// (email); most targets ignore it.
  ///
  /// Returns true when the share sheet was handed off successfully.
  /// On failure — or wherever sharing isn't supported — falls back to
  /// putting the link on the clipboard and tells the user, so this never
  /// dead-ends the one action a user took to send an invite.
  static Future<bool> share(
    BuildContext context, {
    required String inviteUrl,
    String? subject,
    String? message,
  }) async {
    final text = message == null ? inviteUrl : '$message\n\n$inviteUrl';
    // Captured BEFORE the await so the post-share feedback never touches
    // a BuildContext across an async gap (the widget may be gone by then).
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: subject),
      );
      if (result.status == ShareResultStatus.unavailable) {
        return await _copy(messenger, inviteUrl);
      }
      return true;
    } catch (_) {
      // No share sheet available — fall back to copy so the link is
      // still captureable.
      return await _copy(messenger, inviteUrl);
    }
  }

  /// Copy an invite link to the clipboard, with user-visible feedback.
  static Future<bool> copy(BuildContext context, String inviteUrl) =>
      _copy(ScaffoldMessenger.maybeOf(context), inviteUrl);

  static Future<bool> _copy(
    ScaffoldMessengerState? messenger,
    String inviteUrl,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: inviteUrl));
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text("Couldn't copy the invite link")),
      );
      return false;
    }
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Sharing is unavailable on this device, so the invite '
            'link was copied instead'),
      ),
    );
    return true;
  }
}