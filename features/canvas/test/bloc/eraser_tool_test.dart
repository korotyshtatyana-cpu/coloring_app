import 'dart:async';

import 'package:canvas/src/bloc/canvas_bloc.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<ToolEntity> _tools = <ToolEntity>[
  ToolEntity(
    id: 'round_basic',
    nameKey: 'brush_round_basic',
    previewPath: '',
    isPressureSensitive: false,
  ),
  ToolEntity(
    id: 'fine_liner',
    nameKey: 'brush_fine_liner',
    previewPath: '',
    isPressureSensitive: true,
  ),
  ToolEntity(
    id: 'soft_round_basic',
    nameKey: 'brush_soft_round_basic',
    previewPath: '',
    isPressureSensitive: false,
    brushType: BrushType.softRoundBasic,
  ),
  ToolEntity(
    id: 'soft_liner',
    nameKey: 'brush_soft_liner',
    previewPath: '',
    isPressureSensitive: true,
    brushType: BrushType.softLiner,
  ),
];

class _FakeAddStrokeUseCase implements AddStrokeUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeExportImageUseCase implements ExportImageUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShareFileUseCase implements ShareFileUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSaveImageToGalleryUseCase implements SaveImageToGalleryUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRenderProjectThumbnailUseCase
    implements RenderProjectThumbnailUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWatchRefundsUseCase implements WatchRefundsUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGetGalleryItemsUseCase implements GetGalleryItemsUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSaveProjectUseCase implements SaveProjectUseCase {
  @override
  Future<void> execute([ProjectEntity? params]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLoadProjectUseCase implements LoadProjectUseCase {
  @override
  Future<ProjectEntity?> execute([String? params]) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGetContourByIdUseCase implements GetContourByIdUseCase {
  @override
  Future<ContourEntity?> execute([String? params]) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGetAvailableToolsUseCase implements GetAvailableToolsUseCase {
  @override
  Future<List<ToolEntity>> execute([NoParams? params]) async => _tools;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGetCurrentUserUseCase implements GetCurrentUserUseCase {
  @override
  Future<UserEntity?> execute([NoParams? params]) async => null;
}

class _FakeWatchPurchaseUpdatesUseCase implements WatchPurchaseUpdatesUseCase {
  final Stream<PurchaseUpdateEntity> _updates;

  const _FakeWatchPurchaseUpdatesUseCase(this._updates);

  @override
  Stream<PurchaseUpdateEntity> execute([NoParams? params]) => _updates;
}

class _FakeLogger implements AppLogger {
  @override
  void debug(dynamic message, [Object? error, StackTrace? stackTrace]) {}
  @override
  void error(dynamic message, [Object? error, StackTrace? stackTrace]) {}
  @override
  void info(dynamic message, [Object? error, StackTrace? stackTrace]) {}
  @override
  void warning(dynamic message, [Object? error, StackTrace? stackTrace]) {}
  @override
  void verbose(dynamic message, [Object? error, StackTrace? stackTrace]) {}
  @override
  void wtf(dynamic message, [Object? error, StackTrace? stackTrace]) {}
  @override
  void setCrashReporter(CrashReporter? crashReporter) {}
}

void main() {
  group('Eraser tools', () {
    late CanvasBloc bloc;
    late StreamController<PurchaseUpdateEntity> purchaseUpdates;

    setUp(() async {
      purchaseUpdates = StreamController<PurchaseUpdateEntity>.broadcast();
      bloc = CanvasBloc(
        contourId: 'contour_1',
        addStrokeUseCase: _FakeAddStrokeUseCase(),
        saveProjectUseCase: _FakeSaveProjectUseCase(),
        loadProjectUseCase: _FakeLoadProjectUseCase(),
        getContourByIdUseCase: _FakeGetContourByIdUseCase(),
        exportImageUseCase: _FakeExportImageUseCase(),
        shareFileUseCase: _FakeShareFileUseCase(),
        saveImageToGalleryUseCase: _FakeSaveImageToGalleryUseCase(),
        renderProjectThumbnailUseCase: _FakeRenderProjectThumbnailUseCase(),
        getAvailableToolsUseCase: _FakeGetAvailableToolsUseCase(),
        getCurrentUserUseCase: _FakeGetCurrentUserUseCase(),
        watchRefundsUseCase: _FakeWatchRefundsUseCase(),
        watchPurchaseUpdatesUseCase: _FakeWatchPurchaseUpdatesUseCase(
          purchaseUpdates.stream,
        ),
        getGalleryItemsUseCase: _FakeGetGalleryItemsUseCase(),
        logger: _FakeLogger(),
      );

      bloc.add(const LoadProject());
      await bloc.stream.firstWhere(
        (CanvasState state) => state.availableTools.isNotEmpty,
      );
    });

    tearDown(() async {
      await bloc.close();
      await purchaseUpdates.close();
    });

    test('the eraser menu receives every brush, including soft ones', () {
      final List<BrushType> types = bloc.state.availableTools
          .map((ToolEntity tool) => tool.brushType)
          .toList();

      expect(types, contains(BrushType.softRoundBasic));
      expect(types, contains(BrushType.softLiner));
    });

    test('a soft eraser keeps its soft brush type and the eraser color',
        () async {
      bloc.add(const SelectEraser('soft_round_basic'));
      await bloc.stream.firstWhere((CanvasState state) => state.isEraser);

      bloc.add(const StartDrawing(point: Offset(10, 20), pressure: 0.5));
      final CanvasState state = await bloc.stream.firstWhere(
        (CanvasState state) => state.currentStroke != null,
      );
      final StrokeEntity stroke = state.currentStroke!;

      expect(stroke.brushType, BrushType.softRoundBasic);
      expect(stroke.isPressureSensitive, isFalse);
      expect(stroke.color, Colors.white.toARGB32());
    });

    test('a pressure eraser keeps the base size and applies pressure once',
        () async {
      bloc.add(const SelectEraser('soft_liner'));
      await bloc.stream.firstWhere((CanvasState state) => state.isEraser);

      bloc.add(const StartDrawing(point: Offset(10, 20), pressure: 0.25));
      final CanvasState state = await bloc.stream.firstWhere(
        (CanvasState state) => state.currentStroke != null,
      );
      final StrokeEntity stroke = state.currentStroke!;

      expect(stroke.brushType, BrushType.softLiner);
      expect(stroke.isPressureSensitive, isTrue);
      // The renderer scales the width by pressure; pre-scaling the size here
      // would apply pressure twice.
      expect(stroke.size, state.brushSize);
      expect(stroke.points.single.pressure, 0.25);
    });
  });
}
