import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/features/auth/data/models/user_model.dart';
import 'package:bisindo_translator/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserModel', () {
    test('menyimpan hasPassword pada serialisasi JSON', () {
      const model = UserModel(
        id: 'uid-1',
        email: 'rizki@example.com',
        displayName: 'Rizki',
        hasPassword: true,
      );

      final json = model.toJson();

      expect(json['hasPassword'], isTrue);
      expect(UserModel.fromJson(json).hasPassword, isTrue);
    });

    test('hasPassword default false bila tidak ada di JSON', () {
      final model = UserModel.fromJson({
        'id': 'uid-2',
        'email': 'google@example.com',
        'displayName': 'Google User',
        'isGoogleUser': true,
      });

      expect(model.hasPassword, isFalse);
      expect(model.isGoogleUser, isTrue);
    });
  });

  group('UserEntity', () {
    test('hasPassword ikut berubah lewat copyWith', () {
      const user = UserEntity(
        id: 'uid-3',
        email: 'a@example.com',
        displayName: 'A',
      );

      expect(user.hasPassword, isFalse);
      expect(user.copyWith(hasPassword: true).hasPassword, isTrue);
    });

    test('empty bukan pengguna dengan password', () {
      expect(UserEntity.empty.hasPassword, isFalse);
    });
  });
}
