import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrushSoftness', () {
    test('scales sigma proportionally to the brush size', () {
      expect(BrushSoftness.sigmaFor(10), 4.2);
      expect(BrushSoftness.sigmaFor(40), 16.8);
    });

    test('clamps tiny and huge brushes', () {
      expect(BrushSoftness.sigmaFor(1), BrushSoftness.minSigma);
      expect(BrushSoftness.sigmaFor(100), BrushSoftness.maxSigma);
    });

    test('pressure-sensitive sigma follows the current stroke width', () {
      expect(
        BrushSoftness.sigmaFor(40, pressureSensitive: true),
        lessThan(BrushSoftness.sigmaFor(40)),
      );
      // 0.25 of the pressure-scaled width: firm strokes are much softer than
      // with the old fixed 0.11 of nominal size, light ones stay sharp.
      expect(BrushSoftness.sigmaFor(40, pressureSensitive: true), 10);
      expect(
        BrushSoftness.sigmaFor(40, pressureSensitive: true, pressure: 0.1),
        1,
      );
      expect(
        BrushSoftness.sigmaFor(40, pressureSensitive: true, pressure: 1.5),
        15,
      );
      // The floor still protects thin pressure strokes.
      expect(
        BrushSoftness.sigmaFor(1, pressureSensitive: true),
        BrushSoftness.minSigma,
      );
    });

    test('constant-width sigma ignores pressure', () {
      expect(BrushSoftness.sigmaFor(40, pressure: 0.1), 16.8);
      expect(BrushSoftness.sigmaFor(40, pressure: 1.5), 16.8);
    });

    test('effectivePressure is the mean of saved pressure-sensitive points', () {
      const StrokeEntity stroke = StrokeEntity(
        points: <StrokePoint>[
          StrokePoint(offset: Offset.zero, pressure: 0.2),
          StrokePoint(offset: Offset(1, 0), pressure: 0.6),
          StrokePoint(offset: Offset(2, 0), pressure: 1.0),
        ],
        color: 0,
        size: 40,
        opacity: 1,
        brushType: BrushType.softLiner,
        isPressureSensitive: true,
      );
      expect(BrushSoftness.effectivePressure(stroke), closeTo(0.6, 1e-12));

      final StrokeEntity constant = StrokeEntity(
        points: stroke.points,
        color: 0,
        size: 40,
        opacity: 1,
        brushType: BrushType.softRoundBasic,
        isPressureSensitive: false,
      );
      expect(BrushSoftness.effectivePressure(constant), 1.0);
    });

    test('reserves three sigmas of bleed in stroke bounds', () {
      expect(
        BrushSoftness.marginFor(40),
        BrushSoftness.sigmaFor(40) * BrushSoftness.marginInSigmas,
      );
      expect(
        BrushSoftness.marginFor(40, pressureSensitive: true),
        BrushSoftness.sigmaFor(40, pressureSensitive: true) *
            BrushSoftness.marginInSigmas,
      );
    });
  });

  group('BrushType.isSoft', () {
    test('marks only the two soft variants as soft', () {
      expect(BrushType.softLiner.isSoft, isTrue);
      expect(BrushType.softRoundBasic.isSoft, isTrue);
      expect(BrushType.circle.isSoft, isFalse);
      expect(BrushType.watercolor.isSoft, isFalse);
      expect(BrushType.airbrush.isSoft, isFalse);
    });
  });
}
