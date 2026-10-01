import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';

import '../app_router/app_router.dart';
import '../guards/auth_guard.dart';

/// Navigation dependency injection setup.
class NavigationDI {
  /// Registers the root [AppRouter] and observers in the global [appLocator].
  static void initDependencies() {
    appLocator.registerLazySingleton<AuthGuard>(
      () => AuthGuard(
        checkAuthUseCase: appLocator<CheckAuthUseCase>(),
        signInSilentlyUseCase: appLocator<SignInSilentlyUseCase>(),
        signInUseCase: appLocator<SignInUseCase>(),
      ),
    );
    appLocator.registerLazySingleton<AppRouter>(
      () => AppRouter(authGuard: appLocator<AuthGuard>()),
    );
    appLocator.registerLazySingleton<AutoRouteObserver>(
      () => AutoRouteObserver(),
    );
  }
}
