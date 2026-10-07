import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Service khusus untuk mengelola inisialisasi, stream, dan pergantian kamera.
class CameraService {
  CameraService({
    required this.onStateChanged,
    required this.onError,
    required this.onFrame,
  });

  /// Dipanggil saat UI perlu diperbarui (contoh: sedang switch kamera).
  final VoidCallback onStateChanged;

  /// Dipanggil saat terjadi error (contoh: izin ditolak).
  final Function(String) onError;

  /// Dipanggil setiap kali frame kamera baru siap diproses.
  final Function(CameraImage) onFrame;

  CameraController? controller;
  List<CameraDescription> _cameras = const [];
  int? _currentCameraIndex;
  
  bool isSwitchingCamera = false;
  bool _isDisposed = false;
  CameraController? _activeCamera;

  bool get hasMultipleCameras => _cameras.length > 1;
  bool get isFrontCamera {
    final index = _currentCameraIndex;
    if (index == null || index >= _cameras.length) return false;
    return _cameras[index].lensDirection == CameraLensDirection.front;
  }

  Future<void> initialize() async {
    try {
      final available = await availableCameras();
      if (available.isEmpty) {
        throw CameraException('NoCamera', 'Kamera tidak tersedia di perangkat.');
      }
      _cameras = available;

      final defaultIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _currentCameraIndex = defaultIndex >= 0 ? defaultIndex : 0;

      await _startCamera(_cameras[_currentCameraIndex!]);
    } on CameraException catch (error) {
      onError(_cameraErrorMessage(error));
    } catch (_) {
      onError('Gagal mengakses kamera.');
    }
  }

  Future<void> _startCamera(CameraDescription description) async {
    final newController = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await newController.initialize();
    } catch (e) {
      await newController.dispose();
      rethrow;
    }

    if (_isDisposed) {
      await newController.dispose();
      return;
    }

    _activeCamera = newController;
    controller = newController;
    onStateChanged();

    if (!_isDisposed) {
      await newController.startImageStream(_processFrame);
    }
  }

  void _processFrame(CameraImage image) {
    if (isSwitchingCamera || _isDisposed) return;
    if (controller != _activeCamera || _activeCamera == null) return;
    onFrame(image);
  }

  Future<void> switchCamera() async {
    if (isSwitchingCamera || _isDisposed || _cameras.length < 2) return;
    final current = controller;
    if (current == null || !current.value.isInitialized) return;

    isSwitchingCamera = true;
    onStateChanged();

    final nextIndex = ((_currentCameraIndex ?? 0) + 1) % _cameras.length;

    try {
      if (current.value.isStreamingImages) {
        await current.stopImageStream();
      }
      _activeCamera = null;
      controller = null;
      onStateChanged();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await current.dispose();

      _currentCameraIndex = nextIndex;
      await _startCamera(_cameras[nextIndex]);
    } catch (e) {
      debugPrint('[CAMERA ERROR SWITCH] $e');
      try {
        _currentCameraIndex = nextIndex == 0 ? _cameras.length - 1 : nextIndex - 1;
        await _startCamera(_cameras[_currentCameraIndex!]);
      } catch (recoverError) {
        onError('Gagal mengganti kamera.');
      }
    } finally {
      isSwitchingCamera = false;
      if (!_isDisposed) onStateChanged();
    }
  }

  String _cameraErrorMessage(CameraException error) {
    if (error.code == 'CameraAccessDenied' ||
        error.code == 'CameraAccessDeniedWithoutPrompt') {
      return 'Izin kamera diperlukan untuk fitur ini.';
    }
    return error.description ?? 'Gagal mengakses kamera.';
  }

  void dispose() {
    _isDisposed = true;
    final c = controller;
    controller = null;
    _activeCamera = null;

    if (c != null && c.value.isInitialized) {
      if (c.value.isStreamingImages) {
        c.stopImageStream().whenComplete(c.dispose);
      } else {
        c.dispose();
      }
    } else {
      c?.dispose();
    }
  }
}
