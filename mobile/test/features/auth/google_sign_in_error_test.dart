import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/core/errors/failures.dart';
import 'package:bisindo_translator/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  group('mapGoogleSignInError', () {
    test('ApiException 10 menjelaskan masalah SHA-1', () {
      final failure = mapGoogleSignInError(PlatformException(
        code: 'sign_in_failed',
        message: 'com.google.android.gms.common.api.ApiException: 10: ',
      ));

      expect(failure.message, contains('SHA-1'));
    });

    test('network_error menjadi NetworkAuthFailure', () {
      final failure =
          mapGoogleSignInError(PlatformException(code: 'network_error'));

      expect(failure, isA<NetworkAuthFailure>());
    });

    test('ApiException 12501 dianggap dibatalkan', () {
      final failure = mapGoogleSignInError(PlatformException(
        code: 'sign_in_failed',
        message: 'ApiException: 12501: ',
      ));

      expect(failure, isA<GoogleSignInCancelledFailure>());
    });

    test('error lain memakai pesan umum', () {
      final failure =
          mapGoogleSignInError(PlatformException(code: 'unknown'));

      expect(failure.message, contains('Gagal masuk dengan Google'));
    });
  });
}
