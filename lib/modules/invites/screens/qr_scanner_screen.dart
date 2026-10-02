// lib/modules/invites/screens/qr_scanner_screen.dart
//
// Scan an invite QR code on a device with a camera.
//
// The other half of qr_invite_dialog.dart: an Owner prints/posts their QR
// (see the poster view), a prospective Client/Associate/Staff member opens
// the app on their phone, taps "Scan to join", and lands straight on the
// redemption screen with the code already filled in.
//
// Platform support is deliberately narrow. mobile_scanner implements
// android / iOS / macOS / web only — there is no Windows implementation,
// and a desktop VM has no camera to point at a poster anyway. So the scan
// ENTRY POINT is hidden off-camera entirely rather than offered and then
// failing: isQrScanningSupported gates it, keeping the copy/paste path as
// the desktop fallback (the same reasoning the QR dialog's SelectableText
// already documents).
//
// The camera widget lives in its own library and is only imported on
// supported platforms, so a Windows/web build never pulls camera plugin
// code into the binary at all.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/engine/invites/invite_link_builder.dart';

/// Whether this build/platform has a usable camera scanner.
///
/// False on Windows and Linux (no plugin, no camera), so callers hide
/// "Scan to join" instead of presenting a dead button.
bool get isQrScanningSupported {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key, required this.onScanned});

  /// Called with the raw scanned value (a full link or a bare token).
  final void Function(String value) onScanned;

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _handled = false;
  bool _cameraUnavailable = false;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    // Ignore everything after the first hit — a QR in view fires
    // continuously, and we only want to act once.
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;
      final code = InviteLinkBuilder.extractCode(raw);
      if (code == null || code.isEmpty) continue;
      _handled = true;
      widget.onScanned(code);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan invite code'),
      ),
      body: _cameraUnavailable
          ? const _Unavailable(message: 'The camera could not be started.')
          : Stack(
              fit: StackFit.expand,
              children: [
                _QrCameraView(
                  controller: _controller,
                  onDetect: _onDetect,
                  onCameraFailed: () => setState(
                    () => _cameraUnavailable = true,
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.inputRadius),
                          ),
                          child: Text(
                            "Point your camera at the owner's QR code to "
                            'join their business.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// The live camera preview. Isolated so the permission-denied / no-camera
/// case degrades to [_Unavailable] instead of a black rectangle.
class _QrCameraView extends StatelessWidget {
  const _QrCameraView({
    required this.controller,
    required this.onDetect,
    required this.onCameraFailed,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;
  final VoidCallback onCameraFailed;

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: controller,
      onDetect: onDetect,
      onDetectError: (_, __) => onCameraFailed(),
      errorBuilder: (context, error) => _Unavailable(
        message: switch (error.errorCode) {
          MobileScannerErrorCode.permissionDenied =>
            'Camera access was denied. Allow it in your device settings to '
                'scan invite codes.',
          _ => 'The camera could not be started.',
        },
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'You can still join by typing or pasting the invite code '
              'instead.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}