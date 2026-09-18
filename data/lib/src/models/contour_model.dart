import 'package:domain/domain.dart';

/// Data transfer object for a contour.
class ContourModel {
  /// Contour unique identifier.
  final String id;

  /// Contour title.
  final String title;

  /// Contour category.
  final ContourCategory category;

  /// URL to the SVG file describing the contour.
  final String svgUrl;

  /// Preview image URL.
  final String previewUrl;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Creates a [ContourModel].
  const ContourModel({
    required this.id,
    required this.title,
    required this.category,
    required this.svgUrl,
    required this.previewUrl,
    this.createdAt,
  });

  /// Creates a [ContourModel] from a JSON map.
  factory ContourModel.fromJson(Map<String, dynamic> json) {
    return ContourModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: ContourCategory.values.byName(json['category'] as String),
      svgUrl: json['svg_data'] as String,
      previewUrl: json['preview_url'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'category': category.name,
      'svg_data': svgUrl,
      'preview_url': previewUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
