// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'canvas.dart';

/// generated route for
/// [CanvasScreen]
class CanvasRoute extends PageRouteInfo<CanvasRouteArgs> {
  CanvasRoute({
    Key? key,
    required String contourId,
    List<PageRouteInfo>? children,
  }) : super(
         CanvasRoute.name,
         args: CanvasRouteArgs(key: key, contourId: contourId),
         initialChildren: children,
       );

  static const String name = 'CanvasRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CanvasRouteArgs>();
      return CanvasScreen(key: args.key, contourId: args.contourId);
    },
  );
}

class CanvasRouteArgs {
  const CanvasRouteArgs({this.key, required this.contourId});

  final Key? key;

  final String contourId;

  @override
  String toString() {
    return 'CanvasRouteArgs{key: $key, contourId: $contourId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CanvasRouteArgs) return false;
    return key == other.key && contourId == other.contourId;
  }

  @override
  int get hashCode => key.hashCode ^ contourId.hashCode;
}
