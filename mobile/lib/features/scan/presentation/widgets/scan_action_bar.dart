import 'package:flutter/material.dart';

class ScanActionBar extends StatelessWidget {
  final String resultText;
  final VoidCallback onSpacePressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onResetPressed;

  const ScanActionBar({
    required this.resultText,
    required this.onSpacePressed,
    required this.onBackspacePressed,
    required this.onResetPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xF20F1117),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              resultText.isEmpty
                  ? 'Hasil terjemahan akan muncul di sini'
                  : resultText,
              style: TextStyle(
                color: resultText.isEmpty ? Colors.white54 : Colors.white,
                fontSize: 17,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.space_bar_rounded,
                  label: 'Spasi',
                  onPressed: onSpacePressed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.backspace_outlined,
                  label: 'Hapus',
                  onPressed: onBackspacePressed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.restart_alt_rounded,
                  label: 'Reset',
                  onPressed: onResetPressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: FilledButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF2A3042),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
