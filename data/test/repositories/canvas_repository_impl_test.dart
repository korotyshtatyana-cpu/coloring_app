import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tests conflict resolution when opening a project that exists both locally
/// and in Supabase.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late final SupabaseClient client;
  setUpAll(() {
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    );
  });

  ProjectModel project({
    required DateTime lastOpened,
    required BrushType brushType,
  }) {
    final StrokeEntity stroke = StrokeEntity(
      points: const <StrokePoint>[
        StrokePoint(offset: Offset(10, 10), pressure: 1),
        StrokePoint(offset: Offset(50, 50), pressure: 1),
      ],
      color: 0xFF000000,
      size: 20,
      opacity: 1,
      brushType: brushType,
      isPressureSensitive: brushType == BrushType.softLiner,
    );

    return ProjectModel(
      id: 'contour_1',
      contourId: 'contour_1',
      userId: 'user_1',
      data: <String, dynamic>{
        'strokes': <Map<String, dynamic>>[
          StrokeMapper.toModel(stroke, 'contour_1').toJson(),
        ],
      },
      lastOpened: lastOpened,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('CanvasRepositoryImpl.loadProject', () {
    test('uses newer remote project and caches its strokes locally', () async {
      final AppDatabase database = AppDatabase.forTesting();
      addTearDown(database.close);

      final ProjectModel local = project(
        lastOpened: DateTime(2026, 11, 18),
        brushType: BrushType.circle,
      );
      final ProjectModel remote = project(
        lastOpened: DateTime(2026, 11, 19),
        brushType: BrushType.softLiner,
      );

      final _FakeLocalProvider localProvider = _FakeLocalProvider(
        database: database,
        project: local,
        strokes: <String, List<StrokeEntity>>{
          local.id: <StrokeEntity>[
            StrokeMapper.toEntity(
              StrokeModel.fromJson(
                (local.data['strokes'] as List<dynamic>).first
                    as Map<String, dynamic>,
              ),
            ),
          ],
        },
      );
      final _FakeRemoteProvider remoteProvider = _FakeRemoteProvider(
        client: client,
        project: remote,
      );

      final CanvasRepositoryImpl repository = CanvasRepositoryImpl(
        remoteProvider: remoteProvider,
        localProvider: localProvider,
        authRemoteProvider: _FakeAuthProvider(client: client),
      );

      final ProjectEntity? loaded = await repository.loadProject('contour_1');

      expect(loaded, isNotNull);
      expect(loaded!.lastOpened, remote.lastOpened);
      expect(
        (loaded.data['strokes'] as List<dynamic>).first['brushType'],
        BrushType.softLiner.name,
      );
      expect(localProvider.savedProject?.lastOpened, remote.lastOpened);
      expect(localProvider.savedStrokes, hasLength(1));
      expect(
        localProvider.savedStrokes!.single.brushType,
        BrushType.softLiner,
      );
    });

    test('keeps local project when it is newer than remote', () async {
      final AppDatabase database = AppDatabase.forTesting();
      addTearDown(database.close);

      final ProjectModel local = project(
        lastOpened: DateTime(2026, 11, 20),
        brushType: BrushType.circle,
      );
      final ProjectModel remote = project(
        lastOpened: DateTime(2026, 11, 19),
        brushType: BrushType.softLiner,
      );

      final _FakeLocalProvider localProvider = _FakeLocalProvider(
        database: database,
        project: local,
        strokes: <String, List<StrokeEntity>>{
          local.id: <StrokeEntity>[
            StrokeMapper.toEntity(
              StrokeModel.fromJson(
                (local.data['strokes'] as List<dynamic>).first
                    as Map<String, dynamic>,
              ),
            ),
          ],
        },
      );
      final _FakeRemoteProvider remoteProvider = _FakeRemoteProvider(
        client: client,
        project: remote,
      );

      final CanvasRepositoryImpl repository = CanvasRepositoryImpl(
        remoteProvider: remoteProvider,
        localProvider: localProvider,
        authRemoteProvider: _FakeAuthProvider(client: client),
      );

      final ProjectEntity? loaded = await repository.loadProject('contour_1');

      expect(loaded, isNotNull);
      expect(loaded!.lastOpened, local.lastOpened);
      expect(localProvider.savedProject, isNull);
      expect(remoteProvider.loadCount, 1);
    });

    test('falls back to local project when remote load fails', () async {
      final AppDatabase database = AppDatabase.forTesting();
      addTearDown(database.close);

      final ProjectModel local = project(
        lastOpened: DateTime(2026, 11, 18),
        brushType: BrushType.circle,
      );

      final _FakeLocalProvider localProvider = _FakeLocalProvider(
        database: database,
        project: local,
        strokes: <String, List<StrokeEntity>>{
          local.id: <StrokeEntity>[
            StrokeMapper.toEntity(
              StrokeModel.fromJson(
                (local.data['strokes'] as List<dynamic>).first
                    as Map<String, dynamic>,
              ),
            ),
          ],
        },
      );
      final _FakeRemoteProvider remoteProvider = _FakeRemoteProvider(
        client: client,
        error: Exception('network down'),
      );

      final CanvasRepositoryImpl repository = CanvasRepositoryImpl(
        remoteProvider: remoteProvider,
        localProvider: localProvider,
        authRemoteProvider: _FakeAuthProvider(client: client),
      );

      final ProjectEntity? loaded = await repository.loadProject('contour_1');

      expect(loaded, isNotNull);
      expect(loaded!.lastOpened, local.lastOpened);
      expect(localProvider.savedProject, isNull);
    });
  });
}

class _FakeLocalProvider extends CanvasLocalProvider {
  _FakeLocalProvider({
    required this.database,
    this.project,
    this.strokes = const <String, List<StrokeEntity>>{},
  }) : super(database: database);

  final AppDatabase database;
  final ProjectModel? project;
  final Map<String, List<StrokeEntity>> strokes;

  ProjectModel? savedProject;
  List<StrokeEntity>? savedStrokes;

  @override
  Future<ProjectModel?> loadProject(String contourId) async => project;

  @override
  Future<List<StrokeEntity>> loadStrokes(String projectId) async =>
      strokes[projectId] ?? <StrokeEntity>[];

  @override
  Future<void> saveProject(
    ProjectModel project,
    List<StrokeEntity> strokes,
  ) async {
    savedProject = project;
    savedStrokes = strokes;
  }
}

class _FakeRemoteProvider extends CanvasRemoteProvider {
  _FakeRemoteProvider({
    required this.client,
    this.project,
    this.error,
  }) : super(client: client);

  final SupabaseClient client;
  final ProjectModel? project;
  final Object? error;

  int loadCount = 0;

  @override
  Future<ProjectModel?> loadProject(String contourId) async {
    loadCount++;
    if (error != null) throw error!;
    return project;
  }
}

class _FakeAuthProvider extends AuthRemoteProvider {
  _FakeAuthProvider({required this.client}) : super.forTesting(client: client);

  final SupabaseClient client;

  @override
  String? get currentUserId => 'user_1';
}
