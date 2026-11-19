import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas/src/widgets/canvas/brush_cursor_controller.dart';
import 'package:canvas/src/widgets/canvas/brush_cursor_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const int _width = 100;
const int _height = 100;

/// Renders [cursor] with [BrushCursorPainter] into raw RGBA pixels.
Future<Uint8List> _paint(BrushCursorController cursor) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  BrushCursorPainter(
    cursor: cursor,
  ).paint(canvas, Size(_width.toDouble(), _height.toDouble()));

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(_width, _height);
  final ByteData data = (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!;
  picture.dispose();
  image.dispose();
  return data.buffer.asUint8List();
}

int _alphaAt(Uint8List bytes, int x, int y) {
  return bytes[(y * _width + x) * 4 + 3];
}

void main() {
  group('BrushCursorController', () {
    test('starts hidden', () {
      final BrushCursorController cursor = BrushCursorController();

      expect(cursor.isVisible, isFalse);
      expect(cursor.position, isNull);
    });

    test('show publishes the position, diameter and scene scale', () {
      final BrushCursorController cursor = BrushCursorController();
      int notifications = 0;
      cursor.addListener(() => notifications++);

      cursor.show(
        position: const Offset(12, 34),
        brushSize: 40,
        pressureSensitive: false,
        sceneScale: 2,
      );

      expect(cursor.isVisible, isTrue);
      expect(cursor.position, const Offset(12, 34));
      expect(cursor.diameter, 40);
      expect(cursor.sceneScale, 2);
      expect(notifications, 1);
    });

    test('a pressure-sensitive brush starts at the full brush size', () {
      final BrushCursorController cursor = BrushCursorController()
        ..show(
          position: const Offset(10, 10),
          brushSize: 40,
          pressureSensitive: true,
          sceneScale: 1,
        );

      expect(cursor.diameter, 40);
    });

    test('a pressure-sensitive brush shrinks with the pressure', () {
      final BrushCursorController cursor = BrushCursorController()
        ..show(
          position: const Offset(10, 10),
          brushSize: 40,
          pressureSensitive: true,
          sceneScale: 1,
          pressure: 0.25,
        );

      // The stroke width is `stroke.size * pressure`, so the ring must match.
      expect(cursor.diameter, 10);
    });

    test('a pressure-sensitive brush grows past the brush size above 1.0', () {
      final BrushCursorController cursor = BrushCursorController()
        ..show(
          position: const Offset(10, 10),
          brushSize: 40,
          pressureSensitive: true,
          sceneScale: 1,
          pressure: 1.5,
        );

      // Some panels report > 1.0 for a firm finger press; the line is wider
      // than `brushSize` then, so the ring must grow with it.
      expect(cursor.diameter, 60);
    });

    test('a constant-width brush ignores the pressure', () {
      final BrushCursorController cursor = BrushCursorController()
        ..show(
          position: const Offset(10, 10),
          brushSize: 40,
          pressureSensitive: false,
          sceneScale: 1,
          pressure: 0.25,
        );

      expect(cursor.diameter, 40);
    });

    test('move follows the pointer only while the cursor is visible', () {
      final BrushCursorController cursor = BrushCursorController();
      int notifications = 0;
      cursor.addListener(() => notifications++);

      // A stray move event must not bring a hidden cursor back.
      cursor.move(const Offset(1, 1));
      expect(cursor.isVisible, isFalse);
      expect(notifications, 0);

      cursor.show(
        position: const Offset(10, 10),
        brushSize: 20,
        pressureSensitive: false,
        sceneScale: 1,
      );
      cursor.move(const Offset(15, 15));

      expect(cursor.position, const Offset(15, 15));
      expect(notifications, 2);
    });

    test('move resizes the ring when only the pressure changes', () {
      final BrushCursorController cursor = BrushCursorController()
        ..show(
          position: const Offset(10, 10),
          brushSize: 40,
          pressureSensitive: true,
          sceneScale: 1,
        );
      int notifications = 0;
      cursor.addListener(() => notifications++);

      cursor.move(const Offset(10, 10), pressure: 0.5);

      expect(cursor.diameter, 20);
      expect(notifications, 1);
    });

    test('move ignores an unchanged position and pressure', () {
      final BrushCursorController cursor = BrushCursorController()
        ..show(
          position: const Offset(10, 10),
          brushSize: 40,
          pressureSensitive: true,
          sceneScale: 1,
        );
      int notifications = 0;
      cursor.addListener(() => notifications++);

      cursor.move(const Offset(10, 10));

      expect(notifications, 0);
    });

    test('hide clears the position and notifies only once', () {
      final BrushCursorController cursor = BrushCursorController()
        ..show(
          position: const Offset(10, 10),
          brushSize: 20,
          pressureSensitive: false,
          sceneScale: 1,
        );
      int notifications = 0;
      cursor.addListener(() => notifications++);

      cursor.hide();
      cursor.hide();

      expect(cursor.isVisible, isFalse);
      expect(notifications, 1);
    });

    test('falls back to safe values for non-positive input', () {
      final BrushCursorController cursor = BrushCursorController()
        ..show(
          position: Offset.zero,
          brushSize: 0,
          pressureSensitive: false,
          sceneScale: 0,
        );

      expect(cursor.diameter, 1);
      expect(cursor.sceneScale, 1);
    });

    test('never paints a ring thinner than one canvas unit', () {
      final BrushCursorController cursor = BrushCursorController()
        ..show(
          position: Offset.zero,
          brushSize: 40,
          pressureSensitive: true,
          sceneScale: 1,
          pressure: 0,
        );

      expect(cursor.diameter, 1);
    });
  });

  group('BrushCursorPainter', () {
    test('draws an empty ring around the brush centre', () async {
      final BrushCursorController cursor = BrushCursorController()
        ..show(
          position: const Offset(50, 50),
          brushSize: 40,
          pressureSensitive: false,
          sceneScale: 1,
        );

      final Uint8List bytes = await _paint(cursor);

      // The ring edge is painted where the brush would draw, the inside stays
      // transparent so the artwork remains visible.
      expect(_alphaAt(bytes, 70, 50), greaterThan(200));
      expect(_alphaAt(bytes, 50, 50), 0);
      expect(_alphaAt(bytes, 50, 75), 0);
    });

    test('draws a smaller ring for a lower pressure', () async {
      final BrushCursorController cursor = BrushCursorController()
        ..show(
          position: const Offset(50, 50),
          brushSize: 40,
          pressureSensitive: true,
          sceneScale: 1,
          pressure: 0.5,
        );

      final Uint8List bytes = await _paint(cursor);

      // Diameter 20: the edge sits 10 px from the centre instead of 20.
      expect(_alphaAt(bytes, 60, 50), greaterThan(200));
      expect(_alphaAt(bytes, 70, 50), 0);
    });

    test('paints nothing while hidden', () async {
      final BrushCursorController cursor = BrushCursorController();

      final Uint8List bytes = await _paint(cursor);

      final List<int> alphas = <int>[
        for (int i = 3; i < bytes.length; i += 4) bytes[i],
      ];
      expect(alphas.every((int alpha) => alpha == 0), isTrue);
    });

    test('repaints only for a different cursor controller', () {
      final BrushCursorController cursor = BrushCursorController();
      final BrushCursorPainter painter = BrushCursorPainter(cursor: cursor);

      expect(
        painter.shouldRepaint(BrushCursorPainter(cursor: cursor)),
        isFalse,
      );
      expect(
        painter.shouldRepaint(
          BrushCursorPainter(cursor: BrushCursorController()),
        ),
        isTrue,
      );
    });
  });
}
