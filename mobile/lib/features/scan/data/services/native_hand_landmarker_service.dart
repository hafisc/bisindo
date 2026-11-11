import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/detected_hand.dart';

export '../models/detected_hand.dart';

class NativeHandLandmarkerService {
  static const MethodChannel _channel =
      MethodChannel('com.bisindo.mediapipe/hand_landmark');

  final _handsController = StreamController<List<DetectedHand>>.broadcast();
  Stream<List<DetectedHand>> get handsStream => _handsController.stream;

  bool _isProcessing = false;
  bool _isDisposed = false;

  NativeHandLandmarkerService() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (_isDisposed) return;

    if (call.method == 'onHandLandmarks') {
      try {
        final raw = call.arguments as List<dynamic>? ?? [];
        final hands = raw
            .map((h) => DetectedHand.fromMap(h as Map<dynamic, dynamic>))
            .toList();
        if (!_handsController.isClosed) _handsController.add(hands);
      } catch (e) {
        debugPrint('[NativeHandLandmarker] Parse error: $e');
      }
    }
  }

  Future<void> processCameraImage(
    CameraImage image, {
    int sensorOrientation = 0,
  }) async {
    if (_isDisposed || _isProcessing) return;
    _isProcessing = true;

    try {
      if (image.format.group == ImageFormatGroup.jpeg && image.planes.isNotEmpty) {
        await _channel.invokeMethod('processJpegFrame', {
          'bytes': image.planes[0].bytes,
          'rotation': sensorOrientation,
        });
      } else if (image.planes.length >= 3) {
        await _channel.invokeMethod('processYuvFrame', {
          'y': image.planes[0].bytes,
          'u': image.planes[1].bytes,
          'v': image.planes[2].bytes,
          'width': image.width,
          'height': image.height,
          'yRowStride': image.planes[0].bytesPerRow,
          'uvRowStride': image.planes[1].bytesPerRow,
          'uvPixelStride': image.planes[1].bytesPerPixel ?? 1,
          'rotation': sensorOrientation,
        });
      }
    } catch (e) {
      debugPrint('[NativeHandLandmarker] Send frame error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
    try {
      await _channel.invokeMethod('close');
    } catch (_) {}
    await _handsController.close();
  }
}
