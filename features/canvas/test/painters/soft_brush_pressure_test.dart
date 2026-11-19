import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas/src/painters/canvas_painter.dart';
import 'package:canvas/src/widgets/canvas/active_stroke.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const int _width = 400;
const int _height = 120;
const int _sampleX = 200;

/// Vertical profile of a rendered stroke at [_sampleX].
class _Profile {
  /// Ink density at the darkest pixel of the column, in `0..1`.
  final double peak;

  /// Number of rows at or above half of [peak].
  ///
  /// Measured relative to the peak instead of an absolute threshold so the
  /// width can be compared between strokes of different opacity.
  final int widthAtHalfPeak;

  /// Number of rows that contain any ink at all.
  final int inkWidth;

  const _Profile(this.peak, this.widthAtHalfPeak, this.inkWidth);
}

/// Renders [stroke] over a white page and returns the raw RGBA pixels.
Future<Uint8List> _render(StrokeEntity stroke, {required bool active}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 400, 120),
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
    ).paint(canvas, const Size(400, 120));
  } else {
    StrokeRenderer.drawStroke(
      canvas,
      stroke,
      visibleArea: const Rect.fromLTWH(0, 0, 400, 120),
    );
  }

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(_width, _height);
  final ByteData data = (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!;
  picture.dispose();
  image.dispose();
  return data.buffer.asUint8List();
}

/// Measures the column of [stroke] at [_sampleX].
Future<_Profile> _profile(StrokeEntity stroke, {required bool active}) async {
  final Uint8List bytes = await _render(stroke, active: active);

  // The stroke is black over a white page, so the red channel is
  // `255 * (1 - alpha)`.
  double alphaAt(int y) => 1 - bytes[(y * _width + _sampleX) * 4] / 255.0;

  double peak = 0;
  for (int y = 0; y < _height; y++) {
    final double alpha = alphaAt(y);
    if (alpha > peak) peak = alpha;
  }

  int halfPeak = 0;
  int ink = 0;
  for (int y = 0; y < _height; y++) {
    final double alpha = alphaAt(y);
    // The soft edge fades out gradually, so any faint pixel counts as ink.
    if (alpha >= peak * 0.5) halfPeak++;
    if (alpha > 0.02) ink++;
  }
  return _Profile(peak, halfPeak, ink);
}

StrokeEntity _stroke(
  double pressure,
  BrushType type, {
  double opacity = 1.0,
  double size = 24,
}) {
  return StrokeEntity(
    points: <StrokePoint>[
      for (int i = 0; i <= 20; i++)
        StrokePoint(offset: Offset(20 + i * 18.0, 60), pressure: pressure),
    ],
    color: 0xFF000000,
    size: size,
    opacity: opacity,
    brushType: type,
    isPressureSensitive: type == BrushType.softLiner,
  );
}

void main() {
  group('Soft liner pressure', () {
    for (final bool active in <bool>[false, true]) {
      final String painter = active ? 'active' : 'baked';

      test(
        'thicker pressure draws a wider line in the $painter painter',
        () async {
          final int light = (await _profile(
            _stroke(0.3, BrushType.softLiner),
            active: active,
          )).inkWidth;
          final int heavy = (await _profile(
            _stroke(1.0, BrushType.softLiner),
            active: active,
          )).inkWidth;

          expect(light, greaterThan(0));
          expect(heavy, greaterThan(light * 1.3));
        },
      );

      test(
        'pressure above 1.0 widens the line in the $painter painter',
        () async {
          // Some panels report > 1.0 for a firm finger press; hard brushes and
          // the cursor already grow there, so the soft silhouette must too.
          final _Profile normal = await _profile(
            _stroke(1.0, BrushType.softLiner, size: 40),
            active: active,
          );
          final _Profile firm = await _profile(
            _stroke(1.5, BrushType.softLiner, size: 40),
            active: active,
          );

          expect(
            firm.widthAtHalfPeak,
            greaterThan(normal.widthAtHalfPeak * 1.3),
          );
        },
      );

      test(
        'pressure reads as width at reduced opacity in the $painter painter',
        () async {
          // Regression: a blur much wider than the thin stroke smeared its ink
          // over the whole blur radius. At low opacity the light-pressure part
          // then looked like a wide faint smudge instead of a thin line, and
          // pressure appeared to stop working. Both the core width ratio and the
          // light stroke's density must stay legible.
          final _Profile light = await _profile(
            _stroke(0.1, BrushType.softLiner, opacity: 0.4, size: 40),
            active: active,
          );
          final _Profile heavy = await _profile(
            _stroke(1.0, BrushType.softLiner, opacity: 0.4, size: 40),
            active: active,
          );

          // 0.4 opacity keeps the light-pressure core at ~0.17; an over-wide
          // blur leaves it at ~0.12, i.e. nearly invisible on white.
          expect(light.peak, greaterThan(0.14));
          expect(
            heavy.widthAtHalfPeak,
            greaterThanOrEqualTo(light.widthAtHalfPeak * 3),
          );
        },
      );
    }

    test('the constant-width soft brush ignores pressure', () async {
      final int light = (await _profile(
        _stroke(0.3, BrushType.softRoundBasic),
        active: false,
      )).inkWidth;
      final int heavy = (await _profile(
        _stroke(1.0, BrushType.softRoundBasic),
        active: false,
      )).inkWidth;

      expect(light, heavy);
    });
  });
}
