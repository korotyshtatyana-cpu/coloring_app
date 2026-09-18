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

    return CustomPaint(
      painter: ContourPainter(
        pictureInfo: pictureInfo,
        color: state.contourColor,
        opacity: state.contourOpacity,
      ),
    );
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
      if (!mounted || _loadedContourKey != key) {
        info.picture.dispose();
        return;
      }
      setState(() {
        _contourPicture?.picture.dispose();
        _contourPicture = info;
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
