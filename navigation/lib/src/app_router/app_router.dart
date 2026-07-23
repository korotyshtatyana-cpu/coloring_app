import 'package:auto_route/auto_route.dart';
import 'package:auth/auth.dart';
import 'package:gallery/gallery.dart';
import 'package:canvas/canvas.dart';
import 'package:settings/settings.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => <AutoRoute>[
        AutoRoute(
          page: AuthRoute.page,
          initial: true,
        ),
        AutoRoute(
          page: CanvasRoute.page,
        ),
        AutoRoute(
          page: GalleryRoute.page,
        ),
        AutoRoute(
          page: SettingsRoute.page,
        ),
      ];

  @override
  List<AutoRouteGuard> get guards => <AutoRouteGuard>[];
}
