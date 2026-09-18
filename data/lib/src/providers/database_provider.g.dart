// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contourIdMeta = const VerificationMeta(
    'contourId',
  );
  @override
  late final GeneratedColumn<String> contourId = GeneratedColumn<String>(
    'contour_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Map<String, dynamic>>($ProjectsTable.$converterdata);
  static const VerificationMeta _lastOpenedMeta = const VerificationMeta(
    'lastOpened',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpened = GeneratedColumn<DateTime>(
    'last_opened',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contourId,
    userId,
    data,
    lastOpened,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('contour_id')) {
      context.handle(
        _contourIdMeta,
        contourId.isAcceptableOrUnknown(data['contour_id']!, _contourIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contourIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('last_opened')) {
      context.handle(
        _lastOpenedMeta,
        lastOpened.isAcceptableOrUnknown(data['last_opened']!, _lastOpenedMeta),
      );
    } else if (isInserting) {
      context.missing(_lastOpenedMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {contourId, userId},
  ];
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contourId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contour_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      data: $ProjectsTable.$converterdata.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}data'],
        )!,
      ),
      lastOpened: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, dynamic>, String> $converterdata =
      const MapConverter();
}

class Project extends DataClass implements Insertable<Project> {
  /// Project unique identifier.
  final String id;

  /// Associated contour identifier.
  final String contourId;

  /// Owner user identifier.
  final String userId;

  /// Serialized project data (strokes and settings).
  final Map<String, dynamic> data;

  /// Last opened timestamp.
  final DateTime lastOpened;

  /// Creation timestamp.
  final DateTime createdAt;
  const Project({
    required this.id,
    required this.contourId,
    required this.userId,
    required this.data,
    required this.lastOpened,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['contour_id'] = Variable<String>(contourId);
    map['user_id'] = Variable<String>(userId);
    {
      map['data'] = Variable<String>($ProjectsTable.$converterdata.toSql(data));
    }
    map['last_opened'] = Variable<DateTime>(lastOpened);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      contourId: Value(contourId),
      userId: Value(userId),
      data: Value(data),
      lastOpened: Value(lastOpened),
      createdAt: Value(createdAt),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      contourId: serializer.fromJson<String>(json['contourId']),
      userId: serializer.fromJson<String>(json['userId']),
      data: serializer.fromJson<Map<String, dynamic>>(json['data']),
      lastOpened: serializer.fromJson<DateTime>(json['lastOpened']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contourId': serializer.toJson<String>(contourId),
      'userId': serializer.toJson<String>(userId),
      'data': serializer.toJson<Map<String, dynamic>>(data),
      'lastOpened': serializer.toJson<DateTime>(lastOpened),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Project copyWith({
    String? id,
    String? contourId,
    String? userId,
    Map<String, dynamic>? data,
    DateTime? lastOpened,
    DateTime? createdAt,
  }) => Project(
    id: id ?? this.id,
    contourId: contourId ?? this.contourId,
    userId: userId ?? this.userId,
    data: data ?? this.data,
    lastOpened: lastOpened ?? this.lastOpened,
    createdAt: createdAt ?? this.createdAt,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      contourId: data.contourId.present ? data.contourId.value : this.contourId,
      userId: data.userId.present ? data.userId.value : this.userId,
      data: data.data.present ? data.data.value : this.data,
      lastOpened: data.lastOpened.present
          ? data.lastOpened.value
          : this.lastOpened,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('contourId: $contourId, ')
          ..write('userId: $userId, ')
          ..write('data: $data, ')
          ..write('lastOpened: $lastOpened, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, contourId, userId, data, lastOpened, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.contourId == this.contourId &&
          other.userId == this.userId &&
          other.data == this.data &&
          other.lastOpened == this.lastOpened &&
          other.createdAt == this.createdAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> contourId;
  final Value<String> userId;
  final Value<Map<String, dynamic>> data;
  final Value<DateTime> lastOpened;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.contourId = const Value.absent(),
    this.userId = const Value.absent(),
    this.data = const Value.absent(),
    this.lastOpened = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String contourId,
    required String userId,
    required Map<String, dynamic> data,
    required DateTime lastOpened,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contourId = Value(contourId),
       userId = Value(userId),
       data = Value(data),
       lastOpened = Value(lastOpened),
       createdAt = Value(createdAt);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? contourId,
    Expression<String>? userId,
    Expression<String>? data,
    Expression<DateTime>? lastOpened,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contourId != null) 'contour_id': contourId,
      if (userId != null) 'user_id': userId,
      if (data != null) 'data': data,
      if (lastOpened != null) 'last_opened': lastOpened,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? contourId,
    Value<String>? userId,
    Value<Map<String, dynamic>>? data,
    Value<DateTime>? lastOpened,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      contourId: contourId ?? this.contourId,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      lastOpened: lastOpened ?? this.lastOpened,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contourId.present) {
      map['contour_id'] = Variable<String>(contourId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(
        $ProjectsTable.$converterdata.toSql(data.value),
      );
    }
    if (lastOpened.present) {
      map['last_opened'] = Variable<DateTime>(lastOpened.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('contourId: $contourId, ')
          ..write('userId: $userId, ')
          ..write('data: $data, ')
          ..write('lastOpened: $lastOpened, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StrokesTable extends Strokes with TableInfo<$StrokesTable, Stroke> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StrokesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<List<double>>, String>
  points = GeneratedColumn<String>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<List<double>>>($StrokesTable.$converterpoints);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<double> size = GeneratedColumn<double>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opacityMeta = const VerificationMeta(
    'opacity',
  );
  @override
  late final GeneratedColumn<double> opacity = GeneratedColumn<double>(
    'opacity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brushTypeMeta = const VerificationMeta(
    'brushType',
  );
  @override
  late final GeneratedColumn<String> brushType = GeneratedColumn<String>(
    'brush_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brushIdMeta = const VerificationMeta(
    'brushId',
  );
  @override
  late final GeneratedColumn<String> brushId = GeneratedColumn<String>(
    'brush_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPressureSensitiveMeta =
      const VerificationMeta('isPressureSensitive');
  @override
  late final GeneratedColumn<bool> isPressureSensitive = GeneratedColumn<bool>(
    'is_pressure_sensitive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pressure_sensitive" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    points,
    color,
    size,
    opacity,
    brushType,
    brushId,
    isPressureSensitive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strokes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Stroke> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('opacity')) {
      context.handle(
        _opacityMeta,
        opacity.isAcceptableOrUnknown(data['opacity']!, _opacityMeta),
      );
    } else if (isInserting) {
      context.missing(_opacityMeta);
    }
    if (data.containsKey('brush_type')) {
      context.handle(
        _brushTypeMeta,
        brushType.isAcceptableOrUnknown(data['brush_type']!, _brushTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_brushTypeMeta);
    }
    if (data.containsKey('brush_id')) {
      context.handle(
        _brushIdMeta,
        brushId.isAcceptableOrUnknown(data['brush_id']!, _brushIdMeta),
      );
    }
    if (data.containsKey('is_pressure_sensitive')) {
      context.handle(
        _isPressureSensitiveMeta,
        isPressureSensitive.isAcceptableOrUnknown(
          data['is_pressure_sensitive']!,
          _isPressureSensitiveMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Stroke map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Stroke(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      points: $StrokesTable.$converterpoints.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}points'],
        )!,
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}size'],
      )!,
      opacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opacity'],
      )!,
      brushType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brush_type'],
      )!,
      brushId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brush_id'],
      ),
      isPressureSensitive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pressure_sensitive'],
      )!,
    );
  }

  @override
  $StrokesTable createAlias(String alias) {
    return $StrokesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<List<double>>, String> $converterpoints =
      const PointsConverter();
}

class Stroke extends DataClass implements Insertable<Stroke> {
  /// Stroke unique identifier.
  final String id;

  /// Parent project identifier.
  final String projectId;

  /// Serialized list of points.
  final List<List<double>> points;

  /// Stroke color as a 32-bit ARGB integer.
  final int color;

  /// Brush size.
  final double size;

  /// Stroke opacity.
  final double opacity;

  /// Brush type name.
  final String brushType;

  /// Specific tool identifier.
  final String? brushId;

  /// Whether the stroke reacts to pressure.
  final bool isPressureSensitive;
  const Stroke({
    required this.id,
    required this.projectId,
    required this.points,
    required this.color,
    required this.size,
    required this.opacity,
    required this.brushType,
    this.brushId,
    required this.isPressureSensitive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    {
      map['points'] = Variable<String>(
        $StrokesTable.$converterpoints.toSql(points),
      );
    }
    map['color'] = Variable<int>(color);
    map['size'] = Variable<double>(size);
    map['opacity'] = Variable<double>(opacity);
    map['brush_type'] = Variable<String>(brushType);
    if (!nullToAbsent || brushId != null) {
      map['brush_id'] = Variable<String>(brushId);
    }
    map['is_pressure_sensitive'] = Variable<bool>(isPressureSensitive);
    return map;
  }

  StrokesCompanion toCompanion(bool nullToAbsent) {
    return StrokesCompanion(
      id: Value(id),
      projectId: Value(projectId),
      points: Value(points),
      color: Value(color),
      size: Value(size),
      opacity: Value(opacity),
      brushType: Value(brushType),
      brushId: brushId == null && nullToAbsent
          ? const Value.absent()
          : Value(brushId),
      isPressureSensitive: Value(isPressureSensitive),
    );
  }

  factory Stroke.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Stroke(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      points: serializer.fromJson<List<List<double>>>(json['points']),
      color: serializer.fromJson<int>(json['color']),
      size: serializer.fromJson<double>(json['size']),
      opacity: serializer.fromJson<double>(json['opacity']),
      brushType: serializer.fromJson<String>(json['brushType']),
      brushId: serializer.fromJson<String?>(json['brushId']),
      isPressureSensitive: serializer.fromJson<bool>(
        json['isPressureSensitive'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'points': serializer.toJson<List<List<double>>>(points),
      'color': serializer.toJson<int>(color),
      'size': serializer.toJson<double>(size),
      'opacity': serializer.toJson<double>(opacity),
      'brushType': serializer.toJson<String>(brushType),
      'brushId': serializer.toJson<String?>(brushId),
      'isPressureSensitive': serializer.toJson<bool>(isPressureSensitive),
    };
  }

  Stroke copyWith({
    String? id,
    String? projectId,
    List<List<double>>? points,
    int? color,
    double? size,
    double? opacity,
    String? brushType,
    Value<String?> brushId = const Value.absent(),
    bool? isPressureSensitive,
  }) => Stroke(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    points: points ?? this.points,
    color: color ?? this.color,
    size: size ?? this.size,
    opacity: opacity ?? this.opacity,
    brushType: brushType ?? this.brushType,
    brushId: brushId.present ? brushId.value : this.brushId,
    isPressureSensitive: isPressureSensitive ?? this.isPressureSensitive,
  );
  Stroke copyWithCompanion(StrokesCompanion data) {
    return Stroke(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      points: data.points.present ? data.points.value : this.points,
      color: data.color.present ? data.color.value : this.color,
      size: data.size.present ? data.size.value : this.size,
      opacity: data.opacity.present ? data.opacity.value : this.opacity,
      brushType: data.brushType.present ? data.brushType.value : this.brushType,
      brushId: data.brushId.present ? data.brushId.value : this.brushId,
      isPressureSensitive: data.isPressureSensitive.present
          ? data.isPressureSensitive.value
          : this.isPressureSensitive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Stroke(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('points: $points, ')
          ..write('color: $color, ')
          ..write('size: $size, ')
          ..write('opacity: $opacity, ')
          ..write('brushType: $brushType, ')
          ..write('brushId: $brushId, ')
          ..write('isPressureSensitive: $isPressureSensitive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    points,
    color,
    size,
    opacity,
    brushType,
    brushId,
    isPressureSensitive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stroke &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.points == this.points &&
          other.color == this.color &&
          other.size == this.size &&
          other.opacity == this.opacity &&
          other.brushType == this.brushType &&
          other.brushId == this.brushId &&
          other.isPressureSensitive == this.isPressureSensitive);
}

class StrokesCompanion extends UpdateCompanion<Stroke> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<List<List<double>>> points;
  final Value<int> color;
  final Value<double> size;
  final Value<double> opacity;
  final Value<String> brushType;
  final Value<String?> brushId;
  final Value<bool> isPressureSensitive;
  final Value<int> rowid;
  const StrokesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.points = const Value.absent(),
    this.color = const Value.absent(),
    this.size = const Value.absent(),
    this.opacity = const Value.absent(),
    this.brushType = const Value.absent(),
    this.brushId = const Value.absent(),
    this.isPressureSensitive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StrokesCompanion.insert({
    required String id,
    required String projectId,
    required List<List<double>> points,
    required int color,
    required double size,
    required double opacity,
    required String brushType,
    this.brushId = const Value.absent(),
    this.isPressureSensitive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       points = Value(points),
       color = Value(color),
       size = Value(size),
       opacity = Value(opacity),
       brushType = Value(brushType);
  static Insertable<Stroke> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? points,
    Expression<int>? color,
    Expression<double>? size,
    Expression<double>? opacity,
    Expression<String>? brushType,
    Expression<String>? brushId,
    Expression<bool>? isPressureSensitive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (points != null) 'points': points,
      if (color != null) 'color': color,
      if (size != null) 'size': size,
      if (opacity != null) 'opacity': opacity,
      if (brushType != null) 'brush_type': brushType,
      if (brushId != null) 'brush_id': brushId,
      if (isPressureSensitive != null)
        'is_pressure_sensitive': isPressureSensitive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StrokesCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<List<List<double>>>? points,
    Value<int>? color,
    Value<double>? size,
    Value<double>? opacity,
    Value<String>? brushType,
    Value<String?>? brushId,
    Value<bool>? isPressureSensitive,
    Value<int>? rowid,
  }) {
    return StrokesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      points: points ?? this.points,
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      brushType: brushType ?? this.brushType,
      brushId: brushId ?? this.brushId,
      isPressureSensitive: isPressureSensitive ?? this.isPressureSensitive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (points.present) {
      map['points'] = Variable<String>(
        $StrokesTable.$converterpoints.toSql(points.value),
      );
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (size.present) {
      map['size'] = Variable<double>(size.value);
    }
    if (opacity.present) {
      map['opacity'] = Variable<double>(opacity.value);
    }
    if (brushType.present) {
      map['brush_type'] = Variable<String>(brushType.value);
    }
    if (brushId.present) {
      map['brush_id'] = Variable<String>(brushId.value);
    }
    if (isPressureSensitive.present) {
      map['is_pressure_sensitive'] = Variable<bool>(isPressureSensitive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StrokesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('points: $points, ')
          ..write('color: $color, ')
          ..write('size: $size, ')
          ..write('opacity: $opacity, ')
          ..write('brushType: $brushType, ')
          ..write('brushId: $brushId, ')
          ..write('isPressureSensitive: $isPressureSensitive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BrushesTable extends Brushes with TableInfo<$BrushesTable, Brushe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrushesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameKeyMeta = const VerificationMeta(
    'nameKey',
  );
  @override
  late final GeneratedColumn<String> nameKey = GeneratedColumn<String>(
    'name_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previewPathMeta = const VerificationMeta(
    'previewPath',
  );
  @override
  late final GeneratedColumn<String> previewPath = GeneratedColumn<String>(
    'preview_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPressureSensitiveMeta =
      const VerificationMeta('isPressureSensitive');
  @override
  late final GeneratedColumn<bool> isPressureSensitive = GeneratedColumn<bool>(
    'is_pressure_sensitive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pressure_sensitive" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nameKey,
    previewPath,
    isPressureSensitive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'brushes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Brushe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name_key')) {
      context.handle(
        _nameKeyMeta,
        nameKey.isAcceptableOrUnknown(data['name_key']!, _nameKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKeyMeta);
    }
    if (data.containsKey('preview_path')) {
      context.handle(
        _previewPathMeta,
        previewPath.isAcceptableOrUnknown(
          data['preview_path']!,
          _previewPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_previewPathMeta);
    }
    if (data.containsKey('is_pressure_sensitive')) {
      context.handle(
        _isPressureSensitiveMeta,
        isPressureSensitive.isAcceptableOrUnknown(
          data['is_pressure_sensitive']!,
          _isPressureSensitiveMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isPressureSensitiveMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Brushe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Brushe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_key'],
      )!,
      previewPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview_path'],
      )!,
      isPressureSensitive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pressure_sensitive'],
      )!,
    );
  }

  @override
  $BrushesTable createAlias(String alias) {
    return $BrushesTable(attachedDatabase, alias);
  }
}

class Brushe extends DataClass implements Insertable<Brushe> {
  /// Unique tool identifier.
  final String id;

  /// Localized name key.
  final String nameKey;

  /// Path or URL to the preview image.
  final String previewPath;

  /// Whether the tool reacts to pressure.
  final bool isPressureSensitive;
  const Brushe({
    required this.id,
    required this.nameKey,
    required this.previewPath,
    required this.isPressureSensitive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name_key'] = Variable<String>(nameKey);
    map['preview_path'] = Variable<String>(previewPath);
    map['is_pressure_sensitive'] = Variable<bool>(isPressureSensitive);
    return map;
  }

  BrushesCompanion toCompanion(bool nullToAbsent) {
    return BrushesCompanion(
      id: Value(id),
      nameKey: Value(nameKey),
      previewPath: Value(previewPath),
      isPressureSensitive: Value(isPressureSensitive),
    );
  }

  factory Brushe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Brushe(
      id: serializer.fromJson<String>(json['id']),
      nameKey: serializer.fromJson<String>(json['nameKey']),
      previewPath: serializer.fromJson<String>(json['previewPath']),
      isPressureSensitive: serializer.fromJson<bool>(
        json['isPressureSensitive'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nameKey': serializer.toJson<String>(nameKey),
      'previewPath': serializer.toJson<String>(previewPath),
      'isPressureSensitive': serializer.toJson<bool>(isPressureSensitive),
    };
  }

  Brushe copyWith({
    String? id,
    String? nameKey,
    String? previewPath,
    bool? isPressureSensitive,
  }) => Brushe(
    id: id ?? this.id,
    nameKey: nameKey ?? this.nameKey,
    previewPath: previewPath ?? this.previewPath,
    isPressureSensitive: isPressureSensitive ?? this.isPressureSensitive,
  );
  Brushe copyWithCompanion(BrushesCompanion data) {
    return Brushe(
      id: data.id.present ? data.id.value : this.id,
      nameKey: data.nameKey.present ? data.nameKey.value : this.nameKey,
      previewPath: data.previewPath.present
          ? data.previewPath.value
          : this.previewPath,
      isPressureSensitive: data.isPressureSensitive.present
          ? data.isPressureSensitive.value
          : this.isPressureSensitive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Brushe(')
          ..write('id: $id, ')
          ..write('nameKey: $nameKey, ')
          ..write('previewPath: $previewPath, ')
          ..write('isPressureSensitive: $isPressureSensitive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nameKey, previewPath, isPressureSensitive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Brushe &&
          other.id == this.id &&
          other.nameKey == this.nameKey &&
          other.previewPath == this.previewPath &&
          other.isPressureSensitive == this.isPressureSensitive);
}

class BrushesCompanion extends UpdateCompanion<Brushe> {
  final Value<String> id;
  final Value<String> nameKey;
  final Value<String> previewPath;
  final Value<bool> isPressureSensitive;
  final Value<int> rowid;
  const BrushesCompanion({
    this.id = const Value.absent(),
    this.nameKey = const Value.absent(),
    this.previewPath = const Value.absent(),
    this.isPressureSensitive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BrushesCompanion.insert({
    required String id,
    required String nameKey,
    required String previewPath,
    required bool isPressureSensitive,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nameKey = Value(nameKey),
       previewPath = Value(previewPath),
       isPressureSensitive = Value(isPressureSensitive);
  static Insertable<Brushe> custom({
    Expression<String>? id,
    Expression<String>? nameKey,
    Expression<String>? previewPath,
    Expression<bool>? isPressureSensitive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameKey != null) 'name_key': nameKey,
      if (previewPath != null) 'preview_path': previewPath,
      if (isPressureSensitive != null)
        'is_pressure_sensitive': isPressureSensitive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BrushesCompanion copyWith({
    Value<String>? id,
    Value<String>? nameKey,
    Value<String>? previewPath,
    Value<bool>? isPressureSensitive,
    Value<int>? rowid,
  }) {
    return BrushesCompanion(
      id: id ?? this.id,
      nameKey: nameKey ?? this.nameKey,
      previewPath: previewPath ?? this.previewPath,
      isPressureSensitive: isPressureSensitive ?? this.isPressureSensitive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nameKey.present) {
      map['name_key'] = Variable<String>(nameKey.value);
    }
    if (previewPath.present) {
      map['preview_path'] = Variable<String>(previewPath.value);
    }
    if (isPressureSensitive.present) {
      map['is_pressure_sensitive'] = Variable<bool>(isPressureSensitive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrushesCompanion(')
          ..write('id: $id, ')
          ..write('nameKey: $nameKey, ')
          ..write('previewPath: $previewPath, ')
          ..write('isPressureSensitive: $isPressureSensitive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContoursTable extends Contours with TableInfo<$ContoursTable, Contour> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContoursTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _svgUrlMeta = const VerificationMeta('svgUrl');
  @override
  late final GeneratedColumn<String> svgUrl = GeneratedColumn<String>(
    'svg_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previewUrlMeta = const VerificationMeta(
    'previewUrl',
  );
  @override
  late final GeneratedColumn<String> previewUrl = GeneratedColumn<String>(
    'preview_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    category,
    svgUrl,
    previewUrl,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contours';
  @override
  VerificationContext validateIntegrity(
    Insertable<Contour> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('svg_url')) {
      context.handle(
        _svgUrlMeta,
        svgUrl.isAcceptableOrUnknown(data['svg_url']!, _svgUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_svgUrlMeta);
    }
    if (data.containsKey('preview_url')) {
      context.handle(
        _previewUrlMeta,
        previewUrl.isAcceptableOrUnknown(data['preview_url']!, _previewUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_previewUrlMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contour map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contour(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      svgUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}svg_url'],
      )!,
      previewUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview_url'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ContoursTable createAlias(String alias) {
    return $ContoursTable(attachedDatabase, alias);
  }
}

class Contour extends DataClass implements Insertable<Contour> {
  /// Contour unique identifier.
  final String id;

  /// Contour title.
  final String title;

  /// Contour category.
  final String category;

  /// URL to the SVG file describing the contour.
  final String svgUrl;

  /// Preview image URL.
  final String previewUrl;

  /// Creation timestamp.
  final DateTime createdAt;
  const Contour({
    required this.id,
    required this.title,
    required this.category,
    required this.svgUrl,
    required this.previewUrl,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['svg_url'] = Variable<String>(svgUrl);
    map['preview_url'] = Variable<String>(previewUrl);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ContoursCompanion toCompanion(bool nullToAbsent) {
    return ContoursCompanion(
      id: Value(id),
      title: Value(title),
      category: Value(category),
      svgUrl: Value(svgUrl),
      previewUrl: Value(previewUrl),
      createdAt: Value(createdAt),
    );
  }

  factory Contour.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contour(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      svgUrl: serializer.fromJson<String>(json['svgUrl']),
      previewUrl: serializer.fromJson<String>(json['previewUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'svgUrl': serializer.toJson<String>(svgUrl),
      'previewUrl': serializer.toJson<String>(previewUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Contour copyWith({
    String? id,
    String? title,
    String? category,
    String? svgUrl,
    String? previewUrl,
    DateTime? createdAt,
  }) => Contour(
    id: id ?? this.id,
    title: title ?? this.title,
    category: category ?? this.category,
    svgUrl: svgUrl ?? this.svgUrl,
    previewUrl: previewUrl ?? this.previewUrl,
    createdAt: createdAt ?? this.createdAt,
  );
  Contour copyWithCompanion(ContoursCompanion data) {
    return Contour(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      svgUrl: data.svgUrl.present ? data.svgUrl.value : this.svgUrl,
      previewUrl: data.previewUrl.present
          ? data.previewUrl.value
          : this.previewUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contour(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('svgUrl: $svgUrl, ')
          ..write('previewUrl: $previewUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, category, svgUrl, previewUrl, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contour &&
          other.id == this.id &&
          other.title == this.title &&
          other.category == this.category &&
          other.svgUrl == this.svgUrl &&
          other.previewUrl == this.previewUrl &&
          other.createdAt == this.createdAt);
}

class ContoursCompanion extends UpdateCompanion<Contour> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> category;
  final Value<String> svgUrl;
  final Value<String> previewUrl;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ContoursCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.svgUrl = const Value.absent(),
    this.previewUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContoursCompanion.insert({
    required String id,
    required String title,
    required String category,
    required String svgUrl,
    required String previewUrl,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       category = Value(category),
       svgUrl = Value(svgUrl),
       previewUrl = Value(previewUrl),
       createdAt = Value(createdAt);
  static Insertable<Contour> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? svgUrl,
    Expression<String>? previewUrl,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (svgUrl != null) 'svg_url': svgUrl,
      if (previewUrl != null) 'preview_url': previewUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContoursCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? category,
    Value<String>? svgUrl,
    Value<String>? previewUrl,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ContoursCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      svgUrl: svgUrl ?? this.svgUrl,
      previewUrl: previewUrl ?? this.previewUrl,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (svgUrl.present) {
      map['svg_url'] = Variable<String>(svgUrl.value);
    }
    if (previewUrl.present) {
      map['preview_url'] = Variable<String>(previewUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContoursCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('svgUrl: $svgUrl, ')
          ..write('previewUrl: $previewUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $StrokesTable strokes = $StrokesTable(this);
  late final $BrushesTable brushes = $BrushesTable(this);
  late final $ContoursTable contours = $ContoursTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projects,
    strokes,
    brushes,
    contours,
  ];
}

typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectsCompanion Function({
      required String id,
      required String contourId,
      required String userId,
      required Map<String, dynamic> data,
      required DateTime lastOpened,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<String> id,
      Value<String> contourId,
      Value<String> userId,
      Value<Map<String, dynamic>> data,
      Value<DateTime> lastOpened,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contourId => $composableBuilder(
    column: $table.contourId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get lastOpened => $composableBuilder(
    column: $table.lastOpened,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contourId => $composableBuilder(
    column: $table.contourId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpened => $composableBuilder(
    column: $table.lastOpened,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contourId =>
      $composableBuilder(column: $table.contourId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpened => $composableBuilder(
    column: $table.lastOpened,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
          Project,
          PrefetchHooks Function()
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contourId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<Map<String, dynamic>> data = const Value.absent(),
                Value<DateTime> lastOpened = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                contourId: contourId,
                userId: userId,
                data: data,
                lastOpened: lastOpened,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contourId,
                required String userId,
                required Map<String, dynamic> data,
                required DateTime lastOpened,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                contourId: contourId,
                userId: userId,
                data: data,
                lastOpened: lastOpened,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
      Project,
      PrefetchHooks Function()
    >;
typedef $$StrokesTableCreateCompanionBuilder =
    StrokesCompanion Function({
      required String id,
      required String projectId,
      required List<List<double>> points,
      required int color,
      required double size,
      required double opacity,
      required String brushType,
      Value<String?> brushId,
      Value<bool> isPressureSensitive,
      Value<int> rowid,
    });
typedef $$StrokesTableUpdateCompanionBuilder =
    StrokesCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<List<List<double>>> points,
      Value<int> color,
      Value<double> size,
      Value<double> opacity,
      Value<String> brushType,
      Value<String?> brushId,
      Value<bool> isPressureSensitive,
      Value<int> rowid,
    });

class $$StrokesTableFilterComposer
    extends Composer<_$AppDatabase, $StrokesTable> {
  $$StrokesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<List<double>>, List<List<double>>, String>
  get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get opacity => $composableBuilder(
    column: $table.opacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brushType => $composableBuilder(
    column: $table.brushType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brushId => $composableBuilder(
    column: $table.brushId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPressureSensitive => $composableBuilder(
    column: $table.isPressureSensitive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StrokesTableOrderingComposer
    extends Composer<_$AppDatabase, $StrokesTable> {
  $$StrokesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get opacity => $composableBuilder(
    column: $table.opacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brushType => $composableBuilder(
    column: $table.brushType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brushId => $composableBuilder(
    column: $table.brushId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPressureSensitive => $composableBuilder(
    column: $table.isPressureSensitive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StrokesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StrokesTable> {
  $$StrokesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<List<double>>, String> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<double> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<double> get opacity =>
      $composableBuilder(column: $table.opacity, builder: (column) => column);

  GeneratedColumn<String> get brushType =>
      $composableBuilder(column: $table.brushType, builder: (column) => column);

  GeneratedColumn<String> get brushId =>
      $composableBuilder(column: $table.brushId, builder: (column) => column);

  GeneratedColumn<bool> get isPressureSensitive => $composableBuilder(
    column: $table.isPressureSensitive,
    builder: (column) => column,
  );
}

class $$StrokesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StrokesTable,
          Stroke,
          $$StrokesTableFilterComposer,
          $$StrokesTableOrderingComposer,
          $$StrokesTableAnnotationComposer,
          $$StrokesTableCreateCompanionBuilder,
          $$StrokesTableUpdateCompanionBuilder,
          (Stroke, BaseReferences<_$AppDatabase, $StrokesTable, Stroke>),
          Stroke,
          PrefetchHooks Function()
        > {
  $$StrokesTableTableManager(_$AppDatabase db, $StrokesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StrokesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StrokesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StrokesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<List<List<double>>> points = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<double> size = const Value.absent(),
                Value<double> opacity = const Value.absent(),
                Value<String> brushType = const Value.absent(),
                Value<String?> brushId = const Value.absent(),
                Value<bool> isPressureSensitive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrokesCompanion(
                id: id,
                projectId: projectId,
                points: points,
                color: color,
                size: size,
                opacity: opacity,
                brushType: brushType,
                brushId: brushId,
                isPressureSensitive: isPressureSensitive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required List<List<double>> points,
                required int color,
                required double size,
                required double opacity,
                required String brushType,
                Value<String?> brushId = const Value.absent(),
                Value<bool> isPressureSensitive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrokesCompanion.insert(
                id: id,
                projectId: projectId,
                points: points,
                color: color,
                size: size,
                opacity: opacity,
                brushType: brushType,
                brushId: brushId,
                isPressureSensitive: isPressureSensitive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StrokesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StrokesTable,
      Stroke,
      $$StrokesTableFilterComposer,
      $$StrokesTableOrderingComposer,
      $$StrokesTableAnnotationComposer,
      $$StrokesTableCreateCompanionBuilder,
      $$StrokesTableUpdateCompanionBuilder,
      (Stroke, BaseReferences<_$AppDatabase, $StrokesTable, Stroke>),
      Stroke,
      PrefetchHooks Function()
    >;
typedef $$BrushesTableCreateCompanionBuilder =
    BrushesCompanion Function({
      required String id,
      required String nameKey,
      required String previewPath,
      required bool isPressureSensitive,
      Value<int> rowid,
    });
typedef $$BrushesTableUpdateCompanionBuilder =
    BrushesCompanion Function({
      Value<String> id,
      Value<String> nameKey,
      Value<String> previewPath,
      Value<bool> isPressureSensitive,
      Value<int> rowid,
    });

class $$BrushesTableFilterComposer
    extends Composer<_$AppDatabase, $BrushesTable> {
  $$BrushesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previewPath => $composableBuilder(
    column: $table.previewPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPressureSensitive => $composableBuilder(
    column: $table.isPressureSensitive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BrushesTableOrderingComposer
    extends Composer<_$AppDatabase, $BrushesTable> {
  $$BrushesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previewPath => $composableBuilder(
    column: $table.previewPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPressureSensitive => $composableBuilder(
    column: $table.isPressureSensitive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BrushesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrushesTable> {
  $$BrushesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameKey =>
      $composableBuilder(column: $table.nameKey, builder: (column) => column);

  GeneratedColumn<String> get previewPath => $composableBuilder(
    column: $table.previewPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPressureSensitive => $composableBuilder(
    column: $table.isPressureSensitive,
    builder: (column) => column,
  );
}

class $$BrushesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BrushesTable,
          Brushe,
          $$BrushesTableFilterComposer,
          $$BrushesTableOrderingComposer,
          $$BrushesTableAnnotationComposer,
          $$BrushesTableCreateCompanionBuilder,
          $$BrushesTableUpdateCompanionBuilder,
          (Brushe, BaseReferences<_$AppDatabase, $BrushesTable, Brushe>),
          Brushe,
          PrefetchHooks Function()
        > {
  $$BrushesTableTableManager(_$AppDatabase db, $BrushesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrushesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BrushesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BrushesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nameKey = const Value.absent(),
                Value<String> previewPath = const Value.absent(),
                Value<bool> isPressureSensitive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BrushesCompanion(
                id: id,
                nameKey: nameKey,
                previewPath: previewPath,
                isPressureSensitive: isPressureSensitive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nameKey,
                required String previewPath,
                required bool isPressureSensitive,
                Value<int> rowid = const Value.absent(),
              }) => BrushesCompanion.insert(
                id: id,
                nameKey: nameKey,
                previewPath: previewPath,
                isPressureSensitive: isPressureSensitive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BrushesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BrushesTable,
      Brushe,
      $$BrushesTableFilterComposer,
      $$BrushesTableOrderingComposer,
      $$BrushesTableAnnotationComposer,
      $$BrushesTableCreateCompanionBuilder,
      $$BrushesTableUpdateCompanionBuilder,
      (Brushe, BaseReferences<_$AppDatabase, $BrushesTable, Brushe>),
      Brushe,
      PrefetchHooks Function()
    >;
typedef $$ContoursTableCreateCompanionBuilder =
    ContoursCompanion Function({
      required String id,
      required String title,
      required String category,
      required String svgUrl,
      required String previewUrl,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ContoursTableUpdateCompanionBuilder =
    ContoursCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> category,
      Value<String> svgUrl,
      Value<String> previewUrl,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ContoursTableFilterComposer
    extends Composer<_$AppDatabase, $ContoursTable> {
  $$ContoursTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get svgUrl => $composableBuilder(
    column: $table.svgUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previewUrl => $composableBuilder(
    column: $table.previewUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContoursTableOrderingComposer
    extends Composer<_$AppDatabase, $ContoursTable> {
  $$ContoursTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get svgUrl => $composableBuilder(
    column: $table.svgUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previewUrl => $composableBuilder(
    column: $table.previewUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContoursTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContoursTable> {
  $$ContoursTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get svgUrl =>
      $composableBuilder(column: $table.svgUrl, builder: (column) => column);

  GeneratedColumn<String> get previewUrl => $composableBuilder(
    column: $table.previewUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ContoursTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContoursTable,
          Contour,
          $$ContoursTableFilterComposer,
          $$ContoursTableOrderingComposer,
          $$ContoursTableAnnotationComposer,
          $$ContoursTableCreateCompanionBuilder,
          $$ContoursTableUpdateCompanionBuilder,
          (Contour, BaseReferences<_$AppDatabase, $ContoursTable, Contour>),
          Contour,
          PrefetchHooks Function()
        > {
  $$ContoursTableTableManager(_$AppDatabase db, $ContoursTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContoursTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContoursTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContoursTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> svgUrl = const Value.absent(),
                Value<String> previewUrl = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContoursCompanion(
                id: id,
                title: title,
                category: category,
                svgUrl: svgUrl,
                previewUrl: previewUrl,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String category,
                required String svgUrl,
                required String previewUrl,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ContoursCompanion.insert(
                id: id,
                title: title,
                category: category,
                svgUrl: svgUrl,
                previewUrl: previewUrl,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContoursTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContoursTable,
      Contour,
      $$ContoursTableFilterComposer,
      $$ContoursTableOrderingComposer,
      $$ContoursTableAnnotationComposer,
      $$ContoursTableCreateCompanionBuilder,
      $$ContoursTableUpdateCompanionBuilder,
      (Contour, BaseReferences<_$AppDatabase, $ContoursTable, Contour>),
      Contour,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$StrokesTableTableManager get strokes =>
      $$StrokesTableTableManager(_db, _db.strokes);
  $$BrushesTableTableManager get brushes =>
      $$BrushesTableTableManager(_db, _db.brushes);
  $$ContoursTableTableManager get contours =>
      $$ContoursTableTableManager(_db, _db.contours);
}
