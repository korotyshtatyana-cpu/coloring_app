import 'package:domain/domain.dart';

/// Data transfer object for a stroke.
class StrokeModel {
  /// Stroke unique identifier.
  final String id;

  /// Parent project identifier.
  final String projectId;

  /// Serialized list of points as [x, y] pairs.
  final List<List<double>> points;

  /// Stroke color as a 32-bit ARGB integer.
  final int color;

  /// Brush size.
  final double size;

  /// Stroke opacity.
  final double opacity;

  /// Brush type name.
  final BrushType brushType;

  /// Creates a [StrokeModel].
  const StrokeModel({
    required this.id,
    required this.projectId,
    required this.points,
    required this.color,
    required this.size,
    required this.opacity,
    required this.brushType,
  });

  /// Creates a [StrokeModel] from a JSON map.
  factory StrokeModel.fromJson(Map<String, dynamic> json) {
    return StrokeModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      points: (json['points'] as List<dynamic>)
          .map((dynamic row) => (row as List<dynamic>).cast<double>())
          .toList(),
      color: json['color'] as int,
      size: (json['size'] as num).toDouble(),
      opacity: (json['opacity'] as num).toDouble(),
      brushType: BrushType.values.byName(json['brushType'] as String),
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'project_id': projectId,
      'points': points,
      'color': color,
      'size': size,
      'opacity': opacity,
      'brushType': brushType.name,
    };
  }
}
