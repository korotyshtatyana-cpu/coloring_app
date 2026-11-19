import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SoftBrushPath', () {
    test('builds one continuous silhouette for a pressure stroke', () {
      const StrokeEntity stroke = StrokeEntity(
        points: <StrokePoint>[
          StrokePoint(offset: Offset(0, 0), pressure: 1),
          StrokePoint(offset: Offset(100, 0), pressure: 1),
        ],
        color: 0xFF000000,
        size: 20,
        opacity: 1,
        brushType: BrushType.softLiner,
      );

      final Path path = SoftBrushPath.build(stroke);
      final Rect bounds = path.getBounds();

      expect(bounds.left, lessThanOrEqualTo(-10));
      expect(bounds.right, greaterThanOrEqualTo(110));
      expect(path.contains(const Offset(50, 0)), isTrue);
      expect(path.contains(const Offset(50, 20)), isFalse);
    });

    test('pressure above 1.0 widens the silhouette like the hard brushes', () {
      final Path path = SoftBrushPath.build(
        const StrokeEntity(
          points: <StrokePoint>[
            StrokePoint(offset: Offset(0, 0), pressure: 1.5),
            StrokePoint(offset: Offset(100, 0), pressure: 1.5),
          ],
          color: 0xFF000000,
          size: 20,
          opacity: 1,
          brushType: BrushType.softLiner,
          isPressureSensitive: true,
        ),
      );
      final Rect bounds = path.getBounds();

      // Some panels report > 1.0 for a firm finger press: size 20 at pressure
      // 1.5 is 30 wide, so the tip reaches 15 units from the centre line.
      expect(bounds.top, lessThanOrEqualTo(-15));
      expect(bounds.bottom, greaterThanOrEqualTo(15));
      expect(path.contains(const Offset(0, 14)), isTrue);
    });

    test('start and addSegment extend the same incremental path', () {
      const StrokePoint first = StrokePoint(offset: Offset(0, 0), pressure: 1);
      const StrokePoint second = StrokePoint(
        offset: Offset(50, 0),
        pressure: 1,
      );

      final Path incremental = SoftBrushPath.start(first, 10);
      SoftBrushPath.addSegment(incremental, first, second, 10);
      SoftBrushPath.addTip(incremental, second, 10);

      final Path built = SoftBrushPath.build(
        const StrokeEntity(
          points: <StrokePoint>[first, second],
          color: 0xFF000000,
          size: 10,
          opacity: 1,
          brushType: BrushType.softLiner,
        ),
      );

      expect(incremental.getBounds(), built.getBounds());
    });
  });
}
