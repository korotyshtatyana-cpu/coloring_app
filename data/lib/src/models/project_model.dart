/// Data transfer object for a project.
class ProjectModel {
  /// Project unique identifier.
  final String id;

  /// Associated contour identifier.
  final String contourId;

  /// Owner user identifier.
  final String userId;

  /// Serialized project data.
  final Map<String, dynamic> data;

  /// Last opened timestamp.
  final DateTime lastOpened;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Creates a [ProjectModel].
  const ProjectModel({
    required this.id,
    required this.contourId,
    required this.userId,
    required this.data,
    required this.lastOpened,
    required this.createdAt,
  });

  /// Creates a [ProjectModel] from a JSON map.
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      contourId: json['contour_id'] as String,
      userId: json['user_id'] as String,
      data: json['data'] as Map<String, dynamic>,
      lastOpened: DateTime.parse(json['last_opened'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'contour_id': contourId,
      'user_id': userId,
      'data': data,
      'last_opened': lastOpened.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
