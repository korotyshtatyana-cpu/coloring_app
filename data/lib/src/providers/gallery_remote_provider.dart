import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data.dart';

/// Remote provider for gallery operations (contours and favorites).
class GalleryRemoteProvider {
  final SupabaseClient _client;

  /// Creates a provider with the given [client].
  GalleryRemoteProvider({required SupabaseClient client}) : _client = client;

  /// Fetches a paginated list of contours from Supabase.
  Future<List<ContourModel>> getContours({
    required int limit,
    required int offset,
    String? category,
  }) async {
    PostgrestFilterBuilder<PostgrestList> query = _client
        .from(RequestConstants.contoursTable)
        .select(RequestConstants.selectAll);

    if (category != null && category.isNotEmpty) {
      query = query.eq(RequestConstants.categoryColumn, category);
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
  }) async {
    if (ids.isEmpty) {
      return <ContourModel>[];
    }

    final List<Map<String, dynamic>> response = await _client
        .from(RequestConstants.contoursTable)
        .select(RequestConstants.selectAll)
        .inFilter(RequestConstants.contourIdColumn, ids)
        .order(RequestConstants.createdAtColumn, ascending: false)
        .range(offset, offset + limit - 1);

    return response
        .map((Map<String, dynamic> json) => ContourModel.fromJson(json))
        .toList();
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
        .map((Map<String, dynamic> row) =>
            row[RequestConstants.contourIdColumn] as String)
        .toList();
  }

  /// Adds or removes a contour from the current user's favorites.
  Future<void> toggleFavorite(String contourId) async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw Exception(RequestConstants.userNotAuthenticated);
    }

    final List<Map<String, dynamic>> existing = await _client
        .from(RequestConstants.favoritesTable)
        .select(RequestConstants.selectAll)
        .eq(RequestConstants.userIdColumn, user.id)
        .eq(RequestConstants.contourIdColumn, contourId);

    if (existing.isEmpty) {
      await _client
          .from(RequestConstants.favoritesTable)
          .insert(<String, dynamic>{
        RequestConstants.userIdColumn: user.id,
        RequestConstants.contourIdColumn: contourId,
      });
    } else {
      await _client
          .from(RequestConstants.favoritesTable)
          .delete()
          .eq(RequestConstants.userIdColumn, user.id)
          .eq(RequestConstants.contourIdColumn, contourId);
    }
  }
}
