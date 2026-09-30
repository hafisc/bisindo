import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../widgets/detection_info_overlay.dart';
import '../widgets/scan_action_bar.dart';
import '../widgets/scan_camera_view.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? _cameraController;
  final String _detectedLetter = 'A';
  final double _confidence = 0.95;
  String _resultText = '';
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'NoCamera',
          'Kamera tidak tersedia di perangkat.',
        );
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() => _cameraController = controller);
    } on CameraException catch (error) {
      if (mounted) {
        setState(() => _cameraError = _cameraErrorMessage(error));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cameraError = 'Gagal mengakses kamera.');
      }
    }
  }

  String _cameraErrorMessage(CameraException error) {
    if (error.code == 'CameraAccessDenied' ||
        error.code == 'CameraAccessDeniedWithoutPrompt') {
      return 'Izin kamera diperlukan untuk fitur ini.';
    }
    return error.description ?? 'Gagal mengakses kamera.';
  }

  void _appendSpace() {
    setState(() => _resultText += ' ');
  }

  void _removeLastCharacter() {
    if (_resultText.isEmpty) return;
    setState(
      () => _resultText = _resultText.substring(0, _resultText.length - 1),
    );
  }

  void _resetResult() {
    setState(() => _resultText = '');
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScanCameraView(
            controller: _cameraController,
            errorMessage: _cameraError,
            onRetry: _initializeCamera,
          ),
          SafeArea(
            child: Column(
              children: [
                DetectionInfoOverlay(
                  letter: _detectedLetter,
                  confidence: _confidence,
                ),
                const Spacer(),
                ScanActionBar(
                  resultText: _resultText,
                  onSpacePressed: _appendSpace,
                  onBackspacePressed: _removeLastCharacter,
                  onResetPressed: _resetResult,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
