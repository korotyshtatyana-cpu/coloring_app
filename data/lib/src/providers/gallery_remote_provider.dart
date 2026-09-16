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

  /// Fetches contours by their identifiers from Supabase.
  ///
  /// The result is not ordered and not paginated: the repository sorts the
  /// contours by the given [ids] order and paginates afterwards, so lists
  /// like "work in progress" keep their intended order.
  Future<List<ContourModel>> getContoursByIds({
    required List<String> ids,
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

    final List<Map<String, dynamic>> response = await query;

    return response
        .map((Map<String, dynamic> json) => ContourModel.fromJson(json))
        .toList();
  }

  /// Returns the current user's started (work in progress) projects ordered
  /// by the date of the last change, most recent first. Projects without an
  /// uploaded thumbnail are included with a null thumbnail.
  Future<List<WorkInProgressEntity>> getWorkInProgress() async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      return <WorkInProgressEntity>[];
    }

    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.projectsTable)
        .select(RequestConstants.selectProjectThumbnails)
        .eq(RequestConstants.userIdColumn, user.id)
        .order(RequestConstants.lastOpenedColumn, ascending: false);

    return response
        .map(
          (Map<String, dynamic> row) => WorkInProgressEntity(
            contourId: row[RequestConstants.contourIdColumn] as String,
            thumbnailPath: row[RequestConstants.thumbnailUrlColumn] as String?,
            lastOpened: DateTime.parse(
              row[RequestConstants.lastOpenedColumn] as String,
            ),
          ),
        )
        .toList();
  }

  /// Returns favorite contour ids for the current user, most recently
  /// favorited first.
  Future<List<String>> getFavoriteIds() async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      return <String>[];
    }

    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.favoritesTable)
        .select(RequestConstants.selectContourId)
        .eq(RequestConstants.userIdColumn, user.id)
        .order(RequestConstants.createdAtColumn, ascending: false);

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
