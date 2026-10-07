import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controllers/scan_controller.dart';
import '../widgets/camera_switch_button.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/detection_info_overlay.dart';
import '../widgets/scan_action_bar.dart';
import '../widgets/scan_camera_view.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late final ScanController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScanController()..initializeCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder otomatis akan me-refresh tampilan setiap kali
    // _controller memanggil notifyListeners()
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
              if (_controller.cameraError == null &&
                  _controller.hasMultipleCameras)
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: CameraSwitchButton(
                        isFrontCamera: _controller.isFrontCamera,
                        isSwitching: _controller.isSwitchingCamera,
                        isEnabled:
                            _controller.cameraController?.value.isInitialized ==
                                true,
                        onPressed: _controller.switchCamera,
                      ),
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
                    ConnectionStatusIndicator(status: _controller.socketStatus),
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
              // Tombol kembali ke Beranda
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
                      onPressed: () => context.go('/home'),
                    ),
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
