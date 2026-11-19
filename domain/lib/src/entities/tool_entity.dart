import 'package:equatable/equatable.dart';

import 'brush_type.dart';

/// Domain entity representing a drawing tool (shared between brush and eraser modes).
class ToolEntity extends Equatable {
  /// Unique identifier of the tool.
  final String id;

  /// Localized key for the tool name.
  final String nameKey;

  /// Path to the preview image showing a sample stroke.
  final String previewPath;

  /// Whether the tool thickness reacts to stylus pressure.
  ///
  /// For built-in brushes this is the canonical value from `ToolMapper`, not
  /// the value cached in the database: pressure support is a rendering
  /// behavior, so a stale cache row must not change it.
  final bool isPressureSensitive;

  /// Brush type used by the rendering layer for strokes made with this tool.
  final BrushType brushType;

  /// Creates a [ToolEntity].
  const ToolEntity({
    required this.id,
    required this.nameKey,
    required this.previewPath,
    required this.isPressureSensitive,
    this.brushType = BrushType.circle,
  });

  @override
  List<Object?> get props => [
    id,
    nameKey,
    previewPath,
    isPressureSensitive,
    brushType,
  ];
}
