import 'dart:async';

import 'package:canvas/src/bloc/canvas_bloc.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAddStrokeUseCase implements AddStrokeUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSaveProjectUseCase implements SaveProjectUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLoadProjectUseCase implements LoadProjectUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGetContourByIdUseCase implements GetContourByIdUseCase {
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

class _FakeGetAvailableToolsUseCase implements GetAvailableToolsUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGetCurrentUserUseCase implements GetCurrentUserUseCase {
  @override
  Future<UserEntity?> execute([NoParams? params]) async => null;
}

class _FakeWatchRefundsUseCase implements WatchRefundsUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWatchPurchaseUpdatesUseCase implements WatchPurchaseUpdatesUseCase {
  final Stream<PurchaseUpdateEntity> _updates;

  const _FakeWatchPurchaseUpdatesUseCase(this._updates);

  @override
  Stream<PurchaseUpdateEntity> execute([NoParams? params]) => _updates;
}

class _FakeGetGalleryItemsUseCase implements GetGalleryItemsUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  group('CanvasBloc UnlockCanvas', () {
    late CanvasBloc bloc;
    late StreamController<PurchaseUpdateEntity> purchaseUpdatesController;

    setUp(() {
      purchaseUpdatesController =
          StreamController<PurchaseUpdateEntity>.broadcast();
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
          purchaseUpdatesController.stream,
        ),
        getGalleryItemsUseCase: _FakeGetGalleryItemsUseCase(),
        logger: _FakeLogger(),
        isViewOnly: true,
      );
    });

    tearDown(() async {
      await bloc.close();
      await purchaseUpdatesController.close();
    });

    test(
      'initial state has isViewOnly true when created with isViewOnly: true',
      () {
        expect(bloc.state.isViewOnly, isTrue);
        expect(bloc.state.viewOnlyReason, null);
      },
    );

    test('UnlockCanvas switches isViewOnly from true to false', () async {
      expect(bloc.state.isViewOnly, isTrue);

      bloc.add(const UnlockCanvas());

      await expectLater(
        bloc.stream,
        emits(
          predicate<CanvasState>(
            (state) => !state.isViewOnly && state.viewOnlyReason == null,
          ),
        ),
      );
    });

    test('confirmed Premium purchase unlocks the view-only canvas', () async {
      final expectation = expectLater(
        bloc.stream,
        emits(
          predicate<CanvasState>(
            (state) => !state.isViewOnly && state.viewOnlyReason == null,
          ),
        ),
      );

      purchaseUpdatesController.add(
        const PurchaseUpdateEntity(
          status: PurchaseUpdateStatus.success,
          productId: 'premium',
        ),
      );

      await expectation;
    });

    test('confirmed No Ads purchase keeps the canvas view-only', () async {
      purchaseUpdatesController.add(
        const PurchaseUpdateEntity(
          status: PurchaseUpdateStatus.success,
          productId: 'no_ads',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isViewOnly, isTrue);
    });

    test('confirmed purchase of this contour unlocks the canvas', () async {
      final expectation = expectLater(
        bloc.stream,
        emits(predicate<CanvasState>((state) => !state.isViewOnly)),
      );

      purchaseUpdatesController.add(
        const PurchaseUpdateEntity(
          status: PurchaseUpdateStatus.success,
          productId: 'unlock_credit',
          contourId: 'contour_1',
        ),
      );

      await expectation;
    });

    test(
      'MarkCurrentContourAsViewOnly sets viewOnlyReason when starting as non-viewOnly',
      () async {
        final nonViewOnlyBloc = CanvasBloc(
          contourId: 'contour_2',
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
            purchaseUpdatesController.stream,
          ),
          getGalleryItemsUseCase: _FakeGetGalleryItemsUseCase(),
          logger: _FakeLogger(),
          isViewOnly: false,
        );

        nonViewOnlyBloc.add(
          const MarkCurrentContourAsViewOnly(reason: ViewOnlyReason.refunded),
        );

        await expectLater(
          nonViewOnlyBloc.stream,
          emits(
            predicate<CanvasState>(
              (state) =>
                  state.isViewOnly &&
                  state.viewOnlyReason == ViewOnlyReason.refunded,
            ),
          ),
        );

        nonViewOnlyBloc.add(const UnlockCanvas());

        await expectLater(
          nonViewOnlyBloc.stream,
          emits(
            predicate<CanvasState>(
              (state) => !state.isViewOnly && state.viewOnlyReason == null,
            ),
          ),
        );

        await nonViewOnlyBloc.close();
      },
    );
  });
}
