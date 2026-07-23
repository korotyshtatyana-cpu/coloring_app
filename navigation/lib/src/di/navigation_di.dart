import 'package:core/core.dart';

import '../app_router/app_router.dart';

class NavigationDI {
  static void initDependencies() {
    appLocator.registerLazySingleton<AppRouter>(
      () => AppRouter(),
    );
  }
}
