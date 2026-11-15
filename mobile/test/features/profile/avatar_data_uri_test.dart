import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/features/profile/domain/avatar_data_uri.dart';

void main() {
  group('AvatarDataUri', () {
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0xFF, 0xD9]);

    test('encode lalu decode menghasilkan isi yang sama', () {
      final uri = AvatarDataUri.encode(jpeg);

      expect(uri, startsWith('data:image/jpeg;base64,'));
      expect(AvatarDataUri.decode(uri), jpeg);
    });

    test('menolak foto kosong dan foto yang terlalu besar', () {
      expect(() => AvatarDataUri.encode(Uint8List(0)), throwsArgumentError);
      expect(
        () => AvatarDataUri.encode(Uint8List(AvatarDataUri.maxBytes + 1)),
        throwsArgumentError,
      );
    });

    test('URL foto Google bukan data URI', () {
      const google = 'https://lh3.googleusercontent.com/a/foto';

      expect(AvatarDataUri.isDataUri(google), isFalse);
      expect(AvatarDataUri.decode(google), isNull);
    });

    test('data URI rusak tidak membuat crash', () {
      expect(AvatarDataUri.decode('data:image/jpeg;base64,@@@'), isNull);
    });
  });
}
