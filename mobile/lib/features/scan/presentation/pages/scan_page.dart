import 'package:flutter/material.dart';

import '../controllers/scan_controller.dart';
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
              SafeArea(
                child: Column(
                  children: [
                    DetectionInfoOverlay(
                      letter: _controller.detectedLetter,
                      confidence: _controller.confidence,
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
            ],
          ),
        );
      },
    );
  }
}
