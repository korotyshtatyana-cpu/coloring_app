import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'contour_placeholder.dart';

class VectorOrPlaceholder extends StatelessWidget {
  final String? svgData;

  const VectorOrPlaceholder({super.key, this.svgData});

  @override
  Widget build(BuildContext context) {
    if (svgData != null && svgData!.isNotEmpty) {
      return SvgPicture.string(svgData!, fit: BoxFit.fill);
    }
    return const ContourPlaceholder();
  }
}