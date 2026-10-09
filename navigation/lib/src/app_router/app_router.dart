import 'package:auto_route/auto_route.dart';
import 'package:splash/splash.dart';
import 'package:canvas/canvas.dart';
import 'package:gallery/gallery.dart';
import 'package:settings/settings.dart';
import 'package:subscription/subscription.dart';

import '../guards/auth_guard.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  final AuthGuard _authGuard;

  /// Creates an [AppRouter] with the injected [_authGuard].
  AppRouter({required this._authGuard});

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
          guards: <AutoRouteGuard>[_authGuard],
        ),
        AutoRoute(
          page: GalleryRoute.page,
          guards: <AutoRouteGuard>[_authGuard],
        ),
        AutoRoute(
          page: SettingsRoute.page,
          guards: <AutoRouteGuard>[_authGuard],
        ),
        AutoRoute(
          page: SubscriptionRoute.page,
          guards: <AutoRouteGuard>[_authGuard],
        ),
      ];

  @override
  List<AutoRouteGuard> get guards => <AutoRouteGuard>[];
}
