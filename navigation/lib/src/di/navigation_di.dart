import 'package:core/core.dart';

import '../app_router/app_router.dart';

/// Navigation dependency injection setup.
class NavigationDI {
  /// Registers the root [AppRouter] in the global [appLocator].
  static void initDependencies() {
    appLocator.registerLazySingleton<AppRouter>(
      () => AppRouter(),
    );
  }
}
