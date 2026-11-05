import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'contour_placeholder.dart';

class VectorOrPlaceholder extends StatelessWidget {
  final String? svgUrl;

  const VectorOrPlaceholder({super.key, this.svgUrl});

  @override
  Widget build(BuildContext context) {
    if (svgUrl != null && svgUrl!.isNotEmpty) {
      return SvgPicture.network(svgUrl!, fit: BoxFit.fill);
    }
    return const ContourPlaceholder();
  }
}
