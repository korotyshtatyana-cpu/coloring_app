import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:domain/domain.dart';
import '../constants/request_constants.dart';
import '../mappers/project_mapper.dart';
import '../mappers/stroke_mapper.dart';
import '../models/project_model.dart';
import '../models/stroke_model.dart';

import '../providers/auth_remote_provider.dart';
import '../providers/canvas_local_provider.dart';
import '../providers/canvas_remote_provider.dart';
import '../services/canvas_rendering_service.dart';
import '../services/gallery_saver_service.dart';

/// Implementation of [CanvasRepository] managing local strokes and remote sync.
class CanvasRepositoryImpl implements CanvasRepository {
  final CanvasRemoteProvider _remoteProvider;
  final CanvasLocalProvider _localProvider;
  final AuthRemoteProvider _authRemoteProvider;

  final Map<String, List<StrokeEntity>> _strokes =
      <String, List<StrokeEntity>>{};

  /// Longest side of the exported image in pixels.
  static const double _exportTargetSize = 1024;

  /// Longest side of a project thumbnail in pixels.
  static const double _thumbnailTargetSize = 512;

  /// Creates a repository with the given providers.
  CanvasRepositoryImpl({
    required this._remoteProvider,
    required this._localProvider,
    required this._authRemoteProvider,
  });

  @override
  Future<void> addStroke(String projectId, StrokeEntity stroke) async {
    _strokes.putIfAbsent(projectId, () => <StrokeEntity>[]);
    _strokes[projectId]!.add(stroke);

    // Pass a copy because the cached list can be modified concurrently
    // (e.g. another addStroke can run while saveProject is awaiting a DB
    // write, which would mutate the list mid-iteration).
    await _localProvider.saveProject(
      _projectModelFromId(projectId),
      List<StrokeEntity>.from(_strokes[projectId]!),
    );
  }

  @override
  Future<void> saveProject(ProjectEntity project) async {
    final mapped = ProjectMapper.toModel(project);
    final model = ProjectModel(
      id: mapped.id,
      contourId: mapped.contourId,
      userId: _authRemoteProvider.currentUserId ?? mapped.userId,
      data: mapped.data,
      lastOpened: mapped.lastOpened,
      createdAt: mapped.createdAt,
    );
    final strokes = _strokesFromData(mapped.data);
    _strokes[project.id] = strokes;
    // Pass a copy because the cached list can be modified concurrently
    // (e.g. addStroke runs while saveProject is awaiting DB writes).
    await _localProvider.saveProject(model, List<StrokeEntity>.from(strokes));
    try {
      await _remoteProvider.saveProject(model);
    } catch (e, stackTrace) {
      // Remote sync failed (e.g. RLS policy misconfiguration or no network).
      // Local data is already saved, so the user can keep drawing.
      debugPrint('Remote project sync failed: $e');
      debugPrint('$stackTrace');
    }
  }

  @override
  Future<ProjectEntity?> loadProject(String contourId) async {
    final localProject = await _localProvider.loadProject(contourId);
    if (localProject != null) {
      final strokes = await _localProvider.loadStrokes(localProject.id);
      _strokes[localProject.id] = strokes;
      return ProjectMapper.toEntity(localProject);
    }

    final remoteProject = await _remoteProvider.loadProject(contourId);
    if (remoteProject != null) {
      final strokes = _strokesFromData(remoteProject.data);
      _strokes[remoteProject.id] = strokes;
      await _localProvider.saveProject(remoteProject, strokes);
      return ProjectMapper.toEntity(remoteProject);
    }

    return null;
  }

  @override
  Future<void> saveImageToGallery(String filePath) async {
    await GallerySaverService.saveFile(filePath);
  }

  @override
  Future<String?> exportImage(ExportImageParams params) async {
    final ByteData? byteData = await _renderCanvasPng(params, _exportTargetSize);
    if (byteData == null) return null;

    final directory = await getTemporaryDirectory();
    final fileName =
        '${RequestConstants.exportFilePrefix}_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return file.path;
  }

  @override
  Future<String?> renderProjectThumbnail(ExportImageParams params) async {
    final ByteData? byteData =
        await _renderCanvasPng(params, _thumbnailTargetSize);
    if (byteData == null) return null;

    final directory = await getApplicationDocumentsDirectory();
    final thumbnailsDir = Directory('${directory.path}/thumbnails');
    if (!thumbnailsDir.existsSync()) {
      thumbnailsDir.createSync(recursive: true);
    }
    final file = File('${thumbnailsDir.path}/${params.projectId}.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    // The file path never changes, so drop the stale decoded image from the
    // framework cache; otherwise the gallery keeps showing the old render.
    imageCache.evict(FileImage(file));

    return file.path;
  }

  /// Renders the whole canvas (white background, strokes and contour) into
  /// PNG bytes with the longest side equal to [targetSize].
  Future<ByteData?> _renderCanvasPng(
    ExportImageParams params,
    double targetSize,
  ) async {
    final strokes =
        params.strokes ?? await _loadStrokesForProject(params.projectId);

    return CanvasRenderingService.renderCanvasPng(
      contourSvg: params.contourSvg,
      contourColor: params.contourColor,
      contourOpacity: params.contourOpacity,
      contourWidth: params.contourWidth,
      strokes: strokes,
      targetSize: targetSize,
    );
  }

  ProjectModel _projectModelFromId(String projectId) {
    return ProjectModel(
      id: projectId,
      contourId: projectId,
      userId: _authRemoteProvider.currentUserId ?? '',
      data: <String, dynamic>{},
      lastOpened: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  Future<List<StrokeEntity>> _loadStrokesForProject(String projectId) async {
    final cached = _strokes[projectId];
    if (cached != null) {
      return cached;
    }

    final localProject = await _localProvider.loadProject(projectId);
    if (localProject != null) {
      final strokes = await _localProvider.loadStrokes(localProject.id);
      _strokes[localProject.id] = strokes;
      return strokes;
    }

    return <StrokeEntity>[];
  }

  List<StrokeEntity> _strokesFromData(Map<String, dynamic> data) {
    final strokesJson = data['strokes'] as List<dynamic>?;
    if (strokesJson == null) {
      return <StrokeEntity>[];
    }
    return strokesJson
        .map((dynamic json) => StrokeMapper.toEntity(
            StrokeModel.fromJson(json as Map<String, dynamic>)))
        .toList();
  }
}
