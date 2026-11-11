import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/features/profile/data/models/user_profile_model.dart';
import 'package:bisindo_translator/features/profile/domain/models/user_profile.dart';

void main() {
  group('UserProfileModel.fromFirestore', () {
    test('membaca seluruh field dari dokumen Firestore', () {
      final joinedAt = DateTime(2026, 3, 12);
      final model = UserProfileModel.fromFirestore('uid-1', {
        'name': 'Rizki',
        'email': 'rizki@example.com',
        'studentId': '2210512001',
        'role': 'Mahasiswa',
        'avatarUrl': 'https://example.com/a.png',
        'joinedAt': Timestamp.fromDate(joinedAt),
      });

      expect(model.id, 'uid-1');
      expect(model.name, 'Rizki');
      expect(model.email, 'rizki@example.com');
      expect(model.studentId, '2210512001');
      expect(model.role, 'Mahasiswa');
      expect(model.avatarUrl, 'https://example.com/a.png');
      expect(model.joinedAt, joinedAt);
    });

    test('mengisi default ketika dokumen hanya punya sebagian field', () {
      final model = UserProfileModel.fromFirestore('uid-2', {
        'name': '  ',
        'email': 'b@example.com',
      });

      expect(model.name, '');
      expect(model.studentId, '');
      expect(model.role, '');
      expect(model.avatarUrl, isNull);
      expect(model.joinedAt, isNull);
    });
  });

  group('UserProfileModel.toFirestore', () {
    test('menyertakan joinedAt dan updatedAt', () {
      final map = UserProfileModel(
        id: 'uid-3',
        name: 'Aldyth',
        email: 'aldyth@example.com',
        studentId: '2210512002',
        role: 'Mahasiswa',
        joinedAt: DateTime(2026, 1, 2),
      ).toFirestore();

      expect(map['name'], 'Aldyth');
      expect(map['studentId'], '2210512002');
      expect(map['role'], 'Mahasiswa');
      expect(map['joinedAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<FieldValue>());
    });

    test('tidak menulis joinedAt bila null', () {
      final map = UserProfileModel(
        id: 'uid-4',
        name: 'Nanta',
        email: 'nanta@example.com',
      ).toFirestore();

      expect(map.containsKey('joinedAt'), isFalse);
    });
  });

  group('UserProfile', () {
    test('displayName tidak pernah kosong', () {
      const profile = UserProfile(
        id: 'uid-5',
        name: '   ',
        email: 'x@example.com',
        studentId: '',
        role: '',
      );

      expect(profile.displayName, 'Pengguna');
      expect(profile.displayStudentId, 'Belum diisi');
      expect(profile.displayRole, 'Pengguna BISINDO');
    });

    test('copyWith hanya mengubah field yang diberikan', () {
      const original = UserProfile(
        id: 'uid-6',
        name: 'Lama',
        email: 'x@example.com',
        studentId: '1',
        role: 'Umum',
      );

      final updated = original.copyWith(name: 'Baru');

      expect(updated.name, 'Baru');
      expect(updated.email, original.email);
      expect(updated.studentId, original.studentId);
      expect(updated.role, original.role);
    });
  });
}
