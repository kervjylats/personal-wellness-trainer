// lib/modules/team/widgets/invite_dialog.dart
//
// Shared by every screen that generates an invite link (owner's Network
// screen for Partners/Staff/Clients; the client Network screen for
// inviting other clients). Extracted so there's one implementation
// instead of a copy per screen — generateLink() itself already scopes
// correctly to whichever role/business calls it, so this dialog only
// ever needs the target role, nothing role-specific baked in.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/engine/invites/invite_link_notifier.dart';
import 'package:personal_wellness_trainer/modules/invites/screens/qr_invite_dialog.dart';

class InviteDialog extends ConsumerStatefulWidget {
  const InviteDialog({super.key, required this.role});
  final String role;

  @override
  ConsumerState<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<InviteDialog> {
  bool _loading = false;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref
        .read(inviteLinkNotifierProvider.notifier)
        .generateLink(targetRole: widget.role);

    if (!mounted) return;

    setState(() => _loading = false);

    switch (result) {
      case InviteLinkCreated(:final link):
        Navigator.of(context).pop();
        unawaited(showDialog<void>(
          context: context,
          builder: (_) => QrInviteDialog(inviteUrl: link.token),
        ));

      case InviteLinkError(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = switch (widget.role) {
      'partner' => 'Partner',
      'staff'   => 'Staff Member',
      _         => 'Client',
    };

    return AlertDialog(
      title: Text('Invite $roleLabel'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate a one-time invite link for a new $roleLabel to join your platform.',
            style: AppTextStyles.bodyMedium,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _generate,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate Link'),
        ),
      ],
    );
  }
}
