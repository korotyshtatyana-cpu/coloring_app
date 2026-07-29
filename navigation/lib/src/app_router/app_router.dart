import 'package:auto_route/auto_route.dart';
import 'package:splash/splash.dart';
import 'package:canvas/canvas.dart';
import 'package:gallery/gallery.dart';
import 'package:settings/settings.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => <AutoRoute>[
        AutoRoute(
          page: SplashRoute.page,
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
