import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import '../../data/services/prediction_socket.dart';
import '../../data/services/camera_service.dart';

class ScanController extends ChangeNotifier with WidgetsBindingObserver {
  ScanController({
    PredictionSocket? predictionSocket,
    CameraService? cameraService,
  }) : _predictionSocket = predictionSocket ?? PredictionSocket() {
    WidgetsBinding.instance.addObserver(this);

    _statusSub = _predictionSocket.statusStream.listen((status) {
      socketStatus = status;
      notifyListeners();
    });

    _cameraService = cameraService ??
        CameraService(
          onStateChanged: notifyListeners,
          onError: (err) {
            cameraError = err;
            notifyListeners();
          },
          onFrame: _processCameraImage,
        );
  }

  final PredictionSocket _predictionSocket;
  late final CameraService _cameraService;
  StreamSubscription<SocketStatus>? _statusSub;

  // -- State Variabel untuk UI --
  String? cameraError;
  String detectedLetter = '-';
  double confidence = 0.0;
  String resultText = '';
  SocketStatus socketStatus = SocketStatus.idle;

  // -- Proxy State Kamera --
  CameraController? get cameraController => _cameraService.controller;
  bool get isSwitchingCamera => _cameraService.isSwitchingCamera;
  bool get hasMultipleCameras => _cameraService.hasMultipleCameras;
  bool get isFrontCamera => _cameraService.isFrontCamera;

  // -- State Internal --
  bool _isProcessingFrame = false;
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isDisposed = false;

  Future<void> initializeCamera() async {
    cameraError = null;
    notifyListeners();

    await _cameraService.initialize();

    if (!_isDisposed) {
      await _connectSocket();
    }
  }

  Future<void> switchCamera() async {
    await _cameraService.switchCamera();
  }

  Future<void> _connectSocket() async {
    try {
      debugPrint('[CONTROLLER] Mencoba terhubung ke WebSocket...');
      await _predictionSocket.connect(onResult: _updatePrediction);
    } catch (e) {
      debugPrint('[CONTROLLER ERROR CONNECT] $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _connectSocket();
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDisposed) return;

    final now = DateTime.now();
    // Batasi pengiriman frame maks 4 fps (1 frame per 250ms)
    if (_isProcessingFrame ||
        now.difference(_lastProcessedAt).inMilliseconds < 250) {
      return;
    }

    _lastProcessedAt = now;
    _isProcessingFrame = true;
    try {
      await _predictionSocket.sendFrame(image);
    } catch (e) {
      debugPrint('[CONTROLLER ERROR SEND] $e');
    } finally {
      _isProcessingFrame = false;
    }
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
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _statusSub?.cancel();

    _cameraService.dispose();
    _predictionSocket.close();
    _predictionSocket.dispose();

    super.dispose();
  }
}
