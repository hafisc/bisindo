import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

/// Status koneksi WebSocket ke server prediksi.
enum SocketStatus {
  /// Belum pernah mencoba terhubung / sudah ditutup permanen.
  idle,

  /// Sedang mencoba membuka koneksi.
  connecting,

  /// Koneksi terbuka dan siap mengirim frame.
  connected,

  /// Koneksi terputus dan sedang menunggu untuk mencoba ulang.
  reconnecting,
}

class PredictionSocket {
  PredictionSocket({
    this.url = 'ws://192.168.100.12:8000/ws/predict',
    this.autoReconnect = true,
    this.maxReconnectDelay = const Duration(seconds: 15),
  });

  final String url;

  /// Jika true, socket akan otomatis mencoba reconnect ketika koneksi putus.
  final bool autoReconnect;

  /// Batas maksimum jeda (untuk exponential backoff).
  final Duration maxReconnectDelay;

  WebSocket? _socket;
  bool _isProcessing = false; // Flag agar tidak terjadi pembentukan queue frame berlebih
  bool _isClosed = false; // True saat close() dipanggil secara sengaja
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  /// Callback hasil prediksi (dari pesan server).
  void Function(PredictionResult)? _onResult;

  // -- Status koneksi --
  SocketStatus _status = SocketStatus.idle;
  SocketStatus get status => _status;

  final _statusController = StreamController<SocketStatus>.broadcast();

  /// Stream perubahan status koneksi, berguna untuk indikator di UI.
  Stream<SocketStatus> get statusStream => _statusController.stream;

  bool get isConnected =>
      _socket != null && _socket!.readyState == WebSocket.open;

  void _setStatus(SocketStatus status) {
    if (_status == status) return;
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// Membuka koneksi ke server. Callback [onResult] akan dipanggil setiap
  /// pesan prediksi diterima. Aman dipanggil berulang kali: jika sudah
  /// terhubung, pemanggilan ini tidak akan membuat koneksi baru.
  Future<void> connect({
    required void Function(PredictionResult) onResult,
  }) async {
    _onResult = onResult;
    _isClosed = false;

    // Cegah duplikasi koneksi: jika sudah terbuka/sedang connect, abaikan.
    if (isConnected || _status == SocketStatus.connecting) {
      debugPrint('WebSocket sudah terhubung / sedang menghubungkan. Dilewati.');
      return;
    }

    await _openSocket();
  }

  /// Melakukan upaya membuka socket tunggal.
  Future<void> _openSocket() async {
    _reconnectTimer?.cancel();
    _setStatus(SocketStatus.connecting);

    try {
      // Tutup socket lama jika masih ada agar tidak menumpuk (leak).
      await _disposeCurrentSocket();

      final socket = await WebSocket.connect(url);
      _socket = socket;
      _reconnectAttempt = 0;
      _setStatus(SocketStatus.connected);
      debugPrint('WebSocket terhubung ke $url');

      socket.listen(
        (message) {
          if (message is! String) return;
          try {
            final data = jsonDecode(message) as Map<String, dynamic>;
            if (data['error'] != null) return;
            _onResult?.call(
              PredictionResult(
                prediction: data['prediction'] as String,
                confidence: (data['confidence'] as num).toDouble(),
              ),
            );
          } catch (e) {
            debugPrint('Gagal mem-parsing pesan server: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Gagal terhubung ke WebSocket: $e');
      _handleDisconnect();
    }
  }

  /// Menangani kondisi koneksi terputus dan menjadwalkan reconnect.
  void _handleDisconnect() {
    _socket = null;
    if (_isClosed || !autoReconnect) {
      _setStatus(SocketStatus.idle);
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isClosed || !autoReconnect) return;
    if (_reconnectTimer?.isActive ?? false) return;

    _setStatus(SocketStatus.reconnecting);

    // Exponential backoff: 1s, 2s, 4s, 8s ... dibatasi maxReconnectDelay.
    final seconds = math.min(
      1 << _reconnectAttempt.clamp(0, 4), // 1,2,4,8,16
      maxReconnectDelay.inSeconds,
    );
    final delay = Duration(seconds: seconds);
    _reconnectAttempt++;

    debugPrint('Reconnect dalam ${delay.inSeconds}s (percobaan $_reconnectAttempt)');
    _reconnectTimer = Timer(delay, () {
      if (_isClosed) return;
      _openSocket();
    });
  }

  Future<void> sendFrame(CameraImage cameraImage) async {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) return;

    // Abaikan frame jika frame sebelumnya masih diproses (Mencegah Lag / Memory Leak)
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final compressedBytes = await _encodeJpeg(cameraImage);
      if (compressedBytes != null && socket.readyState == WebSocket.open) {
        if (kDebugMode) {
          debugPrint(
            '[SOCKET] Mengirim frame: ${compressedBytes.lengthInBytes} bytes '
            '(${cameraImage.width}x${cameraImage.height}, '
            'format: ${cameraImage.format.group.name})',
          );
        }
        socket.add(compressedBytes);
      }
    } catch (e) {
      debugPrint('Error encoding frame: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<Uint8List?> _encodeJpeg(CameraImage cameraImage) async {
    // 1. Jalur Cepat: Format JPEG Native
    if (cameraImage.format.group == ImageFormatGroup.jpeg) {
      return FlutterImageCompress.compressWithList(
        cameraImage.planes[0].bytes,
        quality: 60,
        minWidth: 480,
        minHeight: 480,
      );
    }

    // 2. Fallback: Eksekusi konversi YUV di Background Isolate via compute()
    return compute(_convertYUV420ToJpeg, cameraImage);
  }

  Future<void> _disposeCurrentSocket() async {
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        await socket.close();
      } catch (_) {
        // Diabaikan: socket mungkin sudah tertutup.
      }
    }
  }

  Future<void> close() async {
    _isClosed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _disposeCurrentSocket();
    _setStatus(SocketStatus.idle);
  }

  /// Menutup stream status. Panggil setelah [close] saat controller dibuang.
  void dispose() {
    _statusController.close();
  }
}

/// Top-level function agar bisa dijalankan di Isolate via compute()
Uint8List? _convertYUV420ToJpeg(CameraImage cameraImage) {
  final width = cameraImage.width;
  final height = cameraImage.height;

  final yPlane = cameraImage.planes[0];

  // Cek ketersediaan plane U dan V untuk keamanan (Android NV21 vs iOS YUV420)
  final hasSeparateUV = cameraImage.planes.length >= 3;
  final uPlane = cameraImage.planes[1];
  final vPlane = hasSeparateUV ? cameraImage.planes[2] : cameraImage.planes[1];

  final uPixelStride = uPlane.bytesPerPixel ?? 1;
  final vPixelStride = hasSeparateUV ? (vPlane.bytesPerPixel ?? 1) : uPixelStride;

  final output = img.Image(width: width, height: height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final yIndex = y * yPlane.bytesPerRow + x;
      final yValue = yPlane.bytes[yIndex];

      final uvRow = y ~/ 2;
      final uvColumn = x ~/ 2;

      final uIndex = uvRow * uPlane.bytesPerRow + uvColumn * uPixelStride;
      final vIndex = hasSeparateUV
          ? (uvRow * vPlane.bytesPerRow + uvColumn * vPixelStride)
          : (uIndex + 1 < uPlane.bytes.length ? uIndex + 1 : uIndex);

      final uValue = uPlane.bytes[uIndex];
      final vValue = vPlane.bytes[vIndex];

      final red = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
      final green = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
          .round()
          .clamp(0, 255);
      final blue = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

      output.setPixelRgb(x, y, red, green, blue);
    }
  }

  return Uint8List.fromList(img.encodeJpg(output, quality: 60));
}

class PredictionResult {
  const PredictionResult({required this.prediction, required this.confidence});

  final String prediction;
  final double confidence;
}
