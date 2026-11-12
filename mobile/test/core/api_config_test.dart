import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/core/config/api_config.dart';

void main() {
  group('ApiConfig.normalize', () {
    test('menambah http:// bila belum ada', () {
      expect(ApiConfig.normalize('192.168.1.5:5000'), 'http://192.168.1.5:5000');
    });

    test('membuang garis miring di akhir', () {
      expect(ApiConfig.normalize('http://192.168.1.5:5000/'), 'http://192.168.1.5:5000');
    });

    test('membuang akhiran /api', () {
      expect(ApiConfig.normalize('http://192.168.1.5:5000/api'), 'http://192.168.1.5:5000');
    });

    test('mempertahankan https', () {
      expect(ApiConfig.normalize('https://bisindo.example.com'), 'https://bisindo.example.com');
    });

    test('nilai kosong kembali ke alamat bawaan', () {
      expect(ApiConfig.normalize('   '), ApiConfig.buildTimeBaseUrl);
    });
  });

  group('ApiConfig.validate', () {
    test('menerima alamat IP dengan port', () {
      expect(ApiConfig.validate('192.168.1.5:5000'), isNull);
    });

    test('menerima URL lengkap', () {
      expect(ApiConfig.validate('https://bisindo.example.com'), isNull);
    });

    test('menolak teks kosong', () {
      expect(ApiConfig.validate('   '), isNotNull);
    });

    test('menolak alamat tanpa host', () {
      expect(ApiConfig.validate('http://'), isNotNull);
    });
  });

  group('ApiConfig.display', () {
    test('menghilangkan skema', () {
      expect(ApiConfig.display('http://192.168.1.5:5000'), '192.168.1.5:5000');
    });
  });

  group('alamat bawaan', () {
    test('memakai alamat adb reverse, bukan alias emulator', () {
      // 10.0.2.2 hanya ada di emulator, sedangkan kamera MediaPipe hanya bisa
      // diuji di HP fisik. Alamat bawaan harus bisa dipakai lewat kabel USB.
      expect(ApiConfig.buildTimeBaseUrl, 'http://127.0.0.1:5000');
      expect(ApiConfig.buildTimeBaseUrl.contains('10.0.2.2'), isFalse);
    });
  });
}
