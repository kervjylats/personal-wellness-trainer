// lib/modules/invites/screens/qr_invite_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/modules/invites/screens/invite_share.dart';

/// Shows an invite as a scannable QR code alongside the same value as
/// selectable text, with Share and Copy actions.
///
/// [inviteUrl] is expected to be a full, tappable link built by
/// `InviteLinkBuilder.buildInviteUrl` — so the QR, the copied text and
/// the shared message all carry an identical payload that actually
/// resolves back into the redemption screen. It previously received a
/// bare token on the owner invite path, which produced a QR that a
/// phone camera could read but no phone could open.
class QrInviteDialog extends StatelessWidget {
  final String inviteUrl;
  const QrInviteDialog({super.key, required this.inviteUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Scan to Join', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            QrImageView(
              data: inviteUrl,
              size: 200,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: AppSpacing.md),
            // SelectableText (not plain Text): there's no camera to scan a
            // QR code on desktop/web, so this is the real fallback path �?"
            // it needs to be actually copyable, not just visible.
            SelectableText(
              inviteUrl,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            // Share first: the whole point of an invite is getting it to
            // the other person, so the native share sheet (WhatsApp, SMS,
            // email) is the primary action. Copy stays as the fallback for
            // anywhere sharing isn't available.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    InviteShare.share(
                      context,
                      inviteUrl: inviteUrl,
                      subject: "You're invited",
                    );
                  },
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text('Share'),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite code copied')),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('Copy code'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}