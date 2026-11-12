import 'package:flutter/material.dart';

import '../../../../core/config/api_config.dart';

/// Dialog untuk mengubah alamat server tanpa build ulang aplikasi.
///
/// Ini penting saat aplikasi dipakai di perangkat lain: alamat IP laptop
/// pengguna berbeda, dan WiFi bisa berganti. Alamat disimpan di perangkat.
class ServerSettingsDialog extends StatefulWidget {
  final String currentUrl;
  final Future<String?> Function(String raw) onSave;
  final Future<void> Function() onReset;

  const ServerSettingsDialog({
    required this.currentUrl,
    required this.onSave,
    required this.onReset,
    super.key,
  });

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiConfig.display(widget.currentUrl));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.onSave(_controller.text);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _reset() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    await widget.onReset();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161A22),
      title: const Text(
        'Alamat Server',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan alamat server BISINDO. Lewat kabel USB, isi 127.0.0.1:5000 '
            'setelah menjalankan adb reverse. Lewat WiFi, isi alamat IP laptop '
            'yang tercetak di terminal saat server dijalankan.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            enabled: !_saving,
            keyboardType: TextInputType.url,
            autocorrect: false,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '192.168.1.5:5000',
              hintStyle: const TextStyle(color: Colors.white38),
              errorText: _error,
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          Text(
            'Alamat bawaan: ${ApiConfig.display(ApiConfig.buildTimeBaseUrl)}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _saving ? null : _reset,
          child: const Text('Alamat bawaan'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
