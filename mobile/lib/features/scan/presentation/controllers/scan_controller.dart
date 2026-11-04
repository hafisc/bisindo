import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import '../../data/services/camera_service.dart';
import '../../data/services/native_hand_landmarker_service.dart';
import '../../data/services/prediction_socket.dart';

class ScanController extends ChangeNotifier with WidgetsBindingObserver {
  ScanController({
    PredictionSocket? predictionSocket,
    CameraService? cameraService,
    NativeHandLandmarkerService? landmarkerService,
  })  : _predictionSocket = predictionSocket ?? PredictionSocket(),
        _landmarkerService = landmarkerService ?? NativeHandLandmarkerService() {
    WidgetsBinding.instance.addObserver(this);

    _statusSub = _predictionSocket.statusStream.listen((status) {
      socketStatus = status;
      notifyListeners();
    });

    _landmarkSub = _landmarkerService.handsStream.listen((hands) {
      detectedHands = hands;
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
  final NativeHandLandmarkerService _landmarkerService;
  late final CameraService _cameraService;

  StreamSubscription<SocketStatus>? _statusSub;
  StreamSubscription<List<DetectedHand>>? _landmarkSub;

  String? cameraError;
  String detectedLetter = '-';
  double confidence = 0.0;
  String resultText = '';
  SocketStatus socketStatus = SocketStatus.idle;
  List<DetectedHand> detectedHands = [];

  CameraController? get cameraController => _cameraService.controller;
  bool get isSwitchingCamera => _cameraService.isSwitchingCamera;
  bool get hasMultipleCameras => _cameraService.hasMultipleCameras;
  bool get isFrontCamera => _cameraService.isFrontCamera;

  bool _isProcessingSocket = false;
  DateTime _lastSocketAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isDisposed = false;

  Future<void> initializeCamera() async {
    cameraError = null;
    notifyListeners();
    await _cameraService.initialize();
    if (!_isDisposed) await _connectSocket();
  }

  Future<void> switchCamera() => _cameraService.switchCamera();

  Future<void> _connectSocket() async {
    try {
      await _predictionSocket.connect(onResult: _updatePrediction);
    } catch (e) {
      debugPrint('[ScanController] Socket connect error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _connectSocket();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDisposed) return;

    await _landmarkerService.processCameraImage(
      image,
      sensorOrientation: _cameraService.sensorOrientation,
    );

    final now = DateTime.now();
    if (_predictionSocket.isConnected &&
        !_isProcessingSocket &&
        now.difference(_lastSocketAt).inMilliseconds >= 250) {
      _lastSocketAt = now;
      _isProcessingSocket = true;
      try {
        await _predictionSocket.sendFrame(image);
      } catch (e) {
        debugPrint('[ScanController] Socket send error: $e');
      } finally {
        _isProcessingSocket = false;
      }
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
    if (resultText.isNotEmpty) {
      resultText = resultText.substring(0, resultText.length - 1);
      notifyListeners();
    }
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
    _landmarkSub?.cancel();
    _cameraService.dispose();
    _landmarkerService.dispose();
    _predictionSocket.close();
    _predictionSocket.dispose();
    super.dispose();
  }
}
