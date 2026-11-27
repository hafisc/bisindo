import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/core/config/auth_config.dart';

void main() {
  group('AuthConfig.resolveServerClientId', () {
    test('mengembalikan null untuk null atau string kosong', () {
      expect(AuthConfig.resolveServerClientId(null), isNull);
      expect(AuthConfig.resolveServerClientId(''), isNull);
      expect(AuthConfig.resolveServerClientId('   '), isNull);
    });

    test('melakukan trim pada Web Client ID yang valid', () {
      expect(
        AuthConfig.resolveServerClientId('  12345-abc.apps.googleusercontent.com  '),
        '12345-abc.apps.googleusercontent.com',
      );
    });
  });

  group('AuthConfig.googleServerClientId', () {
    test('bernilai null secara default bila --dart-define tidak diberikan', () {
      expect(AuthConfig.googleServerClientId, isNull);
    });
  });
}
