import 'dart:async';
import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../bloc/canvas_bloc.dart';
import '../../painters/canvas_painter.dart';
import '../../utils/perf_log.dart';

/// Longest edge of the cached contour raster, in physical pixels.
///
/// A texture taller than the GPU limit can never be retained by the raster
/// cache, so the image is re-uploaded every frame. This is the knob to sweep
/// when looking for the knee on a given device: raise it until `raster` starts
/// growing again, then back off.
const int _kMaxContourEdge = 4096;

/// How far the zoom may grow past the cached raster before it is regenerated.
///
/// This bounds how much the cached raster is ever stretched. Lower values keep
/// it closer to the true on-screen resolution at the cost of more frequent
/// regeneration, which [Duration _kContourRasterDebounce] hides from the
/// gesture. At 1.6 the raster could be stretched up to 60% before a refresh,
/// which is clearly visible as blur while zoomed in; 1.15 keeps that slack under
/// about 15%.
const double _kContourLodFactor = 1.15;

/// Quiet period after the last zoom change before regenerating the raster.
///
/// Rasterizing costs 60-150 ms. Regenerating on every LOD step meant the cached
/// image was repeatedly replaced with a low-resolution one *while the gesture was
/// still running*, which is exactly when the user can see the blur. Deferring to
/// the end of the gesture means the sharp raster is ready by the time the
/// fingers lift, and no frame is ever blocked mid-pinch.
const Duration _kContourRasterDebounce = Duration(milliseconds: 250);

/// Layer that renders the contour SVG on top of the drawing.
class ContourLayer extends StatefulWidget {
  /// Creates a [ContourLayer].
  const ContourLayer({super.key});

  @override
  State<ContourLayer> createState() => _ContourLayerState();
}

class _ContourLayerState extends State<ContourLayer> {
  PictureInfo? _contourPicture;
  String? _loadedContourKey;

  ui.Image? _raster;
  double _rasterRatio = 0;
  String? _rasterKey;
  bool _isRastering = false;
  Timer? _rasterDebounce;
  (PictureInfo, String, double)? _pendingContour;

  @override
  void dispose() {
    _rasterDebounce?.cancel();
    _raster?.dispose();
    _contourPicture?.picture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CanvasBloc>().state;
    final contour = state.contour;
    final contourSvg = state.contourSvg;

    if (contour == null || contourSvg == null) {
      return const SizedBox.shrink();
    }

    final String key = contour.id;
    if (_loadedContourKey != key) {
      _loadedContourKey = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadContourPicture(context, contourSvg, key);
      });
    }

    final PictureInfo? pictureInfo = _contourPicture;
    if (pictureInfo == null) {
      return const SizedBox.shrink();
    }

    _maybeRasterize(pictureInfo, key, state);

    return CustomPaint(
      painter: ContourPainter(
        pictureInfo: pictureInfo,
        rasterImage: _raster,
        color: state.contourColor,
        opacity: state.contourOpacity,
      ),
    );
  }

  /// Physical pixels per SVG unit needed to stay crisp at the current zoom.
  ///
  /// Derived from what is actually on screen, not from the page size: at fit
  /// zoom the page is minified into the viewport, so the full page resolution
  /// would be pure oversampling. At fit zoom this lands near the width of the
  /// viewport in device pixels.
  double _targetRatio(PictureInfo pictureInfo, CanvasState state) {
    final Size svgSize = pictureInfo.size;
    if (svgSize.width <= 0 || svgSize.height <= 0) {
      return 1;
    }
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double dpr = View.of(context).devicePixelRatio;
    final double zoom = state.transform.getMaxScaleOnAxis();
    final double wanted = viewportWidth * dpr / svgSize.width * zoom;
    final double longestSvg =
        svgSize.width > svgSize.height ? svgSize.width : svgSize.height;
    final double capped = _kMaxContourEdge / longestSvg;
    return wanted > capped ? capped : wanted;
  }

  void _maybeRasterize(PictureInfo pictureInfo, String key, CanvasState state) {
    if (!mounted || _isRastering || _loadedContourKey != key) {
      return;
    }
    final double wanted = _targetRatio(pictureInfo, state);
    // Only ever upgrade. Zooming out must not downgrade the cached raster: the
    // higher-resolution image still scales down correctly, whereas replacing it
    // with a smaller one mid-gesture is what made the contour visibly blur.
    final bool firstRaster = _raster == null;
    final bool stale = firstRaster ||
        _rasterKey != key ||
        _rasterRatio < wanted / _kContourLodFactor;
    if (!stale) {
      return;
    }
    _pendingContour = (pictureInfo, key, wanted);
    _rasterDebounce?.cancel();
    if (firstRaster) {
      // Nothing to show yet, so render immediately rather than leaving the page
      // contour-less for the debounce period.
      WidgetsBinding.instance.addPostFrameCallback((_) => _rasterizePending());
      return;
    }
    _rasterDebounce = Timer(
      _kContourRasterDebounce,
      _rasterizePending,
    );
  }

  Future<void> _rasterizePending() async {
    final (PictureInfo pictureInfo, String key, double ratio)? pending =
        _pendingContour;
    _pendingContour = null;
    if (pending == null) {
      return;
    }
    await _rasterizeContour(pending.$1, pending.$2, pending.$3);
  }

  Future<void> _rasterizeContour(
    PictureInfo pictureInfo,
    String key,
    double ratio,
  ) async {
    if (!mounted || _isRastering || _loadedContourKey != key) {
      return;
    }
    _isRastering = true;
    try {
      final Size svgSize = pictureInfo.size;
      final int width = (svgSize.width * ratio).round();
      final int height = (svgSize.height * ratio).round();
      if (width <= 0 || height <= 0) {
        return;
      }

      // `Picture.toImage` does not scale: it captures the region
      // [0..width, 0..height] of the picture's own coordinate space 1:1. Asking
      // it for `svgSize * ratio` would therefore leave the vector shrunk into
      // the top-left corner of an otherwise empty image. Scale the picture
      // first so the vector actually fills the image.
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      canvas
        ..scale(ratio, ratio)
        ..drawPicture(pictureInfo.picture);
      final ui.Picture scaled = recorder.endRecording();

      final Stopwatch stopwatch = Stopwatch()..start();
      final ui.Image image = await scaled.toImage(width, height);
      stopwatch.stop();
      scaled.dispose();
      if (!mounted || _loadedContourKey != key) {
        image.dispose();
        return;
      }
      setState(() {
        _raster?.dispose();
        _raster = image;
        _rasterRatio = ratio;
        _rasterKey = key;
      });
      perfLog(
        'contour-raster',
        '(${width}x$height ratio=${ratio.toStringAsFixed(2)}) '
        'ms=${stopwatch.elapsedMilliseconds}',
      );
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
    } finally {
      _isRastering = false;
    }
  }

  Future<void> _loadContourPicture(
    BuildContext context,
    String svgData,
    String key,
  ) async {
    try {
      final PictureInfo info = await vg.loadPicture(
        SvgStringLoader(svgData),
        null,
      );
      perfLogOnce(
        'svg',
        'bytes=${svgData.length} '
        'paths=${'<path'.allMatches(svgData).length} '
        'svgSize=${info.size.width.round()}x${info.size.height.round()}',
      );
      if (!mounted || _loadedContourKey != key) {
        info.picture.dispose();
        return;
      }
      setState(() {
        _contourPicture?.picture.dispose();
        _contourPicture = info;
        _raster?.dispose();
        _raster = null;
        _rasterRatio = 0;
        _rasterKey = null;
      });

      if (mounted && context.mounted) {
        context.read<CanvasBloc>().add(const ContourCompiled());
      }
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
      if (context.mounted) {
        context.read<CanvasBloc>().add(const ContourCompiled());
      }
    }
  }
}