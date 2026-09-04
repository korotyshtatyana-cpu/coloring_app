import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';

import '../app_router/app_router.dart';

/// Navigation dependency injection setup.
class NavigationDI {
  /// Registers the root [AppRouter] and observers in the global [appLocator].
  static void initDependencies() {
    appLocator.registerLazySingleton<AppRouter>(
      () => AppRouter(),
    );
    appLocator.registerLazySingleton<AutoRouteObserver>(
      () => AutoRouteObserver(),
    );
  }
}
