import 'package:flutter/material.dart';

import '../../data/models/prediction_status.dart';

/// Indikator status hubungan aplikasi dengan server prediksi.
///
/// Menampilkan alamat server yang sedang dipakai, karena alamat itu bisa
/// berbeda di setiap perangkat. Saat gagal, pesan galat dan tombol coba lagi
/// ditampilkan agar pengguna tidak perlu menebak penyebabnya.
class ConnectionStatusIndicator extends StatelessWidget {
  final PredictionStatus status;
  final String serverAddress;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ConnectionStatusIndicator({
    required this.status,
    required this.serverAddress,
    this.errorMessage,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;
    final bool spinning;

    switch (status) {
      case PredictionStatus.ready:
        color = const Color(0xFF22C55E);
        label = 'Terhubung ke $serverAddress';
        icon = Icons.wifi;
        spinning = false;
      case PredictionStatus.connecting:
        color = Colors.amber;
        label = 'Menghubungi $serverAddress...';
        icon = Icons.wifi_find;
        spinning = true;
      case PredictionStatus.error:
        color = Colors.redAccent;
        label = 'Server tidak terhubung';
        icon = Icons.wifi_off;
        spinning = false;
      case PredictionStatus.idle:
        color = Colors.white70;
        label = 'Server belum diperiksa';
        icon = Icons.wifi_tethering;
        spinning = false;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (spinning)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color),
                )
              else
                Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (status == PredictionStatus.error && errorMessage != null)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (onRetry != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF9EE7D7),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Coba lagi'),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
