import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';

import 'package:domain/domain.dart';
import '../constants/request_constants.dart';
import '../mappers/project_mapper.dart';
import '../mappers/stroke_mapper.dart';
import '../models/project_model.dart';
import '../models/stroke_model.dart';
import 'package:core/core.dart';

import '../providers/auth_remote_provider.dart';
import '../providers/canvas_local_provider.dart';
import '../providers/canvas_remote_provider.dart';
import '../services/gallery_saver_service.dart';

/// Implementation of [CanvasRepository] managing local strokes and remote sync.
class CanvasRepositoryImpl implements CanvasRepository {
  final CanvasRemoteProvider _remoteProvider;
  final CanvasLocalProvider _localProvider;
  final AuthRemoteProvider _authRemoteProvider;

  final Map<String, List<StrokeEntity>> _strokes = <String, List<StrokeEntity>>{};

  /// Longest side of the exported image in pixels.
  static const double _exportTargetSize = 1024;

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

    await _localProvider.saveProject(
      _projectModelFromId(projectId),
      _strokes[projectId]!,
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
    final strokes = await _loadStrokesForProject(params.projectId);

    // Strokes live in canvas (viewBox) coordinates; scale them to fit the
    // output while keeping the canvas aspect ratio.
    final Size canvasSize =
        SvgUtils.parseViewBoxSize(params.contourSvg) ?? const Size(1024, 1024);
    final double scale = min(
      _exportTargetSize / canvasSize.width,
      _exportTargetSize / canvasSize.height,
    );
    final Size outputSize = Size(
      canvasSize.width * scale,
      canvasSize.height * scale,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & outputSize, backgroundPaint);
    canvas.scale(scale);

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    await _drawContour(
      canvas,
      svgData: SvgUtils.applyStrokeWidth(params.contourSvg, params.contourWidth),
      color: params.contourColor,
      opacity: params.contourOpacity,
      width: params.contourWidth,
      size: canvasSize,
    );

    final picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      outputSize.width.round(),
      outputSize.height.round(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      return null;
    }

    final directory = await getTemporaryDirectory();
    final fileName =
        '${RequestConstants.exportFilePrefix}_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return file.path;
  }

  void _drawStroke(Canvas canvas, StrokeEntity stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = Color(stroke.color).withValues(alpha: stroke.opacity)
      ..strokeWidth = stroke.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.brushType == BrushType.watercolor ||
        stroke.brushType == BrushType.airbrush) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    }

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  Future<void> _drawContour(
    Canvas canvas, {
    required String svgData,
    required Color color,
    required double opacity,
    required double width,
    required Size size,
  }) async {
    final PictureInfo pictureInfo = await vg.loadPicture(
      SvgStringLoader(svgData),
      null,
    );

    final recorder = ui.PictureRecorder();
    final strokeCanvas = Canvas(recorder);

    strokeCanvas.drawPicture(pictureInfo.picture);

    final strokePicture = recorder.endRecording();
    final layerPaint = Paint()
      ..colorFilter = ColorFilter.mode(
        color.withValues(alpha: opacity),
        BlendMode.srcIn,
      );

    canvas.saveLayer(Offset.zero & size, layerPaint);
    canvas.drawPicture(strokePicture);
    canvas.restore();

    pictureInfo.picture.dispose();
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
