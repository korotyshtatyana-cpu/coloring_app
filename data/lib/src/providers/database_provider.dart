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
  TextColumn get data => text()();

  /// Last opened timestamp.
  DateTimeColumn get lastOpened => dateTime()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local strokes table.
class Strokes extends Table {
  /// Stroke unique identifier.
  TextColumn get id => text()();

  /// Parent project identifier.
  TextColumn get projectId => text()();

  /// Serialized list of points.
  TextColumn get points => text()();

  /// Stroke color as a 32-bit ARGB integer.
  IntColumn get color => integer()();

  /// Brush size.
  RealColumn get size => real()();

  /// Stroke opacity.
  RealColumn get opacity => real()();

  /// Brush type name.
  TextColumn get brushType => text()();

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

/// Drift database for local project, stroke and contour storage.
@DriftDatabase(tables: <Type>[Projects, Strokes, Contours])
class AppDatabase extends _$AppDatabase {
  /// Creates a database instance.
  AppDatabase() : super(_openConnection());

  /// Current database schema version.
  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final Directory dbFolder = await getApplicationDocumentsDirectory();
      final File file =
          File(path.join(dbFolder.path, 'coloring_pro_db.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
