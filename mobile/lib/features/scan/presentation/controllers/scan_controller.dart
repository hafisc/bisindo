import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../data/services/prediction_socket.dart';

class ScanController extends ChangeNotifier {
  ScanController({PredictionSocket? predictionSocket})
      : _predictionSocket = predictionSocket ?? PredictionSocket();

  final PredictionSocket _predictionSocket;

  // -- State Variabel untuk UI --
  CameraController? cameraController;
  String? cameraError;
  String detectedLetter = '-';
  double confidence = 0.0;
  String resultText = '';

  // -- State Internal --
  bool _isProcessingFrame = false;
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> initializeCamera() async {
    try {
      cameraError = null;
      notifyListeners();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'Kamera tidak tersedia di perangkat.');
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      cameraController = controller;
      notifyListeners();

      try {
        await _predictionSocket.connect(onResult: _updatePrediction);
      } on SocketException {
      } on WebSocketException {
      } on TimeoutException {
      }

      await controller.startImageStream(_processCameraImage);
    } on CameraException catch (error) {
      cameraError = _cameraErrorMessage(error);
      notifyListeners();
    } catch (_) {
      cameraError = 'Gagal mengakses kamera.';
      notifyListeners();
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final now = DateTime.now();
    if (_isProcessingFrame ||
        now.difference(_lastProcessedAt).inMilliseconds < 250) {
      return;
    }

    _lastProcessedAt = now;
    _isProcessingFrame = true;
    try {
      await _predictionSocket.sendFrame(image);
    } finally {
      _isProcessingFrame = false;
    }
  }

  String _cameraErrorMessage(CameraException error) {
    if (error.code == 'CameraAccessDenied' ||
        error.code == 'CameraAccessDeniedWithoutPrompt') {
      return 'Izin kamera diperlukan untuk fitur ini.';
    }
    return error.description ?? 'Gagal mengakses kamera.';
  }

  void _updatePrediction(PredictionResult prediction) {
    detectedLetter = prediction.prediction;
    confidence = prediction.confidence;
    notifyListeners();
  }

  void appendSpace() {
    resultText += ' ';
    notifyListeners();
  }

  void removeLastCharacter() {
    if (resultText.isEmpty) return;
    resultText = resultText.substring(0, resultText.length - 1);
    notifyListeners();
  }

  void resetResult() {
    resultText = '';
    notifyListeners();
  }

  @override
  void dispose() {
    cameraController?.stopImageStream();
    cameraController?.dispose();
    _predictionSocket.close();
    super.dispose();
  }
}
