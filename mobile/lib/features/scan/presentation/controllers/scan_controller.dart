import 'dart:async';

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../history/domain/models/history_item.dart';
import '../../../history/presentation/providers/history_provider.dart';
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

const Object _unset = Object();

/// Mode operasional controller kamera BISINDO.
enum ScanMode {
  /// Penerjemahan langsung: hasil ditambahkan ke teks, riwayat, dan TTS.
  translate,

  /// Latihan interaktif: hanya memancarkan huruf stabil tanpa riwayat/TTS.
  learn,
}

/// Peristiwa huruf stabil yang baru saja dikunci oleh stabilizer.
class RecognizedLetterEvent extends Equatable {
  final String letter;
  final double confidence;
  final int sequence;

  const RecognizedLetterEvent({
    required this.letter,
    required this.confidence,
    required this.sequence,
  });

  @override
  List<Object?> get props => [letter, confidence, sequence];
}

/// State immutable untuk fitur Scan dan Mode Belajar.
class ScanState extends Equatable {
  final String? cameraError;
  final String? predictionError;
  final String detectedLetter;
  final double confidence;
  final String resultText;
  final PredictionStatus predictionStatus;
  final List<DetectedHand> detectedHands;
  final bool ttsEnabled;
  final bool showSkeleton;
  final CameraController? cameraController;
  final bool isSwitchingCamera;
  final bool hasMultipleCameras;
  final bool isFrontCamera;
  final int cameraRevision;
  final String serverAddress;
  final String serverUrl;
  final RecognizedLetterEvent? lastRecognized;

  const ScanState({
    this.cameraError,
    this.predictionError,
    this.detectedLetter = '-',
    this.confidence = 0.0,
    this.resultText = '',
    this.predictionStatus = PredictionStatus.idle,
    this.detectedHands = const [],
    this.ttsEnabled = true,
    this.showSkeleton = true,
    this.cameraController,
    this.isSwitchingCamera = false,
    this.hasMultipleCameras = false,
    this.isFrontCamera = false,
    this.cameraRevision = 0,
    required this.serverAddress,
    required this.serverUrl,
    this.lastRecognized,
  });

  factory ScanState.initial() {
    return ScanState(
      serverAddress: ApiConfig.display(ApiConfig.baseUrl),
      serverUrl: ApiConfig.baseUrl,
    );
  }

  ScanState copyWith({
    Object? cameraError = _unset,
    Object? predictionError = _unset,
    String? detectedLetter,
    double? confidence,
    String? resultText,
    PredictionStatus? predictionStatus,
    List<DetectedHand>? detectedHands,
    bool? ttsEnabled,
    bool? showSkeleton,
    Object? cameraController = _unset,
    bool? isSwitchingCamera,
    bool? hasMultipleCameras,
    bool? isFrontCamera,
    int? cameraRevision,
    String? serverAddress,
    String? serverUrl,
    Object? lastRecognized = _unset,
  }) {
    return ScanState(
      cameraError: cameraError == _unset ? this.cameraError : cameraError as String?,
      predictionError:
          predictionError == _unset ? this.predictionError : predictionError as String?,
      detectedLetter: detectedLetter ?? this.detectedLetter,
      confidence: confidence ?? this.confidence,
      resultText: resultText ?? this.resultText,
      predictionStatus: predictionStatus ?? this.predictionStatus,
      detectedHands: detectedHands ?? this.detectedHands,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      showSkeleton: showSkeleton ?? this.showSkeleton,
      cameraController: cameraController == _unset
          ? this.cameraController
          : cameraController as CameraController?,
      isSwitchingCamera: isSwitchingCamera ?? this.isSwitchingCamera,
      hasMultipleCameras: hasMultipleCameras ?? this.hasMultipleCameras,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      cameraRevision: cameraRevision ?? this.cameraRevision,
      serverAddress: serverAddress ?? this.serverAddress,
      serverUrl: serverUrl ?? this.serverUrl,
      lastRecognized: lastRecognized == _unset
          ? this.lastRecognized
          : lastRecognized as RecognizedLetterEvent?,
    );
  }

  @override
  List<Object?> get props => [
        cameraError,
        predictionError,
        detectedLetter,
        confidence,
        resultText,
        predictionStatus,
        detectedHands,
        ttsEnabled,
        showSkeleton,
        cameraController,
        isSwitchingCamera,
        hasMultipleCameras,
        isFrontCamera,
        cameraRevision,
        serverAddress,
        serverUrl,
        lastRecognized,
      ];
}

typedef CameraServiceFactory = CameraService Function({
  required VoidCallback onStateChanged,
  required Function(String) onError,
  required Function(CameraImage) onFrame,
});

typedef ScanHistoryWriter = Future<void> Function(HistoryItem item);

// ── Providers ────────────────────────────────────────────────────────────────

final predictionApiClientProvider = Provider<PredictionApiClient>((ref) {
  return PredictionApiClient();
});

final ttsServiceProvider = Provider.autoDispose<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final nativeHandLandmarkerServiceProvider =
    Provider.autoDispose<NativeHandLandmarkerService>((ref) {
  final service = NativeHandLandmarkerService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final predictionStabilizerProvider =
    Provider.autoDispose<PredictionStabilizer>((ref) {
  return PredictionStabilizer();
});

final cameraServiceFactoryProvider = Provider<CameraServiceFactory>((ref) {
  return CameraService.new;
});

final scanNowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final scanUserIdProvider = Provider<String?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.valueOrNull ?? ref.watch(currentUserProvider);
  if (user == null || user.isEmpty) return null;
  return user.id;
});

final scanHistoryWriterProvider = Provider<ScanHistoryWriter>((ref) {
  return (item) => ref.read(historyNotifierProvider.notifier).addHistoryItem(item);
});

final scanAutoInitProvider = Provider<bool>((ref) => true);

final scanControllerProvider =
    AutoDisposeNotifierProviderFamily<ScanController, ScanState, ScanMode>(
  ScanController.new,
);

// ── Controller Notifier ──────────────────────────────────────────────────────

/// Riverpod notifier yang mengelola siklus kamera, MediaPipe landmark,
/// pemanggilan API prediksi BISINDO, stabilisasi huruf, riwayat, dan TTS.
class ScanController extends AutoDisposeFamilyNotifier<ScanState, ScanMode>
    with WidgetsBindingObserver {
  late PredictionApiClient _apiClient;
  late TtsService _ttsService;
  late PredictionStabilizer _stabilizer;
  late NativeHandLandmarkerService _landmarkerService;
  late DateTime Function() _now;
  late ScanHistoryWriter _historyWriter;
  late CameraService _cameraService;

  StreamSubscription<List<DetectedHand>>? _landmarkSub;
  Timer? _handsLostTimer;

  String? _userId;
  bool _isDisposed = false;
  bool _isPredicting = false;
  bool _isCheckingServer = false;
  bool _ttsToggledByUser = false;
  int _recognitionSeq = 0;
  DateTime _lastPredictAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _retryAfter = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _recordHistory => arg == ScanMode.translate;

  @override
  ScanState build(ScanMode arg) {
    _isDisposed = false;
    _isPredicting = false;
    _isCheckingServer = false;
    _ttsToggledByUser = false;
    _recognitionSeq = 0;
    _lastPredictAt = DateTime.fromMillisecondsSinceEpoch(0);
    _retryAfter = DateTime.fromMillisecondsSinceEpoch(0);

    _apiClient = ref.watch(predictionApiClientProvider);
    _ttsService = ref.watch(ttsServiceProvider);
    _stabilizer = ref.watch(predictionStabilizerProvider);
    _landmarkerService = ref.watch(nativeHandLandmarkerServiceProvider);
    _now = ref.watch(scanNowProvider);
    _historyWriter = ref.watch(scanHistoryWriterProvider);
    final cameraFactory = ref.watch(cameraServiceFactoryProvider);

    _userId = ref.read(scanUserIdProvider);
    ref.listen<String?>(scanUserIdProvider, (_, next) {
      _userId = next;
    });

    WidgetsBinding.instance.addObserver(this);
    _landmarkSub = _landmarkerService.handsStream.listen(_onHands);

    _cameraService = cameraFactory(
      onStateChanged: _handleCameraStateChanged,
      onError: _handleCameraError,
      onFrame: _processCameraImage,
    );

    final autoInit = ref.read(scanAutoInitProvider);

    ref.onDispose(() {
      _isDisposed = true;
      _handsLostTimer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
      unawaited(_landmarkSub?.cancel() ?? Future<void>.value());
      _cameraService.dispose();
      unawaited(_landmarkerService.dispose());
      unawaited(_ttsService.dispose());
    });

    Future.microtask(_loadPreferences);
    if (autoInit) {
      Future.microtask(initializeCamera);
    }

    return ScanState(
      cameraController: _cameraService.controller,
      isSwitchingCamera: _cameraService.isSwitchingCamera,
      hasMultipleCameras: _cameraService.hasMultipleCameras,
      isFrontCamera: _cameraService.isFrontCamera,
      serverAddress: ApiConfig.display(ApiConfig.baseUrl),
      serverUrl: ApiConfig.baseUrl,
    );
  }

  void _handleCameraStateChanged() {
    if (_isDisposed) return;
    _syncCameraState();
  }

  void _handleCameraError(String err) {
    if (_isDisposed) return;
    state = state.copyWith(
      cameraError: err,
      cameraController: _cameraService.controller,
      isSwitchingCamera: _cameraService.isSwitchingCamera,
      hasMultipleCameras: _cameraService.hasMultipleCameras,
      isFrontCamera: _cameraService.isFrontCamera,
      cameraRevision: state.cameraRevision + 1,
    );
  }

  void _syncCameraState() {
    state = state.copyWith(
      cameraController: _cameraService.controller,
      isSwitchingCamera: _cameraService.isSwitchingCamera,
      hasMultipleCameras: _cameraService.hasMultipleCameras,
      isFrontCamera: _cameraService.isFrontCamera,
      cameraRevision: state.cameraRevision + 1,
    );
  }

  Future<void> _loadPreferences() async {
    await _ttsService.load();
    if (_isDisposed || _ttsToggledByUser) return;
    state = state.copyWith(ttsEnabled: _ttsService.enabled);
  }

  Future<void> initializeCamera() async {
    if (_isDisposed) return;
    state = state.copyWith(cameraError: null);
    await _cameraService.initialize();
    if (_isDisposed) return;
    _syncCameraState();
    unawaited(_checkServer());
  }

  Future<void> switchCamera() async {
    _stabilizer.reset();
    await _cameraService.switchCamera();
    if (!_isDisposed) {
      _syncCameraState();
    }
  }

  /// Periksa apakah server bisa dihubungi dan modelnya termuat.
  Future<void> _checkServer() async {
    if (_isDisposed || _isCheckingServer) return;

    _isCheckingServer = true;
    state = state.copyWith(
      predictionStatus: PredictionStatus.connecting,
      predictionError: null,
    );

    try {
      await _apiClient.checkHealth();
      if (_isDisposed) return;
      state = state.copyWith(
        predictionStatus: PredictionStatus.ready,
        predictionError: null,
      );
    } on PredictionException catch (error) {
      if (_isDisposed) return;
      state = state.copyWith(
        predictionStatus: PredictionStatus.error,
        predictionError: error.message,
      );
    } catch (error) {
      if (_isDisposed) return;
      state = state.copyWith(
        predictionStatus: PredictionStatus.error,
        predictionError: 'Gagal memeriksa server: $error',
      );
    } finally {
      _isCheckingServer = false;
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
    if (_isDisposed) return null;
    _stabilizer.reset();
    _retryAfter = DateTime.fromMillisecondsSinceEpoch(0);
    state = state.copyWith(
      serverAddress: ApiConfig.display(ApiConfig.baseUrl),
      serverUrl: ApiConfig.baseUrl,
    );
    unawaited(_checkServer());
    return null;
  }

  Future<void> resetServerAddress() async {
    await ApiConfig.reset();
    if (_isDisposed) return;
    _stabilizer.reset();
    state = state.copyWith(
      serverAddress: ApiConfig.display(ApiConfig.baseUrl),
      serverUrl: ApiConfig.baseUrl,
    );
    unawaited(_checkServer());
  }

  void toggleSkeleton() {
    state = state.copyWith(showSkeleton: !state.showSkeleton);
  }

  Future<void> toggleTts() async {
    _ttsToggledByUser = true;
    final next = !state.ttsEnabled;
    state = state.copyWith(ttsEnabled: next);
    await _ttsService.setEnabled(next);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isDisposed) {
      unawaited(_checkServer());
    }
  }

  void _onHands(List<DetectedHand> hands) {
    if (_isDisposed) return;

    if (hands.isEmpty) {
      // Beri jeda singkat: deteksi bisa kosong satu-dua frame saat tangan
      // bergerak. Setelah itu, tanda berikutnya boleh sama lagi.
      _handsLostTimer ??= Timer(const Duration(milliseconds: 600), () {
        _handsLostTimer = null;
        if (_isDisposed) return;
        _stabilizer.markHandsLost();
        state = state.copyWith(
          detectedLetter: '-',
          confidence: 0.0,
        );
      });
    } else {
      _handsLostTimer?.cancel();
      _handsLostTimer = null;
    }

    state = state.copyWith(detectedHands: hands);
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
    final hands = state.detectedHands;
    if (hands.isEmpty) return;
    if (_cameraService.controller == null) return;

    final now = _now();
    if (now.isBefore(_retryAfter)) return;
    if (now.difference(_lastPredictAt) < _predictInterval) return;

    _lastPredictAt = now;
    _isPredicting = true;

    try {
      final result = await _apiClient.predict(
        hands: hands,
        userId: _userId,
      );
      if (_isDisposed) return;

      final committed = _stabilizer.add(result);
      final recognizedEvent = committed == null
          ? null
          : RecognizedLetterEvent(
              letter: committed,
              confidence: result.confidence,
              sequence: ++_recognitionSeq,
            );

      var nextResultText = state.resultText;
      if (committed != null && _recordHistory) {
        nextResultText = '$nextResultText$committed';
        _saveAndSpeakLetter(committed, result.confidence);
      }

      state = state.copyWith(
        predictionStatus: PredictionStatus.ready,
        predictionError: null,
        detectedLetter: result.prediction,
        confidence: result.confidence,
        resultText: nextResultText,
        lastRecognized: recognizedEvent ?? _unset,
      );
    } on PredictionException catch (error) {
      if (_isDisposed) return;

      if (error.isRejected) {
        // Server menjawab, hanya datanya yang belum layak (misalnya tangan
        // terlalu kecil). Jangan tampilkan seolah server mati.
        state = state.copyWith(
          detectedLetter: '-',
          confidence: 0.0,
          predictionStatus: PredictionStatus.ready,
          predictionError: null,
        );
      } else {
        _retryAfter = _now().add(_retryInterval);
        state = state.copyWith(
          predictionStatus: PredictionStatus.error,
          predictionError: error.message,
        );
      }
    } catch (error) {
      if (_isDisposed) return;
      _retryAfter = _now().add(_retryInterval);
      state = state.copyWith(
        predictionStatus: PredictionStatus.error,
        predictionError: 'Gagal memproses prediksi: $error',
      );
    } finally {
      _isPredicting = false;
    }
  }

  void _saveAndSpeakLetter(String letter, double letterConfidence) {
    final ttsActive = state.ttsEnabled;
    final category = ttsActive ? 'Suara' : 'Teks';
    final item = HistoryItem(
      title: letter,
      type: 'Huruf',
      category: category,
      mode: ttsActive ? 'BISINDO → Suara' : 'BISINDO → Teks',
      timestamp: _now().toIso8601String(),
      confidence: letterConfidence,
    );

    // Riwayat disimpan dan dikirim ke server oleh HistoryNotifier.
    unawaited(_historyWriter(item));
    unawaited(_ttsService.speak(letter));
  }

  void appendSpace() {
    state = state.copyWith(resultText: '${state.resultText} ');
  }

  void removeLastCharacter() {
    if (state.resultText.isNotEmpty) {
      state = state.copyWith(
        resultText: state.resultText.substring(0, state.resultText.length - 1),
      );
    }
  }

  void resetResult() {
    state = state.copyWith(resultText: '');
  }

  void speakSentence() {
    final text = state.resultText.trim();
    if (text.isNotEmpty) {
      unawaited(_ttsService.speak(text));
    }
  }

  @visibleForTesting
  void setResultTextForTest(String value) {
    state = state.copyWith(resultText: value);
  }
}
