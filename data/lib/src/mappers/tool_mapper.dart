import 'package:domain/domain.dart';

/// Maps tool records from Supabase and Drift to [ToolEntity].
abstract final class ToolMapper {
  /// Builds a tool from a Supabase row.
  ///
  /// Column names are accepted in both `snake_case` and `camelCase` so older
  /// and newer remote schemas keep working. Returns `null` for a row without a
  /// usable identifier.
  static ToolEntity? fromRemoteRow(Map<String, dynamic> row) {
    final Object? rawId = row['id'];
    if (rawId is! String || rawId.isEmpty) {
      return null;
    }

    final Object? rawName = row['name_key'] ?? row['nameKey'];
    final Object? rawPreview =
        row['preview_path'] ?? row['previewPath'] ?? row['preview_url'];
    final Object? rawPressure =
        row['is_pressure_sensitive'] ?? row['isPressureSensitive'];

    return fromFields(
      id: rawId,
      nameKey: rawName is String && rawName.isNotEmpty
          ? rawName
          : 'brush_$rawId',
      previewPath: rawPreview is String ? rawPreview : '',
      isPressureSensitive: _asBool(rawPressure),
    );
  }

  /// Builds a tool from already normalized fields.
  ///
  /// Rendering behavior of a built-in brush is defined in code, so the pressure
  /// flag of a known identifier wins over the cached or remote value. This
  /// keeps a stale local row (or a partially filled remote row) from silently
  /// turning pressure support off for a brush that supports it.
  static ToolEntity fromFields({
    required String id,
    required String nameKey,
    required String previewPath,
    required bool isPressureSensitive,
  }) {
    return ToolEntity(
      id: id,
      nameKey: nameKey,
      previewPath: previewPath,
      isPressureSensitive:
          isPressureSensitiveForId(id) ?? isPressureSensitive,
      brushType: brushTypeForId(id),
    );
  }

  /// Canonical pressure sensitivity for built-in brush identifiers.
  ///
  /// Returns `null` for identifiers unknown to this build so their flag can be
  /// taken from the catalog row.
  static bool? isPressureSensitiveForId(String id) {
    switch (id) {
      case 'fine_liner':
      case 'soft_liner':
        return true;
      case 'round_basic':
      case 'soft_round_basic':
        return false;
    }
    return null;
  }

  /// Resolves a database tool identifier to the brush type used by painters.
  ///
  /// Unknown identifiers fall back to [BrushType.circle], which keeps the app
  /// usable when the backend adds a tool before this build supports it.
  static BrushType brushTypeForId(String id) {
    switch (id) {
      case 'soft_liner':
        return BrushType.softLiner;
      case 'soft_round_basic':
        return BrushType.softRoundBasic;
      case 'round_basic':
      case 'fine_liner':
        return BrushType.circle;
    }

    for (final BrushType type in BrushType.values) {
      if (type.name == id) {
        return type;
      }
    }
    return BrushType.circle;
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }
}
