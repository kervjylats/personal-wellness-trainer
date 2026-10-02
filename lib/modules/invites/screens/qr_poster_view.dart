// lib/modules/invites/screens/qr_poster_view.dart
//
// A poster-sized, shareable invite code for printing or putting on a wall.
//
// An Owner/coach prints this (or shares it as an image), a prospective
// client sees it at the studio / on a flyer / in an ad, scans it with
// their phone, and lands directly on the redemption screen with the code
// filled in. That's the "Jim the nutritionist prints his QR and puts it on
// the wall" path.
//
// This is deliberately a VIEW of an existing link rather than a new
// invite: it renders exactly what InviteLinkBuilder produced, so the
// printed code and the shared link can never disagree.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/modules/invites/screens/invite_share.dart';

class QrPosterView extends StatelessWidget {
  const QrPosterView({
    super.key,
    required this.inviteUrl,
    required this.businessName,
    this.headline,
  });

  /// The full, tappable invite link (InviteLinkBuilder.buildInviteUrl).
  final String inviteUrl;

  /// Shown above the code so the printed page identifies whose business
  /// this is.
  final String businessName;

  /// Optional short pitch line, e.g. "Scan to join as a client".
  final String? headline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                businessName,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall.copyWith(color: primary),
              ),
              if (headline != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  headline!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              // Generous quiet zone so the code still scans after being
              // printed or photographed off a wall.
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  border: Border.all(color: AppColors.lockedBorder),
                ),
                child: Center(
                  child: QrImageView(
                    data: inviteUrl,
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SelectableText(
                inviteUrl,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  InviteShare.share(
                    context,
                    inviteUrl: inviteUrl,
                    subject: 'Join $businessName',
                    message: 'Scan this code or open the link to join '
                        '$businessName.',
                  );
                },
                icon: const Icon(Icons.ios_share, size: 18),
                label: const Text('Share invite'),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invite link copied — paste it anywhere'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: const Text('Copy link'),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}