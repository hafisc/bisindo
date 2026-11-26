import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/core/errors/failures.dart';
import 'package:bisindo_translator/features/dictionary/data/datasources/dictionary_local_data_source.dart';
import 'package:bisindo_translator/features/dictionary/data/datasources/dictionary_remote_data_source.dart';
import 'package:bisindo_translator/features/dictionary/data/repositories/dictionary_repository_impl.dart';
import 'package:bisindo_translator/features/dictionary/domain/models/dictionary_item.dart';

class _MemoryDictionaryLocal implements DictionaryLocalDataSource {
  List<DictionaryItem> items = [];
  List<DictionaryItem> seed;

  _MemoryDictionaryLocal({List<DictionaryItem>? seed})
      : seed = seed ??
            const [
              DictionaryItem(
                id: 'letter_A',
                title: 'A',
                category: DictionaryCategory.huruf,
                instructions: ['Instruksi A'],
                tips: 'Tips A',
              ),
            ];

  @override
  Future<List<DictionaryItem>> getItems({DictionaryCategory? category}) async {
    if (category == null) return List.unmodifiable(items);
    return items.where((e) => e.category == category).toList(growable: false);
  }

  @override
  Future<DictionaryItem?> getItemById(String id) async {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> saveItems(List<DictionaryItem> newItems) async {
    items = List<DictionaryItem>.from(newItems);
  }

  @override
  Future<void> upsertItem(DictionaryItem item, {int? sortOrder}) async {
    final index = items.indexWhere((e) => e.id == item.id);
    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }
  }

  @override
  Future<List<DictionaryItem>> loadBundledSeed() async => seed;
}

class _FakeDictionaryRemote implements DictionaryRemoteDataSource {
  bool online = true;
  List<String> letters = const ['A', 'B'];
  Map<String, DictionaryRemoteLetterDetail> details = const {
    'A': DictionaryRemoteLetterDetail(
      letter: 'A',
      description: 'Genggam tangan, ibu jari di samping telunjuk.',
      imageUrl: 'http://127.0.0.1:5000/static/img/dictionary/A.png',
    ),
  };

  @override
  Future<List<String>> fetchLetters() async {
    if (!online) {
      throw const DictionaryRemoteException('Server kamus tidak dapat dihubungi.');
    }
    return letters;
  }

  @override
  Future<DictionaryRemoteLetterDetail> fetchLetterDetail(String letter) async {
    if (!online) {
      throw const DictionaryRemoteException('Server kamus tidak dapat dihubungi.');
    }
    final detail = details[letter.toUpperCase()];
    if (detail == null) {
      throw const DictionaryRemoteException('Tidak ditemukan', statusCode: 404);
    }
    return detail;
  }
}

class _FakeAssetBundle extends CachingAssetBundle {
  final Map<String, String> files;
  _FakeAssetBundle(this.files);

  @override
  Future<ByteData> load(String key) async {
    final text = await loadString(key);
    return ByteData.sublistView(utf8.encode(text));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = files[key];
    if (value == null) throw FlutterError('Asset not found: $key');
    return value;
  }
}

void main() {
  group('DictionaryRepositoryImpl', () {
    late _MemoryDictionaryLocal local;
    late _FakeDictionaryRemote remote;
    late DictionaryRepositoryImpl repository;

    setUp(() {
      local = _MemoryDictionaryLocal();
      remote = _FakeDictionaryRemote();
      repository = DictionaryRepositoryImpl(local: local, remote: remote);
    });

    test('getItems melakukan seed ke cache lokal saat pertama kali kosong', () async {
      final result = await repository.getItems();

      expect(result.isRight(), isTrue);
      final items = result.getOrElse(() => []);
      expect(items, hasLength(1));
      expect(items.first.id, 'letter_A');
      expect(local.items, hasLength(1));
    });

    test('getItems memfilter kategori huruf', () async {
      final result = await repository.getItems(category: DictionaryCategory.huruf);

      final items = result.getOrElse(() => []);
      expect(items.map((e) => e.id), ['letter_A']);
    });

    test('syncFromRemote menambahkan huruf baru dari server ke cache lokal', () async {
      final result = await repository.syncFromRemote();

      final items = result.getOrElse(() => []);
      expect(items.any((e) => e.id == 'letter_B'), isTrue);
      expect(items.any((e) => e.id == 'letter_A'), isTrue);
    });

    test('syncFromRemote mengembalikan ServerFailure saat server offline', () async {
      remote.online = false;

      final result = await repository.syncFromRemote();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Harusnya gagal'),
      );
    });

    test('getItemById memperkaya deskripsi & imageUrl huruf dari API dan simpan ke cache', () async {
      final result = await repository.getItemById('letter_A');

      final item = result.getOrElse(() => null);
      expect(item, isNotNull);
      expect(item!.description, 'Genggam tangan, ibu jari di samping telunjuk.');
      expect(item.imageUrl, 'http://127.0.0.1:5000/static/img/dictionary/A.png');
      expect((await local.getItemById('letter_A'))?.description, item.description);
    });

    test('getItemById tetap mengembalikan cache lokal saat server offline', () async {
      remote.online = false;

      final result = await repository.getItemById('letter_A');

      final item = result.getOrElse(() => null);
      expect(item, isNotNull);
      expect(item!.title, 'A');
      expect(item.instructions, ['Instruksi A']);
    });
  });

  test('DictionaryLocalDataSourceImpl memuat seed 26 huruf A-Z dari bisindo_poses.json', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final local = DictionaryLocalDataSourceImpl();

    final seed = await local.loadBundledSeed();

    expect(seed, hasLength(26));
    expect(seed.every((e) => e.category == DictionaryCategory.huruf), isTrue);
    expect(seed.first.id, 'letter_A');
    expect(seed.last.id, 'letter_Z');
  });

  test('DictionaryLocalDataSourceImpl membaca aset kustom bisindo_poses.json', () async {
    final bundle = _FakeAssetBundle({
      'assets/data/bisindo_poses.json': jsonEncode({
        'letters': {
          'A': {
            'letter': 'A',
            'twoHanded': false,
            'twoHandedPercent': 0,
            'samples': 10,
            'hands': [
              List.generate(21, (i) => [0.0, 0.0]),
            ],
            'instructions': ['Pose A'],
            'tips': 'Tip A',
          },
        },
      }),
    });
    final local = DictionaryLocalDataSourceImpl(bundle: bundle);

    final seed = await local.loadBundledSeed();

    expect(seed, hasLength(1));
    expect(seed.first.id, 'letter_A');
  });
}
