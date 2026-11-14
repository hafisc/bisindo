import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../history/domain/models/history_item.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../controllers/scan_controller.dart';
import '../widgets/camera_switch_button.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/detection_info_overlay.dart';
import '../widgets/hand_landmarks_painter.dart';
import '../widgets/scan_action_bar.dart';
import '../widgets/scan_camera_view.dart';
import '../widgets/server_settings_dialog.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  late final ScanController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScanController(onLetterCommitted: _saveToHistory)
      ..initializeCamera();
  }

  void _saveToHistory(HistoryItem item) {
    unawaited(ref.read(historyNotifierProvider.notifier).addHistoryItem(item));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openServerSettings() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ServerSettingsDialog(
        currentUrl: _controller.serverUrl,
        onSave: _controller.setServerAddress,
        onReset: _controller.resetServerAddress,
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alamat server dipakai: ${_controller.serverAddress}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              ScanCameraView(
                controller: _controller.cameraController,
                errorMessage: _controller.cameraError,
                onRetry: _controller.initializeCamera,
              ),
              if (_controller.cameraError == null && _controller.showSkeleton)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: HandLandmarksPainter(
                        hands: _controller.detectedHands,
                        isFrontCamera: _controller.isFrontCamera,
                        imageSize:
                            _controller.cameraController?.value.previewSize,
                      ),
                    ),
                  ),
                ),
              if (_controller.cameraError == null)
                Positioned(
                  right: 16,
                  top: 80,
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _RoundIconButton(
                          icon: _controller.showSkeleton
                              ? Icons.visibility
                              : Icons.visibility_off,
                          tooltip: _controller.showSkeleton
                              ? 'Sembunyikan skeleton'
                              : 'Tampilkan skeleton',
                          onPressed: _controller.toggleSkeleton,
                        ),
                        const SizedBox(height: 16),
                        _RoundIconButton(
                          icon: _controller.ttsEnabled
                              ? Icons.volume_up
                              : Icons.volume_off,
                          tooltip: _controller.ttsEnabled
                              ? 'Matikan suara'
                              : 'Nyalakan suara',
                          onPressed: _controller.toggleTts,
                        ),
                        if (_controller.hasMultipleCameras) ...[
                          const SizedBox(height: 16),
                          CameraSwitchButton(
                            isFrontCamera: _controller.isFrontCamera,
                            isSwitching: _controller.isSwitchingCamera,
                            isEnabled:
                                _controller
                                    .cameraController
                                    ?.value
                                    .isInitialized ==
                                true,
                            onPressed: _controller.switchCamera,
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
                      letter: _controller.detectedLetter,
                      confidence: _controller.confidence,
                    ),
                    ConnectionStatusIndicator(
                      status: _controller.predictionStatus,
                      serverAddress: _controller.serverAddress,
                      errorMessage: _controller.predictionError,
                      onRetry: _controller.refreshServer,
                    ),
                    const Spacer(),
                    ScanActionBar(
                      resultText: _controller.resultText,
                      onSpacePressed: _controller.appendSpace,
                      onBackspacePressed: _controller.removeLastCharacter,
                      onResetPressed: _controller.resetResult,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: SafeArea(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: SafeArea(
                  child: _RoundIconButton(
                    icon: Icons.settings,
                    tooltip: 'Alamat server',
                    onPressed: _openServerSettings,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
