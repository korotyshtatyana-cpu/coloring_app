import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data.dart';

/// Remote provider for saving and loading projects from Supabase.
class CanvasRemoteProvider {
  final SupabaseClient _client;

  /// Creates a provider with the given [_client].
  CanvasRemoteProvider({required this._client});

  /// Saves the project to Supabase using upsert semantics.
  Future<void> saveProject(ProjectModel project) async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw Exception(RequestConstants.userNotAuthenticated);
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      RequestConstants.userIdColumn: user.id,
      RequestConstants.contourIdColumn: project.contourId,
      RequestConstants.dataColumn: project.data,
      RequestConstants.lastOpenedColumn: project.lastOpened.toIso8601String(),
    };

    // Mirror the thumbnail into its own column so the gallery can list
    // per-user thumbnails with a cheap query. Only sync remote URLs — a
    // device-local file path is useless on other devices.
    final String? thumbnailPath = project.data['thumbnailPath'] as String?;
    if (thumbnailPath != null && thumbnailPath.startsWith('http')) {
      payload[RequestConstants.thumbnailUrlColumn] = thumbnailPath;
    }

    await _client
        .from(RequestConstants.projectsTable)
        .upsert(payload, onConflict: RequestConstants.onConflictUserContour);
  }

  /// Uploads a project thumbnail to Supabase Storage and returns its public
  /// URL. The object path is `user_id/contour_id.png` in the
  /// `project_thumbnails` bucket, so each user has their own copy.
  Future<String> uploadThumbnail({
    required String contourId,
    required Uint8List pngBytes,
  }) async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw Exception(RequestConstants.userNotAuthenticated);
    }

    final String path =
        '${user.id}/$contourId${RequestConstants.thumbnailFileExtension}';

    await _client.storage
        .from(RequestConstants.thumbnailsBucket)
        .uploadBinary(
          path,
          pngBytes,
          fileOptions: const FileOptions(
            contentType: RequestConstants.pngMimeType,
            upsert: true,
          ),
        );

    final String publicUrl = _client.storage
        .from(RequestConstants.thumbnailsBucket)
        .getPublicUrl(path);

    // The object is overwritten on every save, so its URL never changes.
    // A version query busts both the Flutter image cache and the CDN cache,
    // otherwise the gallery would keep showing the previous thumbnail.
    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Loads the project for the given contour.
  Future<ProjectModel?> loadProject(String contourId) async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.projectsTable)
        .select(RequestConstants.selectProjectData)
        .eq(RequestConstants.userIdColumn, user.id)
        .eq(RequestConstants.contourIdColumn, contourId)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }

    return ProjectModel(
      // Use the local id convention (contour id) so caching this project
      // locally doesn't create a duplicate row for the same contour.
      id: contourId,
      contourId: contourId,
      userId: user.id,
      data: response.first[RequestConstants.dataColumn] as Map<String, dynamic>,
      lastOpened: DateTime.parse(
          response.first[RequestConstants.lastOpenedColumn] as String),
      createdAt: DateTime.now(),
    );
  }
}
