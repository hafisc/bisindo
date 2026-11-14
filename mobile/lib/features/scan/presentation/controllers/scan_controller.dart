import 'dart:async';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/config/api_config.dart';
import '../../../history/domain/models/history_item.dart';
import '../../data/models/prediction_result.dart';
import '../../data/models/prediction_status.dart';
import '../../data/services/camera_service.dart';
import '../../data/services/native_hand_landmarker_service.dart';
import '../../data/services/prediction_api_client.dart';
import '../../data/services/tts_service.dart';
import '../../domain/prediction_stabilizer.dart';

/// Jeda minimum antar permintaan prediksi.
const Duration _predictInterval = Duration(milliseconds: 200);

/// Jeda setelah kegagalan sebelum mencoba server lagi.
const Duration _retryInterval = Duration(seconds: 2);

class ScanController extends ChangeNotifier with WidgetsBindingObserver {
  ScanController({
    PredictionApiClient? apiClient,
    TtsService? ttsService,
    PredictionStabilizer? stabilizer,
    CameraService? cameraService,
    NativeHandLandmarkerService? landmarkerService,
    this.onLetterCommitted,
    this.onLetterRecognized,
    this.recordHistory = true,
  })  : _apiClient = apiClient ?? PredictionApiClient(),
        _ttsService = ttsService ?? TtsService(),
        _stabilizer = stabilizer ?? PredictionStabilizer(),
        _landmarkerService = landmarkerService ?? NativeHandLandmarkerService() {
    WidgetsBinding.instance.addObserver(this);
    _resolveUser();

    _landmarkSub = _landmarkerService.handsStream.listen(_onHands);

    _cameraService = cameraService ??
        CameraService(
          onStateChanged: notifyListeners,
          onError: (err) {
            cameraError = err;
            notifyListeners();
          },
          onFrame: _processCameraImage,
        );

    unawaited(_loadPreferences());
  }

  final PredictionApiClient _apiClient;
  final TtsService _ttsService;
  final PredictionStabilizer _stabilizer;
  final NativeHandLandmarkerService _landmarkerService;
  late final CameraService _cameraService;

  /// Dipanggil setiap kali satu huruf dikunci, agar layar bisa menyimpannya ke
  /// riwayat lokal.
  final void Function(HistoryItem item)? onLetterCommitted;

  /// Dipanggil setiap kali stabilizer mengunci satu huruf, dipakai Mode
  /// Belajar untuk mencocokkan huruf dengan target.
  final void Function(String letter, double confidence)? onLetterRecognized;

  /// `false` untuk Mode Belajar: huruf yang dikunci tidak ditambahkan ke
  /// teks hasil, tidak disimpan ke riwayat, dan tidak dibacakan.
  final bool recordHistory;

  StreamSubscription<List<DetectedHand>>? _landmarkSub;
  Timer? _handsLostTimer;

  String? cameraError;
  String? predictionError;

  String detectedLetter = '-';
  double confidence = 0.0;
  String resultText = '';

  PredictionStatus predictionStatus = PredictionStatus.idle;
  List<DetectedHand> detectedHands = const [];

  bool ttsEnabled = true;

  String? _userId;
  String? _userName;
  String? _userEmail;

  bool _isDisposed = false;
  bool _isPredicting = false;
  bool _isCheckingServer = false;
  DateTime _lastPredictAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _retryAfter = DateTime.fromMillisecondsSinceEpoch(0);

  CameraController? get cameraController => _cameraService.controller;
  bool get isSwitchingCamera => _cameraService.isSwitchingCamera;
  bool get hasMultipleCameras => _cameraService.hasMultipleCameras;
  bool get isFrontCamera => _cameraService.isFrontCamera;

  /// Alamat server yang sedang dipakai, tanpa `http://`.
  String get serverAddress => ApiConfig.display(ApiConfig.baseUrl);

  /// Alamat server lengkap, dipakai di dialog pengaturan.
  String get serverUrl => ApiConfig.baseUrl;

  Future<void> _loadPreferences() async {
    await _ttsService.load();
    ttsEnabled = _ttsService.enabled;
    if (!_isDisposed) notifyListeners();
  }

  void _resolveUser() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      _userId = user?.uid;
      _userName = user?.displayName;
      _userEmail = user?.email;
    } catch (error) {
      debugPrint('[ScanController] Firebase belum siap: $error');
    }
  }

  Future<void> initializeCamera() async {
    cameraError = null;
    notifyListeners();
    await _cameraService.initialize();
    if (!_isDisposed) unawaited(_checkServer());
  }

  Future<void> switchCamera() async {
    _stabilizer.reset();
    await _cameraService.switchCamera();
  }

  /// Periksa apakah server bisa dihubungi dan modelnya termuat.
  Future<void> _checkServer() async {
    if (_isDisposed || _isCheckingServer) return;

    _isCheckingServer = true;
    predictionStatus = PredictionStatus.connecting;
    predictionError = null;
    notifyListeners();

    try {
      await _apiClient.checkHealth();
      if (_isDisposed) return;
      predictionStatus = PredictionStatus.ready;
      predictionError = null;
    } on PredictionException catch (error) {
      if (_isDisposed) return;
      predictionStatus = PredictionStatus.error;
      predictionError = error.message;
    } catch (error) {
      if (_isDisposed) return;
      predictionStatus = PredictionStatus.error;
      predictionError = 'Gagal memeriksa server: $error';
    } finally {
      _isCheckingServer = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Coba hubungi server lagi, dipakai tombol "Coba lagi".
  Future<void> refreshServer() => _checkServer();

  /// Simpan alamat server baru lalu periksa koneksinya.
  ///
  /// Mengembalikan `null` bila berhasil, atau pesan galat bila alamat tidak
  /// valid.
  Future<String?> setServerAddress(String raw) async {
    final validationError = ApiConfig.validate(raw);
    if (validationError != null) return validationError;

    await ApiConfig.save(raw);
    _stabilizer.reset();
    _retryAfter = DateTime.fromMillisecondsSinceEpoch(0);
    notifyListeners();
    unawaited(_checkServer());
    return null;
  }

  Future<void> resetServerAddress() async {
    await ApiConfig.reset();
    _stabilizer.reset();
    notifyListeners();
    unawaited(_checkServer());
  }

  Future<void> toggleTts() async {
    ttsEnabled = !ttsEnabled;
    notifyListeners();
    await _ttsService.setEnabled(ttsEnabled);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isDisposed) {
      unawaited(_checkServer());
    }
  }

  void _onHands(List<DetectedHand> hands) {
    if (_isDisposed) return;
    detectedHands = hands;

    if (hands.isEmpty) {
      // Beri jeda singkat: deteksi bisa kosong satu-dua frame saat tangan
      // bergerak. Setelah itu, tanda berikutnya boleh sama lagi.
      _handsLostTimer ??= Timer(const Duration(milliseconds: 600), () {
        _handsLostTimer = null;
        if (_isDisposed) return;
        _stabilizer.markHandsLost();
        detectedLetter = '-';
        confidence = 0.0;
        notifyListeners();
      });
    } else {
      _handsLostTimer?.cancel();
      _handsLostTimer = null;
    }

    notifyListeners();
    unawaited(_maybePredict());
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDisposed) return;

    await _landmarkerService.processCameraImage(
      image,
      sensorOrientation: _cameraService.sensorOrientation,
    );
  }

  Future<void> _maybePredict() async {
    if (_isDisposed || _isPredicting) return;
    if (detectedHands.isEmpty) return;
    if (_cameraService.controller == null) return;

    final now = DateTime.now();
    if (now.isBefore(_retryAfter)) return;
    if (now.difference(_lastPredictAt) < _predictInterval) return;

    _lastPredictAt = now;
    _isPredicting = true;

    try {
      final result = await _apiClient.predict(
        hands: detectedHands,
        userId: _userId,
      );
      if (_isDisposed) return;

      predictionStatus = PredictionStatus.ready;
      predictionError = null;
      detectedLetter = result.prediction;
      confidence = result.confidence;

      final committed = _stabilizer.add(result);
      if (committed != null) {
        onLetterRecognized?.call(committed, result.confidence);
        if (recordHistory) _commitLetter(committed, result.confidence);
      }
      notifyListeners();
    } on PredictionException catch (error) {
      if (_isDisposed) return;

      if (error.isRejected) {
        // Server menjawab, hanya datanya yang belum layak (misalnya tangan
        // terlalu kecil). Jangan tampilkan seolah server mati.
        detectedLetter = '-';
        confidence = 0.0;
        predictionStatus = PredictionStatus.ready;
        predictionError = null;
      } else {
        predictionStatus = PredictionStatus.error;
        predictionError = error.message;
        _retryAfter = DateTime.now().add(_retryInterval);
      }
      notifyListeners();
    } catch (error) {
      if (_isDisposed) return;
      predictionStatus = PredictionStatus.error;
      predictionError = 'Gagal memproses prediksi: $error';
      _retryAfter = DateTime.now().add(_retryInterval);
      notifyListeners();
    } finally {
      _isPredicting = false;
    }
  }

  void _commitLetter(String letter, double letterConfidence) {
    resultText += letter;

    final category = ttsEnabled ? 'Suara' : 'Teks';
    final item = HistoryItem(
      title: letter,
      type: 'Huruf',
      category: category,
      mode: ttsEnabled ? 'BISINDO → Suara' : 'BISINDO → Teks',
      timestamp: DateTime.now().toIso8601String(),
      confidence: letterConfidence,
    );

    onLetterCommitted?.call(item);
    unawaited(_ttsService.speak(letter));
    unawaited(_syncHistory(item));
  }

  Future<void> _syncHistory(HistoryItem item) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;

    await _apiClient.syncHistory(
      uid: uid,
      name: _userName,
      email: _userEmail,
      entry: {
        'title': item.title,
        'type': item.type,
        'category': item.category,
        'mode': item.mode,
        'confidence': item.confidence,
        'timestamp': item.timestamp,
      },
    );
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
    _handsLostTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _landmarkSub?.cancel();
    _cameraService.dispose();
    _landmarkerService.dispose();
    unawaited(_ttsService.dispose());
    super.dispose();
  }
}
