import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

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
            // QR code on desktop/web, so this is the real fallback path —
            // it needs to be actually copyable, not just visible.
            SelectableText(
              inviteUrl,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
