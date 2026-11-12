import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingGalleryRepository implements GalleryRepository {
  ContourCategory? category;
  ContourAccessType? accessType;
  DateTime? createdAfter;
  int calls = 0;

  @override
  Future<List<ContourEntity>> getContours({
    required int limit,
    required int offset,
    ContourCategory? category,
    ContourAccessType? accessType,
    DateTime? createdAfter,
  }) async {
    calls++;
    this.category = category;
    this.accessType = accessType;
    this.createdAfter = createdAfter;
    return const <ContourEntity>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('GetContoursUseCase', () {
    late _RecordingGalleryRepository repository;
    late GetContoursUseCase useCase;

    setUp(() {
      repository = _RecordingGalleryRepository();
      useCase = GetContoursUseCase(repository: repository);
    });

    test('passes the free access type through to the repository', () async {
      await useCase.execute(
        const GetContoursParams(
          limit: 20,
          offset: 0,
          accessType: ContourAccessType.free,
        ),
      );

      expect(repository.accessType, ContourAccessType.free);
      expect(repository.createdAfter, isNull);
    });

    test('turns onlyNew into a created_at filter for the last month', () async {
      final DateTime before = DateTime.now().toUtc();
      await useCase.execute(
        const GetContoursParams(limit: 20, offset: 0, onlyNew: true),
      );
      final DateTime after = DateTime.now().toUtc();

      final DateTime createdAfter = repository.createdAfter!;
      expect(
        createdAfter.isBefore(
          before.subtract(GetContoursUseCase.newContoursPeriod),
        ),
        isFalse,
      );
      expect(
        createdAfter.isAfter(
          after.subtract(GetContoursUseCase.newContoursPeriod),
        ),
        isFalse,
      );
    });

    test('clears the UI-only all category', () async {
      await useCase.execute(
        const GetContoursParams(
          limit: 20,
          offset: 0,
          category: ContourCategory.all,
        ),
      );

      expect(repository.category, isNull);
    });
  });
}
