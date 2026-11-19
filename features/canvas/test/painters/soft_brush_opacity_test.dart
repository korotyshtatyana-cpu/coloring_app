import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas/src/painters/canvas_painter.dart';
import 'package:canvas/src/widgets/canvas/active_stroke.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const int _width = 400;
const int _height = 100;

/// Renders [stroke] over a white page and returns the red channel at the
/// centre of the line.
Future<int> _centerRed(StrokeEntity stroke, {required bool active}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 400, 100),
    Paint()..color = Colors.white,
  );

  if (active) {
    final ActiveStroke holder = ActiveStroke()
      ..begin(
        StrokeEntity(
          points: <StrokePoint>[stroke.points.first],
          color: stroke.color,
          size: stroke.size,
          opacity: stroke.opacity,
          brushType: stroke.brushType,
          isPressureSensitive: stroke.isPressureSensitive,
        ),
      );
    for (final StrokePoint point in stroke.points.skip(1)) {
      holder.add(point);
    }
    ActiveStrokePainter(
      stroke: holder.stroke!,
      cachedPath: holder.path,
      rawBounds: holder.rawBounds,
    ).paint(canvas, const Size(400, 100));
  } else {
    StrokeRenderer.drawStroke(
      canvas,
      stroke,
      visibleArea: const Rect.fromLTWH(0, 0, 400, 100),
    );
  }

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(_width, _height);
  final ByteData data = (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!;
  picture.dispose();
  image.dispose();

  return data.buffer.asUint8List()[(_height ~/ 2 * _width + _width ~/ 2) * 4];
}

StrokeEntity _softStroke(double opacity, BrushType type) {
  return StrokeEntity(
    points: <StrokePoint>[
      for (int i = 0; i <= 20; i++)
        StrokePoint(offset: Offset(50 + i * 15, 50), pressure: 1),
    ],
    color: 0xFF000000,
    size: 20,
    opacity: opacity,
    brushType: type,
    isPressureSensitive: type == BrushType.softLiner,
  );
}

void main() {
  group('Soft brush opacity', () {
    for (final BrushType type in <BrushType>[
      BrushType.softLiner,
      BrushType.softRoundBasic,
    ]) {
      for (final bool active in <bool>[false, true]) {
        final String painter = active ? 'active' : 'baked';

        test('$type is translucent in the $painter painter', () async {
          final int opaque = await _centerRed(
            _softStroke(1.0, type),
            active: active,
          );
          final int faint = await _centerRed(
            _softStroke(0.2, type),
            active: active,
          );
          final int half = await _centerRed(
            _softStroke(0.5, type),
            active: active,
          );

          // A gaussian soft edge never reaches the paint's full alpha at the
          // centre: with the current blur even a fully opaque soft round brush
          // peaks at ~0.77. The test still verifies that opacity is folded into
          // the paint (full opacity paints much darker than half opacity).
          expect(opaque, lessThan(70));
          // 0.2 opacity over white is ~204, 0.5 opacity is ~128.
          expect(faint, greaterThan(180));
          expect(half, inInclusiveRange(100, 160));
        });
      }
    }
  });
}
