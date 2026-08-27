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

    await _client.from(RequestConstants.projectsTable).upsert(<String, dynamic>{
      RequestConstants.userIdColumn: user.id,
      RequestConstants.contourIdColumn: project.contourId,
      RequestConstants.dataColumn: project.data,
      RequestConstants.lastOpenedColumn: project.lastOpened.toIso8601String(),
    }, onConflict: RequestConstants.onConflictUserContour);
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
