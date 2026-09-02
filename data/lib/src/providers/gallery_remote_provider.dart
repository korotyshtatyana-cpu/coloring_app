import 'package:domain/domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data.dart';

/// Remote provider for gallery operations (contours and favorites).
class GalleryRemoteProvider {
  final SupabaseClient _client;

  /// Creates a provider with the given [_client].
  GalleryRemoteProvider({required this._client});

  /// Fetches a paginated list of contours from Supabase.
  Future<List<ContourModel>> getContours({
    required int limit,
    required int offset,
    ContourCategory? category,
  }) async {
    PostgrestFilterBuilder<PostgrestList> query = _client
        .from(RequestConstants.contoursTable)
        .select(RequestConstants.selectAll);

    if (category != null) {
      query = query.eq(RequestConstants.categoryColumn, category.name);
    }

    final List<Map<String, dynamic>> response = await query
        .order(RequestConstants.createdAtColumn, ascending: false)
        .range(offset, offset + limit - 1);

    return response
        .map((Map<String, dynamic> json) => ContourModel.fromJson(json))
        .toList();
  }

  /// Fetches a paginated list of contours by their identifiers from Supabase.
  Future<List<ContourModel>> getContoursByIds({
    required List<String> ids,
    required int limit,
    required int offset,
    ContourCategory? category,
  }) async {
    if (ids.isEmpty) {
      return <ContourModel>[];
    }

    PostgrestFilterBuilder<PostgrestList> query = _client
        .from(RequestConstants.contoursTable)
        .select(RequestConstants.selectAll)
        .inFilter(RequestConstants.contourIdColumn, ids);

    if (category != null) {
      query = query.eq(RequestConstants.categoryColumn, category.name);
    }

    final List<Map<String, dynamic>> response = await query
        .order(RequestConstants.createdAtColumn, ascending: false)
        .range(offset, offset + limit - 1);

    return response
        .map((Map<String, dynamic> json) => ContourModel.fromJson(json))
        .toList();
  }

  /// Returns thumbnail URLs of the current user's projects, keyed by
  /// contour id. Projects without an uploaded thumbnail are included with
  /// a null value so they still count as "in progress".
  Future<Map<String, String?>> getWorkInProgressThumbnails() async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      return <String, String?>{};
    }

    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.projectsTable)
        .select(RequestConstants.selectProjectThumbnails)
        .eq(RequestConstants.userIdColumn, user.id);

    final Map<String, String?> result = <String, String?>{};
    for (final Map<String, dynamic> row in response) {
      result[row[RequestConstants.contourIdColumn] as String] =
          row[RequestConstants.thumbnailUrlColumn] as String?;
    }
    return result;
  }

  /// Returns favorite contour ids for the current user.
  Future<List<String>> getFavoriteIds() async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      return <String>[];
    }

    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.favoritesTable)
        .select(RequestConstants.selectContourId)
        .eq(RequestConstants.userIdColumn, user.id);

    return response
        .map(
          (Map<String, dynamic> row) =>
              row[RequestConstants.contourIdColumn] as String,
        )
        .toList();
  }

  /// Adds or removes a contour from the current user's favorites.
  Future<void> toggleFavorite(String contourId) async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw Exception(RequestConstants.userNotAuthenticated);
    }

    try {
      await _client.rpc(
        RequestConstants.toggleFavoriteRpc,
        params: {
          RequestConstants.pUserId: user.id,
          RequestConstants.pContourId: contourId,
        },
      );
    } on PostgrestException catch (e) {
      // Catch unique constraint violation (duplicate key) to handle race conditions.
      // If the record was already created/deleted by another request, we consider it success.
      if (e.code != RequestConstants.codeUniqueViolation) {
        rethrow;
      }
    }
  }
}
