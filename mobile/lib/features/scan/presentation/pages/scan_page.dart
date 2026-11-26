import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/router/app_router.dart';
import '../controllers/scan_controller.dart';
import '../widgets/camera_switch_button.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/detection_info_overlay.dart';
import '../widgets/hand_landmarks_painter.dart';
import '../widgets/scan_action_bar.dart';
import '../widgets/scan_camera_view.dart';
import '../widgets/scan_round_icon_button.dart';
import '../widgets/server_settings_dialog.dart';

/// Layar kamera penerjemah huruf BISINDO secara real-time.
class ScanPage extends ConsumerWidget {
  const ScanPage({super.key});

  Future<void> _openServerSettings(BuildContext context, WidgetRef ref) async {
    final controller =
        ref.read(scanControllerProvider(ScanMode.translate).notifier);
    final currentUrl =
        ref.read(scanControllerProvider(ScanMode.translate)).serverUrl;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ServerSettingsDialog(
        currentUrl: currentUrl,
        onSave: controller.setServerAddress,
        onReset: controller.resetServerAddress,
      ),
    );

    if (saved == true && context.mounted) {
      final address =
          ref.read(scanControllerProvider(ScanMode.translate)).serverAddress;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alamat server dipakai: $address'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanControllerProvider(ScanMode.translate));
    final scanController =
        ref.read(scanControllerProvider(ScanMode.translate).notifier);

    return Scaffold(
      backgroundColor: AppPalette.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScanCameraView(
            controller: scanState.cameraController,
            errorMessage: scanState.cameraError,
            onRetry: scanController.initializeCamera,
          ),
          if (scanState.cameraError == null && scanState.showSkeleton)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: HandLandmarksPainter(
                    hands: scanState.detectedHands,
                    isFrontCamera: scanState.isFrontCamera,
                    imageSize: scanState.cameraController?.value.previewSize,
                  ),
                ),
              ),
            ),
          if (scanState.cameraError == null)
            Positioned(
              right: 16,
              top: 80,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ScanRoundIconButton(
                      icon: scanState.showSkeleton
                          ? Icons.visibility
                          : Icons.visibility_off,
                      tooltip: scanState.showSkeleton
                          ? 'Sembunyikan skeleton'
                          : 'Tampilkan skeleton',
                      onPressed: scanController.toggleSkeleton,
                    ),
                    const SizedBox(height: 16),
                    ScanRoundIconButton(
                      icon: scanState.ttsEnabled
                          ? Icons.volume_up
                          : Icons.volume_off,
                      tooltip: scanState.ttsEnabled
                          ? 'Matikan suara'
                          : 'Nyalakan suara',
                      onPressed: scanController.toggleTts,
                    ),
                    if (scanState.hasMultipleCameras) ...[
                      const SizedBox(height: 16),
                      CameraSwitchButton(
                        isFrontCamera: scanState.isFrontCamera,
                        isSwitching: scanState.isSwitchingCamera,
                        isEnabled:
                            scanState.cameraController?.value.isInitialized ==
                                true,
                        onPressed: scanController.switchCamera,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                DetectionInfoOverlay(
                  letter: scanState.detectedLetter,
                  confidence: scanState.confidence,
                ),
                ConnectionStatusIndicator(
                  status: scanState.predictionStatus,
                  serverAddress: scanState.serverAddress,
                  errorMessage: scanState.predictionError,
                  onRetry: scanController.refreshServer,
                ),
                const Spacer(),
                ScanActionBar(
                  resultText: scanState.resultText,
                  onSpacePressed: scanController.appendSpace,
                  onBackspacePressed: scanController.removeLastCharacter,
                  onResetPressed: scanController.resetResult,
                  onSpeakPressed: scanController.speakSentence,
                  onCopyPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: scanState.resultText),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hasil terjemahan disalin ke clipboard'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: SafeArea(
              child: ScanRoundIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Kembali',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: SafeArea(
              child: ScanRoundIconButton(
                icon: Icons.settings,
                tooltip: 'Alamat server',
                onPressed: () => _openServerSettings(context, ref),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
