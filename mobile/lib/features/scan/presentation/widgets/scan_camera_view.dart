import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ScanCameraView extends StatelessWidget {
  final CameraController? controller;
  final String? errorMessage;
  final VoidCallback onRetry;

  const ScanCameraView({
    required this.controller,
    required this.errorMessage,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return _CameraError(message: errorMessage!, onRetry: onRetry);
    }

    final cameraController = controller;
    // Cek isInitialized; jika controller sudah disposed, value-nya juga
    // tidak initialized sehingga aman menampilkan loading.
    CameraValue? value;
    try {
      value = cameraController?.value;
    } catch (_) {
      value = null;
    }
    if (cameraController == null || value == null || !value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return _CameraPreviewBox(controller: cameraController);
  }
}

class _CameraPreviewBox extends StatelessWidget {
  final CameraController controller;

  const _CameraPreviewBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    // CameraPreview selalu melaporkan size dalam orientasi landscape
    // (lebar = sisi panjang). Di layar portrait kita perlu menukarnya agar
    // rasio aspek benar dan tidak terjadi crop berlebihan.
    final deviceOrientation = MediaQuery.of(context).orientation;
    final isPortrait = deviceOrientation == Orientation.portrait;

    final width = isPortrait ? previewSize.height : previewSize.width;
    final height = isPortrait ? previewSize.width : previewSize.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: width,
            height: height,
            child: CameraPreview(controller),
          ),
        );
      },
    );
  }
}

class _CameraError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CameraError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
