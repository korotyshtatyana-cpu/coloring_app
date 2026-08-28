import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../bloc/canvas_bloc.dart';
import '../../painters/canvas_painter.dart';

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

  @override
  void dispose() {
    _contourPicture?.picture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CanvasBloc>().state;
    final contour = state.contour;

    if (contour == null) {
      return const SizedBox.shrink();
    }

    final String key = '${contour.id}:${state.contourWidth}';
    if (_loadedContourKey != key) {
      _loadedContourKey = key;
      final String svgData = SvgUtils.applyStrokeWidth(
        contour.svgData,
        state.contourWidth,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadContourPicture(svgData, key);
      });
    }

    final PictureInfo? pictureInfo = _contourPicture;
    if (pictureInfo == null) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: ContourPainter(
        pictureInfo: pictureInfo,
        color: state.contourColor,
        opacity: state.contourOpacity,
      ),
    );
  }

  Future<void> _loadContourPicture(String svgData, String key) async {
    try {
      final PictureInfo info = await vg.loadPicture(
        SvgStringLoader(svgData),
        null,
      );
      if (!mounted || _loadedContourKey != key) {
        info.picture.dispose();
        return;
      }
      setState(() {
        _contourPicture?.picture.dispose();
        _contourPicture = info;
      });
    } catch (e, stackTrace) {
      ErrorHandler.report(e, stackTrace);
    }
  }
}
