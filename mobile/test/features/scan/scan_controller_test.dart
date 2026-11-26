import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
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
  late List<String> recognizedLetters;

  ScanController createController({
    bool recordHistory = true,
    String? userId = 'uid-test',
  }) {
    return ScanController(
      apiClient: api,
      ttsService: tts,
      cameraService: camera,
      landmarkerService: landmarker,
      now: () => currentNow,
      userIdProvider: () => userId,
      recordHistory: recordHistory,
      onLetterCommitted: committedHistory.add,
      onLetterRecognized: (letter, _) => recognizedLetters.add(letter),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConfig.reset();

    currentNow = DateTime(2026, 11, 26, 9, 0, 0);
    committedHistory = [];
    recognizedLetters = [];
    api = _FakeApiClient();
    tts = _FakeTtsService();
    landmarker = _FakeLandmarkerService();
    camera = _FakeCameraService(
      onStateChanged: () {},
      onError: (_) {},
      onFrame: (_) {},
    );
  });

  group('ScanController inisialisasi & server', () {
    test('initializeCamera mengecek kesehatan server dan menjadi ready', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.initializeCamera();
      await _flushMicrotasks();

      expect(api.healthChecks, 1);
      expect(controller.predictionStatus, PredictionStatus.ready);
      expect(controller.cameraError, isNull);
    });

    test('checkHealth gagal mengubah predictionStatus menjadi error', () async {
      api.healthError = const PredictionException('Server mati');
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.initializeCamera();
      await _flushMicrotasks();

      expect(controller.predictionStatus, PredictionStatus.error);
      expect(controller.predictionError, 'Server mati');
    });

    test('didChangeAppLifecycleState resumed memanggil ulang checkHealth', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _flushMicrotasks();

      expect(api.healthChecks, 1);
    });

    test('setServerAddress memvalidasi, menyimpan, dan resetServerAddress mengembalikan default', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      expect(await controller.setServerAddress('   '), isNotNull);

      expect(await controller.setServerAddress('192.168.1.10:5000'), isNull);
      await _flushMicrotasks();
      expect(controller.serverAddress, '192.168.1.10:5000');
      expect(controller.serverUrl, 'http://192.168.1.10:5000');

      await controller.resetServerAddress();
      await _flushMicrotasks();
      expect(controller.serverUrl, ApiConfig.buildTimeBaseUrl);
    });
  });

  group('ScanController deteksi & stabilisasi', () {
    test('mengunci huruf setelah 3 suara stabil, menyimpan riwayat, dan membacakan TTS', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      for (var i = 0; i < 3; i++) {
        currentNow = currentNow.add(const Duration(milliseconds: 250));
        landmarker.emitHands([_dummyHand()]);
        await _flushMicrotasks();
      }

      expect(api.predictCalls, 3);
      expect(api.lastUserId, 'uid-test');
      expect(controller.detectedLetter, 'A');
      expect(controller.confidence, 0.92);
      expect(controller.resultText, 'A');
      expect(recognizedLetters, ['A']);
      expect(committedHistory, hasLength(1));
      expect(committedHistory.single.title, 'A');
      expect(committedHistory.single.category, 'Suara');
      expect(tts.spoken, ['A']);
    });

    test('mode belajar (recordHistory: false) tidak menambah resultText, riwayat, atau TTS', () async {
      final controller = createController(recordHistory: false);
      addTearDown(controller.dispose);

      for (var i = 0; i < 3; i++) {
        currentNow = currentNow.add(const Duration(milliseconds: 250));
        landmarker.emitHands([_dummyHand()]);
        await _flushMicrotasks();
      }

      expect(recognizedLetters, ['A']);
      expect(controller.resultText, isEmpty);
      expect(committedHistory, isEmpty);
      expect(tts.spoken, isEmpty);
    });

    test('request dalam jeda < 200ms di-throttle', () async {
      final controller = createController();
      addTearDown(controller.dispose);

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
      final controller = createController();
      addTearDown(controller.dispose);

      currentNow = currentNow.add(const Duration(milliseconds: 250));
      landmarker.emitHands([_dummyHand()]);
      await _flushMicrotasks();

      expect(controller.detectedLetter, '-');
      expect(controller.confidence, 0.0);
      expect(controller.predictionStatus, PredictionStatus.ready);
      expect(controller.predictionError, isNull);
    });

    test('PredictionException 5xx/network memicu status error dan jeda retry 2 detik', () async {
      api.predictError = const PredictionException('Timeout');
      final controller = createController();
      addTearDown(controller.dispose);

      currentNow = currentNow.add(const Duration(milliseconds: 250));
      landmarker.emitHands([_dummyHand()]);
      await _flushMicrotasks();

      expect(controller.predictionStatus, PredictionStatus.error);
      expect(controller.predictionError, 'Timeout');

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
      expect(api.predictCalls, 2);
      expect(controller.predictionStatus, PredictionStatus.ready);
    });

    testWidgets('tangan hilang selama 600ms mereset huruf terdeteksi dan mengizinkan huruf sama lagi', (
      tester,
    ) async {
      final controller = createController();
      addTearDown(controller.dispose);

      for (var i = 0; i < 3; i++) {
        currentNow = currentNow.add(const Duration(milliseconds: 250));
        landmarker.emitHands([_dummyHand()]);
        await tester.pump();
      }
      expect(controller.resultText, 'A');

      // Tangan hilang -> tunggu timer 600ms
      landmarker.emitHands(const []);
      await tester.pump(const Duration(milliseconds: 650));

      expect(controller.detectedLetter, '-');
      expect(controller.confidence, 0.0);

      // Tangan muncul kembali dengan A -> bisa terkunci lagi
      for (var i = 0; i < 3; i++) {
        currentNow = currentNow.add(const Duration(milliseconds: 250));
        landmarker.emitHands([_dummyHand()]);
        await tester.pump();
      }
      expect(controller.resultText, 'AA');
    });
  });

  group('ScanController aksi teks & toggle', () {
    test('appendSpace, removeLastCharacter, resetResult, speakSentence, dan toggle bekerja', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      controller.resultText = 'AB';
      controller.appendSpace();
      expect(controller.resultText, 'AB ');

      controller.removeLastCharacter();
      expect(controller.resultText, 'AB');

      controller.speakSentence();
      expect(tts.spoken, ['AB']);

      controller.resetResult();
      expect(controller.resultText, isEmpty);

      controller.toggleSkeleton();
      expect(controller.showSkeleton, isFalse);

      await controller.toggleTts();
      expect(controller.ttsEnabled, isFalse);
      expect(tts.enabled, isFalse);

      await controller.switchCamera();
      expect(camera.switchCalled, isTrue);
    });

    test('dispose membebaskan service terkait', () {
      final controller = createController();
      controller.dispose();

      expect(camera.disposed, isTrue);
      expect(landmarker.disposed, isTrue);
      expect(tts.disposed, isTrue);
    });
  });
}
