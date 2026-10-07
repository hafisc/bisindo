import 'package:flutter/material.dart';

/// Tombol untuk mengganti antara kamera depan dan belakang.
class CameraSwitchButton extends StatefulWidget {
  final bool isFrontCamera;
  final bool isSwitching;
  final bool isEnabled;
  final VoidCallback onPressed;

  const CameraSwitchButton({
    required this.isFrontCamera,
    required this.isSwitching,
    required this.isEnabled,
    required this.onPressed,
    super.key,
  });

  @override
  State<CameraSwitchButton> createState() => _CameraSwitchButtonState();
}

class _CameraSwitchButtonState extends State<CameraSwitchButton> {
  DateTime _lastTapAt = DateTime.fromMillisecondsSinceEpoch(0);

  void _handleTap() {
    // Debounce: cegah tap beruntun yang memicu race condition saat switch.
    final now = DateTime.now();
    if (now.difference(_lastTapAt).inMilliseconds < 800) return;
    _lastTapAt = now;
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.isEnabled && !widget.isSwitching;
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isEnabled ? _handleTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: widget.isSwitching
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  widget.isFrontCamera
                      ? Icons.camera_rear_rounded
                      : Icons.camera_front_rounded,
                  color: isEnabled ? Colors.white : Colors.white38,
                  size: 24,
                ),
        ),
      ),
    );
  }
}
