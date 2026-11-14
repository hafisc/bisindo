import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/router/app_router.dart';
import '../../../scan/presentation/controllers/scan_controller.dart';
import '../../../scan/presentation/widgets/connection_status_indicator.dart';
import '../../../scan/presentation/widgets/hand_landmarks_painter.dart';
import '../../../scan/presentation/widgets/scan_camera_view.dart';
import '../../domain/learn_session.dart';

/// Jeda setelah jawaban benar sebelum pindah ke huruf berikutnya.
const Duration _nextLetterDelay = Duration(milliseconds: 1000);

/// Mode Belajar: pengguna memperagakan huruf target ke kamera dan model
/// memeriksa apakah peragaannya benar.
class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  late final ScanController _controller;
  final LearnSession _session = LearnSession();

  /// Huruf yang baru saja dikenali model, untuk banner umpan balik.
  String? _lastLetter;
  LearnAnswer? _lastAnswer;

  /// Huruf target yang sedang ditampilkan. Saat jawaban benar, nilai ini
  /// tetap menunjukkan huruf lama sampai jeda selesai.
  String? _shownTarget;
  bool _waitingNext = false;
  Timer? _nextTimer;

  @override
  void initState() {
    super.initState();
    _shownTarget = _session.current;
    _controller = ScanController(
      recordHistory: false,
      onLetterRecognized: _onLetterRecognized,
    )..initializeCamera();
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onLetterRecognized(String letter, double confidence) {
    if (!mounted || _waitingNext || _session.isFinished) return;

    final answer = _session.submit(letter);
    if (answer == LearnAnswer.ignored) return;

    setState(() {
      _lastLetter = letter;
      _lastAnswer = answer;
    });

    if (answer == LearnAnswer.correct) {
      _waitingNext = true;
      _nextTimer = Timer(_nextLetterDelay, () {
        if (!mounted) return;
        setState(() {
          _waitingNext = false;
          _clearFeedback();
          _shownTarget = _session.current;
        });
      });
    }
  }

  void _clearFeedback() {
    _lastLetter = null;
    _lastAnswer = null;
  }

  void _skip() {
    if (_waitingNext) return;
    setState(() {
      _session.skip();
      _clearFeedback();
      _shownTarget = _session.current;
    });
  }

  void _restart() {
    _nextTimer?.cancel();
    setState(() {
      _session.restart();
      _waitingNext = false;
      _clearFeedback();
      _shownTarget = _session.current;
    });
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finished = _shownTarget == null;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              ScanCameraView(
                controller: _controller.cameraController,
                errorMessage: _controller.cameraError,
                onRetry: _controller.initializeCamera,
              ),
              if (_controller.cameraError == null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: HandLandmarksPainter(
                        hands: _controller.detectedHands,
                        isFrontCamera: _controller.isFrontCamera,
                        imageSize:
                            _controller.cameraController?.value.previewSize,
                      ),
                    ),
                  ),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _RoundButton(
                            icon: Icons.arrow_back,
                            tooltip: 'Kembali',
                            onPressed: _goBack,
                          ),
                          const Spacer(),
                          _ProgressChip(
                            index: finished
                                ? _session.length
                                : _session.currentIndex +
                                    (_waitingNext ? 0 : 1),
                            total: _session.length,
                            score: _session.score,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ConnectionStatusIndicator(
                        status: _controller.predictionStatus,
                        serverAddress: _controller.serverAddress,
                        errorMessage: _controller.predictionError,
                        onRetry: _controller.refreshServer,
                      ),
                      const Spacer(),
                      if (finished)
                        _ResultCard(
                          score: _session.score,
                          total: _session.length,
                          onRestart: _restart,
                          onBack: _goBack,
                        )
                      else
                        _TargetCard(
                          target: _shownTarget!,
                          detected: _controller.detectedLetter,
                          answer: _lastAnswer,
                          answeredLetter: _lastLetter,
                          onSkip: _waitingNext ? null : _skip,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final int index;
  final int total;
  final int score;

  const _ProgressChip({
    required this.index,
    required this.total,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        'Huruf $index/$total  ·  Skor $score',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final String target;
  final String detected;
  final LearnAnswer? answer;
  final String? answeredLetter;
  final VoidCallback? onSkip;

  const _TargetCard({
    required this.target,
    required this.detected,
    required this.answer,
    required this.answeredLetter,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Peragakan huruf',
            style: TextStyle(color: AppPalette.gray600, fontSize: 15),
          ),
          Text(
            target,
            style: const TextStyle(
              color: AppPalette.primary,
              fontSize: 72,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Terbaca kamera: $detected',
            style: const TextStyle(color: AppPalette.gray400, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _FeedbackBanner(answer: answer, letter: answeredLetter),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSkip,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Lewati'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final LearnAnswer? answer;
  final String? letter;

  const _FeedbackBanner({required this.answer, required this.letter});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String text;

    switch (answer) {
      case LearnAnswer.correct:
        color = AppPalette.success;
        icon = Icons.check_circle_rounded;
        text = 'Benar!';
      case LearnAnswer.wrong:
        color = AppPalette.error;
        icon = Icons.cancel_rounded;
        text = 'Terdeteksi $letter, coba lagi';
      case LearnAnswer.ignored:
      case null:
        color = AppPalette.gray400;
        icon = Icons.back_hand_rounded;
        text = 'Arahkan tangan ke kamera';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onRestart;
  final VoidCallback onBack;

  const _ResultCard({
    required this.score,
    required this.total,
    required this.onRestart,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: AppPalette.yellow,
            size: 56,
          ),
          const SizedBox(height: 8),
          const Text(
            'Latihan selesai',
            style: TextStyle(
              color: AppPalette.gray800,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Skor $score/$total',
            style: const TextStyle(
              color: AppPalette.primary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onRestart,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Ulangi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
