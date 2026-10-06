import 'package:flutter/material.dart';

import '../../data/services/prediction_socket.dart';

/// Indikator kecil yang menunjukkan status koneksi WebSocket ke server.
class ConnectionStatusIndicator extends StatelessWidget {
  final SocketStatus status;

  const ConnectionStatusIndicator({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;
    final bool spinning;

    switch (status) {
      case SocketStatus.connected:
        color = const Color(0xFF22C55E); // hijau
        label = 'Terhubung';
        icon = Icons.wifi;
        spinning = false;
      case SocketStatus.connecting:
        color = Colors.amber;
        label = 'Menghubungkan...';
        icon = Icons.wifi_find;
        spinning = true;
      case SocketStatus.reconnecting:
        color = Colors.orange;
        label = 'Menghubungkan ulang...';
        icon = Icons.sync;
        spinning = true;
      case SocketStatus.idle:
        color = Colors.redAccent;
        label = 'Terputus';
        icon = Icons.wifi_off;
        spinning = false;
    }

    return Container(
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
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
