import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bisindo_translator/core/config/api_config.dart';
import 'package:bisindo_translator/features/history/domain/models/history_item.dart';
import 'package:bisindo_translator/features/scan/data/models/prediction_result.dart';
import 'package:bisindo_translator/features/scan/data/models/prediction_status.dart';
import 'package:bisindo_translator/features/scan/data/services/camera_service.dart';
import 'package:bisindo_translator/features/scan/data/services/native_hand_landmarker_service.dart';
import 'package:bisindo_translator/features/scan/data/services/prediction_api_client.dart';
import 'package:bisindo_translator/features/scan/data/services/tts_service.dart';
import 'package:bisindo_translator/features/scan/presentation/controllers/scan_controller.dart';

class _FakeCameraController extends Fake implements CameraController {}

class _FakeCameraService implements CameraService {
  @override
  final VoidCallback onStateChanged;

  @override
  final Function(String) onError;

  @override
  final Function(CameraImage) onFrame;

  _FakeCameraService({
    required this.onStateChanged,
    required this.onError,
    required this.onFrame,
  });

  @override
  CameraController? controller = _FakeCameraController();

  @override
  bool isSwitchingCamera = false;

  @override
  bool hasMultipleCameras = true;

  @override
  bool isFrontCamera = true;

  @override
  int sensorOrientation = 270;

  bool initShouldFail = false;
  bool switchCalled = false;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    if (initShouldFail) {
      onError('Izin kamera diperlukan untuk fitur ini.');
      return;
    }
    onStateChanged();
  }

  @override
  Future<void> switchCamera() async {
    switchCalled = true;
    isFrontCamera = !isFrontCamera;
    onStateChanged();
  }

  @override
  void dispose() {
    disposed = true;
  }
}

class _FakeLandmarkerService implements NativeHandLandmarkerService {
  final StreamController<List<DetectedHand>> _controller =
      StreamController<List<DetectedHand>>.broadcast();

  bool disposed = false;

  @override
  Stream<List<DetectedHand>> get handsStream => _controller.stream;

  void emitHands(List<DetectedHand> hands) {
    if (!_controller.isClosed) _controller.add(hands);
  }

  @override
  Future<void> processCameraImage(
    CameraImage image, {
    int sensorOrientation = 0,
  }) async {}

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }
}

class _FakeApiClient implements PredictionApiClient {
  PredictionException? healthError;
  Object? predictError;
  PredictionResult nextResult =
      const PredictionResult(prediction: 'A', confidence: 0.92);

  int healthChecks = 0;
  int predictCalls = 0;
  String? lastUserId;

  @override
  String get baseUrl => ApiConfig.baseUrl;

  @override
  Future<void> checkHealth() async {
    healthChecks++;
    if (healthError != null) throw healthError!;
  }

  @override
  Future<PredictionResult> predict({
    required List<DetectedHand> hands,
    String? userId,
  }) async {
    predictCalls++;
    lastUserId = userId;
    if (predictError != null) throw predictError!;
    return nextResult;
  }
}

class _FakeTtsService implements TtsService {
  bool _enabled = true;
  final List<String> spoken = [];
  bool disposed = false;

  @override
  bool get enabled => _enabled;

  @override
  Future<void> load() async {}

  @override
  Future<void> setEnabled(bool value) async {
    _enabled = value;
  }

  @override
  Future<void> speak(String text) async {
    if (_enabled && text.trim().isNotEmpty) {
      spoken.add(text.trim());
    }
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

DetectedHand _dummyHand() {
  return DetectedHand(
    label: 'Right',
    score: 0.95,
    landmarks: List.generate(
      21,
      (i) => LandmarkPoint(x: i * 0.01, y: i * 0.01, z: 0.0),
    ),
  );
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeCameraService camera;
  late _FakeLandmarkerService landmarker;
  late _FakeApiClient api;
  late _FakeTtsService tts;
  late DateTime currentNow;
  late List<HistoryItem> committedHistory;

  ProviderContainer createContainer({
    ScanMode mode = ScanMode.translate,
    String? userId = 'uid-test',
  }) {
    final container = ProviderContainer(
      overrides: [
        predictionApiClientProvider.overrideWithValue(api),
        ttsServiceProvider.overrideWithValue(tts),
        nativeHandLandmarkerServiceProvider.overrideWithValue(landmarker),
        cameraServiceFactoryProvider.overrideWithValue(
          ({
            required onStateChanged,
            required onError,
            required onFrame,
          }) {
            camera = _FakeCameraService(
              onStateChanged: onStateChanged,
              onError: onError,
              onFrame: onFrame,
            );
            return camera;
          },
        ),
        scanNowProvider.overrideWithValue(() => currentNow),
        scanUserIdProvider.overrideWithValue(userId),
        scanHistoryWriterProvider.overrideWithValue(
          (item) async => committedHistory.add(item),
        ),
        scanAutoInitProvider.overrideWithValue(false),
      ],
    );
    // Pertahankan AutoDisposeFamilyNotifier tetap hidup sepanjang test.
    container.listen(scanControllerProvider(mode), (_, _) {});
    return container;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConfig.reset();

    currentNow = DateTime(2026, 11, 26, 9, 0, 0);
    committedHistory = [];
    api = _FakeApiClient();
    tts = _FakeTtsService();
    landmarker = _FakeLandmarkerService();
  });

  group('ScanController inisialisasi & server', () {
    test('initializeCamera mengecek kesehatan server dan menjadi ready', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller =
          container.read(scanControllerProvider(ScanMode.translate).notifier);
      await controller.initializeCamera();
      await _flushMicrotasks();

      final state = container.read(scanControllerProvider(ScanMode.translate));
      expect(api.healthChecks, 1);
      expect(state.predictionStatus, PredictionStatus.ready);
      expect(state.cameraError, isNull);
    });

    test('checkHealth gagal mengubah predictionStatus menjadi error', () async {
      api.healthError = const PredictionException('Server mati');
      final container = createContainer();
      addTearDown(container.dispose);

      final controller =
          container.read(scanControllerProvider(ScanMode.translate).notifier);
      await controller.initializeCamera();
      await _flushMicrotasks();

      final state = container.read(scanControllerProvider(ScanMode.translate));
      expect(state.predictionStatus, PredictionStatus.error);
      expect(state.predictionError, 'Server mati');
    });

    test('didChangeAppLifecycleState resumed memanggil ulang checkHealth', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller =
          container.read(scanControllerProvider(ScanMode.translate).notifier);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _flushMicrotasks();

      expect(api.healthChecks, 1);
    });

    test('setServerAddress memvalidasi, menyimpan, dan resetServerAddress mengembalikan default', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller =
          container.read(scanControllerProvider(ScanMode.translate).notifier);
      expect(await controller.setServerAddress('   '), isNotNull);

      expect(await controller.setServerAddress('192.168.1.10:5000'), isNull);
      await _flushMicrotasks();
      var state = container.read(scanControllerProvider(ScanMode.translate));
      expect(state.serverAddress, '192.168.1.10:5000');
      expect(state.serverUrl, 'http://192.168.1.10:5000');

      await controller.resetServerAddress();
      await _flushMicrotasks();
      state = container.read(scanControllerProvider(ScanMode.translate));
      expect(state.serverUrl, ApiConfig.buildTimeBaseUrl);
    });
  });

  group('ScanController deteksi & stabilisasi', () {
    test('mengunci huruf setelah 3 suara stabil, menyimpan riwayat, dan membacakan TTS', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      for (var i = 0; i < 3; i++) {
        currentNow = currentNow.add(const Duration(milliseconds: 250));
        landmarker.emitHands([_dummyHand()]);
        await _flushMicrotasks();
      }

      final state = container.read(scanControllerProvider(ScanMode.translate));
      expect(api.predictCalls, 3);
      expect(api.lastUserId, 'uid-test');
      expect(state.detectedLetter, 'A');
      expect(state.confidence, 0.92);
      expect(state.resultText, 'A');
      expect(state.lastRecognized?.letter, 'A');
      expect(committedHistory, hasLength(1));
      expect(committedHistory.single.title, 'A');
      expect(committedHistory.single.category, 'Suara');
      expect(tts.spoken, ['A']);
    });

    test('mode belajar memancarkan lastRecognized tanpa menambah resultText, riwayat, atau TTS', () async {
      final container = createContainer(mode: ScanMode.learn);
      addTearDown(container.dispose);

      final recognizedLetters = <String>[];
      container.listen<RecognizedLetterEvent?>(
        scanControllerProvider(ScanMode.learn).select((s) => s.lastRecognized),
        (prev, next) {
          if (next != null && next != prev) {
            recognizedLetters.add(next.letter);
          }
        },
      );

      for (var i = 0; i < 3; i++) {
        currentNow = currentNow.add(const Duration(milliseconds: 250));
        landmarker.emitHands([_dummyHand()]);
        await _flushMicrotasks();
      }

      final state = container.read(scanControllerProvider(ScanMode.learn));
      expect(recognizedLetters, ['A']);
      expect(state.resultText, isEmpty);
      expect(committedHistory, isEmpty);
      expect(tts.spoken, isEmpty);
    });

    test('request dalam jeda < 200ms di-throttle', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      currentNow = currentNow.add(const Duration(milliseconds: 250));
      landmarker.emitHands([_dummyHand()]);
      await _flushMicrotasks();

      currentNow = currentNow.add(const Duration(milliseconds: 100));
      landmarker.emitHands([_dummyHand()]);
      await _flushMicrotasks();

      expect(api.predictCalls, 1);
    });

    test('PredictionException 4xx (rejected) mereset huruf tanpa status error', () async {
      api.predictError = const PredictionException('Tangan terlalu kecil', statusCode: 400);
      final container = createContainer();
      addTearDown(container.dispose);

      currentNow = currentNow.add(const Duration(milliseconds: 250));
      landmarker.emitHands([_dummyHand()]);
      await _flushMicrotasks();

      final state = container.read(scanControllerProvider(ScanMode.translate));
      expect(state.detectedLetter, '-');
      expect(state.confidence, 0.0);
      expect(state.predictionStatus, PredictionStatus.ready);
      expect(state.predictionError, isNull);
    });

    test('PredictionException 5xx/network memicu status error dan jeda retry 2 detik', () async {
      api.predictError = const PredictionException('Timeout');
      final container = createContainer();
      addTearDown(container.dispose);

      currentNow = currentNow.add(const Duration(milliseconds: 250));
      landmarker.emitHands([_dummyHand()]);
      await _flushMicrotasks();

      var state = container.read(scanControllerProvider(ScanMode.translate));
      expect(state.predictionStatus, PredictionStatus.error);
      expect(state.predictionError, 'Timeout');

      // Dalam 1 detik belum boleh memanggil server lagi
      currentNow = currentNow.add(const Duration(seconds: 1));
      landmarker.emitHands([_dummyHand()]);
      await _flushMicrotasks();
      expect(api.predictCalls, 1);

      // Setelah lewat 2 detik boleh mencoba lagi
      api.predictError = null;
      currentNow = currentNow.add(const Duration(seconds: 2));
      landmarker.emitHands([_dummyHand()]);
      await _flushMicrotasks();
      state = container.read(scanControllerProvider(ScanMode.translate));
      expect(api.predictCalls, 2);
      expect(state.predictionStatus, PredictionStatus.ready);
    });

    testWidgets('tangan hilang selama 600ms mereset huruf terdeteksi dan mengizinkan huruf sama lagi', (
      tester,
    ) async {
      final container = createContainer();
      addTearDown(container.dispose);

      for (var i = 0; i < 3; i++) {
        currentNow = currentNow.add(const Duration(milliseconds: 250));
        landmarker.emitHands([_dummyHand()]);
        await tester.pump();
      }
      expect(
        container.read(scanControllerProvider(ScanMode.translate)).resultText,
        'A',
      );

      // Tangan hilang -> tunggu timer 600ms
      landmarker.emitHands(const []);
      await tester.pump(const Duration(milliseconds: 650));

      var state = container.read(scanControllerProvider(ScanMode.translate));
      expect(state.detectedLetter, '-');
      expect(state.confidence, 0.0);

      // Tangan muncul kembali dengan A -> bisa terkunci lagi
      for (var i = 0; i < 3; i++) {
        currentNow = currentNow.add(const Duration(milliseconds: 250));
        landmarker.emitHands([_dummyHand()]);
        await tester.pump();
      }
      state = container.read(scanControllerProvider(ScanMode.translate));
      expect(state.resultText, 'AA');
    });
  });

  group('ScanController aksi teks & toggle', () {
    test('appendSpace, removeLastCharacter, resetResult, speakSentence, dan toggle bekerja', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller =
          container.read(scanControllerProvider(ScanMode.translate).notifier);

      controller.setResultTextForTest('AB');
      controller.appendSpace();
      expect(
        container.read(scanControllerProvider(ScanMode.translate)).resultText,
        'AB ',
      );

      controller.removeLastCharacter();
      expect(
        container.read(scanControllerProvider(ScanMode.translate)).resultText,
        'AB',
      );

      controller.speakSentence();
      expect(tts.spoken, ['AB']);

      controller.resetResult();
      expect(
        container.read(scanControllerProvider(ScanMode.translate)).resultText,
        isEmpty,
      );

      controller.toggleSkeleton();
      expect(
        container.read(scanControllerProvider(ScanMode.translate)).showSkeleton,
        isFalse,
      );

      await controller.toggleTts();
      expect(
        container.read(scanControllerProvider(ScanMode.translate)).ttsEnabled,
        isFalse,
      );
      expect(tts.enabled, isFalse);

      await controller.switchCamera();
      expect(camera.switchCalled, isTrue);
    });

    test('dispose membebaskan service terkait', () {
      final container = createContainer();
      container.dispose();

      expect(camera.disposed, isTrue);
      expect(landmarker.disposed, isTrue);
      expect(tts.disposed, isTrue);
    });
  });
}
