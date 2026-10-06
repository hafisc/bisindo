import 'package:flutter/material.dart';

class DetectionInfoOverlay extends StatelessWidget {
  final String letter;
  final double confidence;

  const DetectionInfoOverlay({
    required this.letter,
    required this.confidence,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final confPercent = (confidence * 100).round();
    
    Color statusColor;
    IconData statusIcon;
    if (confidence >= 0.75) {
      statusColor = const Color(0xFF9EE7D7); // Cyan/Hijau (Sangat Yakin)
      statusIcon = Icons.auto_awesome;
    } else if (confidence >= 0.4) {
      statusColor = Colors.amber; // Kuning (Kurang Yakin)
      statusIcon = Icons.help_outline;
    } else {
      statusColor = Colors.redAccent; // Merah (Tidak Yakin)
      statusIcon = Icons.error_outline;
    }

    // Jika belum ada deteksi
    final isWaiting = letter == '-';

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isWaiting ? Icons.hourglass_empty : statusIcon, 
              color: isWaiting ? Colors.white54 : statusColor, 
              size: 20
            ),
            const SizedBox(width: 12),
            Text(
              isWaiting ? 'Mencari Isyarat...' : 'Huruf: $letter',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!isWaiting) ...[
              Container(
                height: 18,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white30,
              ),
              Text(
                '$confPercent%',
                style: TextStyle(
                  color: statusColor, 
                  fontSize: 14, 
                  fontWeight: FontWeight.w600
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
