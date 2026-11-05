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
    bool isViewOnly = false,
    List<PageRouteInfo>? children,
  }) : super(
         CanvasRoute.name,
         args: CanvasRouteArgs(
           key: key,
           contourId: contourId,
           isViewOnly: isViewOnly,
         ),
         initialChildren: children,
       );

  static const String name = 'CanvasRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CanvasRouteArgs>();
      return CanvasScreen(
        key: args.key,
        contourId: args.contourId,
        isViewOnly: args.isViewOnly,
      );
    },
  );
}

class CanvasRouteArgs {
  const CanvasRouteArgs({
    this.key,
    required this.contourId,
    this.isViewOnly = false,
  });

  final Key? key;

  final String contourId;

  final bool isViewOnly;

  @override
  String toString() {
    return 'CanvasRouteArgs{key: $key, contourId: $contourId, isViewOnly: $isViewOnly}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CanvasRouteArgs) return false;
    return key == other.key &&
        contourId == other.contourId &&
        isViewOnly == other.isViewOnly;
  }

  @override
  int get hashCode => key.hashCode ^ contourId.hashCode ^ isViewOnly.hashCode;
}
