import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import '../../data/services/prediction_socket.dart';

class ScanController extends ChangeNotifier with WidgetsBindingObserver {
  ScanController({PredictionSocket? predictionSocket})
      : _predictionSocket = predictionSocket ?? PredictionSocket() {
    // Daftarkan listener saat controller dibuat
    WidgetsBinding.instance.addObserver(this);

    // Pantau perubahan status koneksi untuk ditampilkan di UI.
    _statusSub = _predictionSocket.statusStream.listen((status) {
      socketStatus = status;
      notifyListeners();
    });
  }

  final PredictionSocket _predictionSocket;
  StreamSubscription<SocketStatus>? _statusSub;

  // -- State Variabel untuk UI --
  CameraController? cameraController;
  String? cameraError;
  String detectedLetter = '-';
  double confidence = 0.0;
  String resultText = '';
  SocketStatus socketStatus = SocketStatus.idle;

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
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      cameraController = controller;
      notifyListeners();

      await _connectSocket();

      await controller.startImageStream(_processCameraImage);
    } on CameraException catch (error) {
      cameraError = _cameraErrorMessage(error);
      notifyListeners();
    } catch (_) {
      cameraError = 'Gagal mengakses kamera.';
      notifyListeners();
    }
  }

  Future<void> _connectSocket() async {
    try {
      debugPrint('[CONTROLLER] Mencoba terhubung ke WebSocket...');
      await _predictionSocket.connect(onResult: _updatePrediction);
    } catch (e) {
      debugPrint('[CONTROLLER ERROR CONNECT] $e');
    }
  }

  /// AUTO-CONNECT: Hubungkan ulang saat app kembali dari background atau
  /// saat app kembali aktif. Aman dipanggil berulang karena socket akan
  /// mengabaikan jika sudah terhubung.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _connectSocket();
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
    } catch (e) {
      debugPrint('[CONTROLLER ERROR SEND] $e');
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
    WidgetsBinding.instance.removeObserver(this);
    _statusSub?.cancel();
    cameraController?.stopImageStream();
    cameraController?.dispose();
    _predictionSocket.close();
    _predictionSocket.dispose();
    super.dispose();
  }
}
