import 'package:equatable/equatable.dart';

/// Domain entity representing a drawing tool (shared between brush and eraser modes).
class ToolEntity extends Equatable {
  /// Unique identifier of the tool.
  final String id;

  /// Localized key for the tool name.
  final String nameKey;

  /// Path to the preview image showing a sample stroke.
  final String previewPath;

  /// Whether the tool thickness reacts to stylus pressure.
  final bool isPressureSensitive;

  /// Creates a [ToolEntity].
  const ToolEntity({
    required this.id,
    required this.nameKey,
    required this.previewPath,
    required this.isPressureSensitive,
  });

  @override
  List<Object?> get props => [
        id,
        nameKey,
        previewPath,
        isPressureSensitive,
      ];
}
