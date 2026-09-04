import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'brush_type.dart';

/// A single point in a [StrokeEntity] with its pressure information.
class StrokePoint extends Equatable {
  /// The coordinates of the point in scene space.
  final Offset offset;

  /// The pressure value for this point, ranging from 0.0 to 1.0.
  final double pressure;

  /// Creates a [StrokePoint].
  const StrokePoint({
    required this.offset,
    required this.pressure,
  });

  @override
  List<Object?> get props => <Object?>[offset, pressure];
}

/// Domain entity representing a single drawing stroke.
class StrokeEntity extends Equatable {
  /// List of points that make up the stroke.
  final List<StrokePoint> points;

  /// Stroke color as a 32-bit ARGB value.
  final int color;

  /// Base brush size in logical pixels.
  final double size;

  /// Stroke opacity in the range [0.0, 1.0].
  final double opacity;

  /// Brush type used for this stroke.
  final BrushType brushType;

  /// Creates a [StrokeEntity].
  const StrokeEntity({
    required this.points,
    required this.color,
    required this.size,
    required this.opacity,
    required this.brushType,
  });

  /// Creates a copy with optional new values.
  StrokeEntity copyWith({
    List<StrokePoint>? points,
    int? color,
    double? size,
    double? opacity,
    BrushType? brushType,
  }) {
    return StrokeEntity(
      points: points ?? this.points,
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      brushType: brushType ?? this.brushType,
    );
  }

  @override
  List<Object?> get props => <Object?>[points, color, size, opacity, brushType];
}
