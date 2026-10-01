import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

class PredictionSocket {
  PredictionSocket({this.url = 'ws://192.168.100.12:8000/ws/predict'});

  final String url;
  WebSocket? _socket;

  Future<void> connect({
    required void Function(PredictionResult) onResult,
  }) async {
    _socket = await WebSocket.connect(url);
    _socket!.listen((message) {
      if (message is! String) return;
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (data['error'] != null) return;
      onResult(
        PredictionResult(
          prediction: data['prediction'] as String,
          confidence: (data['confidence'] as num).toDouble(),
        ),
      );
    });
  }

  Future<void> sendFrame(CameraImage cameraImage) async {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) return;
    
    final compressedBytes = await _encodeJpeg(cameraImage);
    if (compressedBytes != null) {
      socket.add(compressedBytes);
    }
  }

  Future<Uint8List?> _encodeJpeg(CameraImage cameraImage) async {
    // Jika data dari kamera sudah berupa JPEG (sangat cepat, 0 overhead konversi di Dart)
    if (cameraImage.format.group == ImageFormatGroup.jpeg) {
      // Kompresi native C/C++ menggunakan libjpeg-turbo (via flutter_image_compress)
      return FlutterImageCompress.compressWithList(
        cameraImage.planes[0].bytes,
        quality: 70, // kompresi agar ukuran byte kecil dan pengiriman WebSocket cepat
      );
    }

    // Fallback: Jika gagal menggunakan format JPEG di CameraController, gunakan manual YUV ke RGB
    final output = img.Image(
      width: cameraImage.width,
      height: cameraImage.height,
    );
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    for (var y = 0; y < cameraImage.height; y++) {
      for (var x = 0; x < cameraImage.width; x++) {
        final yValue = yPlane.bytes[y * yPlane.bytesPerRow + x];
        final uvRow = (y ~/ 2);
        final uvColumn = (x ~/ 2);
        final uIndex = uvRow * uPlane.bytesPerRow + uvColumn * uPixelStride;
        final vIndex = uvRow * vPlane.bytesPerRow + uvColumn * vPixelStride;
        final uValue = uPlane.bytes[uIndex];
        final vValue = vPlane.bytes[vIndex];
        final red = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        final green =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .round()
                .clamp(0, 255);
        final blue = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);
        output.setPixelRgb(x, y, red, green, blue);
      }
    }

    return Uint8List.fromList(img.encodeJpg(output, quality: 70));
  }

  Future<void> close() async {
    await _socket?.close();
    _socket = null;
  }
}

class PredictionResult {
  const PredictionResult({required this.prediction, required this.confidence});

  final String prediction;
  final double confidence;
}
