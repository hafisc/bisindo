import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/features/learn/domain/learn_session.dart';

void main() {
  group('LearnSession', () {
    test('berisi 10 huruf unik A-Z', () {
      final session = LearnSession(random: Random(1));

      expect(session.targets, hasLength(10));
      expect(session.targets.toSet(), hasLength(10));
      expect(
        session.targets.every((l) => RegExp(r'^[A-Z]$').hasMatch(l)),
        isTrue,
      );
    });

    test('jawaban benar menambah skor dan pindah huruf', () {
      final session = LearnSession(random: Random(1));
      final first = session.current!;

      expect(session.submit(first), LearnAnswer.correct);
      expect(session.score, 1);
      expect(session.currentIndex, 1);
    });

    test('huruf kecil dianggap sama', () {
      final session = LearnSession(random: Random(1));

      expect(session.submit(session.current!.toLowerCase()),
          LearnAnswer.correct);
    });

    test('jawaban salah tidak memajukan', () {
      final session = LearnSession(letters: ['A', 'B'], length: 2,
          random: Random(1));
      final wrong = session.current == 'A' ? 'B' : 'A';

      expect(session.submit(wrong), LearnAnswer.wrong);
      expect(session.score, 0);
      expect(session.currentIndex, 0);
    });

    test('lewati memajukan tanpa skor', () {
      final session = LearnSession(random: Random(1));

      session.skip();

      expect(session.currentIndex, 1);
      expect(session.score, 0);
    });

    test('selesai setelah semua huruf, lalu jawaban diabaikan', () {
      final session = LearnSession(length: 3, random: Random(1));

      session.submit(session.current!);
      session.skip();
      session.submit(session.current!);

      expect(session.isFinished, isTrue);
      expect(session.current, isNull);
      expect(session.score, 2);
      expect(session.submit('A'), LearnAnswer.ignored);
    });

    test('restart mengatur ulang skor dan indeks', () {
      final session = LearnSession(random: Random(1));
      session.submit(session.current!);
      session.skip();

      session.restart();

      expect(session.score, 0);
      expect(session.currentIndex, 0);
      expect(session.targets, hasLength(10));
    });
  });
}
