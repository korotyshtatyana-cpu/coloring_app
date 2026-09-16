import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'database_provider.g.dart';

/// Local projects table.
class Projects extends Table {
  /// Project unique identifier.
  TextColumn get id => text()();

  /// Associated contour identifier.
  TextColumn get contourId => text()();

  /// Owner user identifier.
  TextColumn get userId => text()();

  /// Serialized project data (strokes and settings).
  TextColumn get data => text().map(const MapConverter())();

  /// Last opened timestamp.
  DateTimeColumn get lastOpened => dateTime()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {contourId, userId}
      ];
}

/// Local strokes table.
class Strokes extends Table {
  /// Stroke unique identifier.
  TextColumn get id => text()();

  /// Parent project identifier.
  TextColumn get projectId => text()();

  /// Serialized list of points.
  TextColumn get points => text().map(const PointsConverter())();

  /// Stroke color as a 32-bit ARGB integer.
  IntColumn get color => integer()();

  /// Brush size.
  RealColumn get size => real()();

  /// Stroke opacity.
  RealColumn get opacity => real()();

  /// Brush type name.
  TextColumn get brushType => text()();

  /// Specific tool identifier.
  TextColumn get brushId => text().nullable()();

  /// Whether the stroke reacts to pressure.
  BoolColumn get isPressureSensitive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local tools/brushes table.
class Brushes extends Table {
  /// Unique tool identifier.
  TextColumn get id => text()();

  /// Localized name key.
  TextColumn get nameKey => text()();

  /// Path or URL to the preview image.
  TextColumn get previewPath => text()();

  /// Whether the tool reacts to pressure.
  BoolColumn get isPressureSensitive => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cached contours table.
class Contours extends Table {
  /// Contour unique identifier.
  TextColumn get id => text()();

  /// Contour title.
  TextColumn get title => text()();

  /// Contour category.
  TextColumn get category => text()();

  /// SVG data describing the contour.
  TextColumn get svgData => text()();

  /// Preview image URL.
  TextColumn get previewUrl => text()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Converts a JSON string to a Map<String, dynamic> and back.
class MapConverter extends TypeConverter<Map<String, dynamic>, String> {
  /// Creates a [MapConverter].
  const MapConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    return jsonDecode(fromDb) as Map<String, dynamic>;
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return jsonEncode(value);
  }
}

/// Converts a JSON string to a List<List<double>> and back.
class PointsConverter extends TypeConverter<List<List<double>>, String> {
  /// Creates a [PointsConverter].
  const PointsConverter();

  @override
  List<List<double>> fromSql(String fromDb) {
    return (jsonDecode(fromDb) as List<dynamic>)
        .map((dynamic e) => (e as List<dynamic>).cast<double>())
        .toList();
  }

  @override
  String toSql(List<List<double>> value) {
    return jsonEncode(value);
  }
}

/// Drift database for local project, stroke and contour storage.
@DriftDatabase(tables: <Type>[Projects, Strokes, Brushes, Contours])
class AppDatabase extends _$AppDatabase {
  /// Creates a database instance.
  AppDatabase() : super(_openConnection());

  /// Current database schema version.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Create the new brushes table
            await m.createTable(brushes);
            // Add missing columns to strokes
            await m.addColumn(strokes, strokes.brushId);
            await m.addColumn(strokes, strokes.isPressureSensitive);
          }
        },
      );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final Directory dbFolder = await getApplicationDocumentsDirectory();
      final File file =
          File(path.join(dbFolder.path, 'coloring_pro_db.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
