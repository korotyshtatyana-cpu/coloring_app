import 'package:auto_route/auto_route.dart';
import 'package:domain/domain.dart';
import 'package:splash/splash.dart';

/// Guard that checks user authentication before allowing navigation
/// to protected routes.
class AuthGuard extends AutoRouteGuard {
  final CheckAuthUseCase checkAuthUseCase;
  final SignInSilentlyUseCase signInSilentlyUseCase;
  final SignInUseCase signInUseCase;

  /// Creates an [AuthGuard] with the required use cases.
  AuthGuard({
    required this.checkAuthUseCase,
    required this.signInSilentlyUseCase,
    required this.signInUseCase,
  });

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    // 1. Check if the user is already authenticated.
    final bool isAuthenticated = await checkAuthUseCase.execute();
    if (isAuthenticated) {
      resolver.next(true);
      return;
    }

    // 2. Attempt silent sign-in if available.
    try {
      await signInSilentlyUseCase.execute();
      resolver.next(true);
      return;
    } catch (_) {
      // Silent sign-in failed/unavailable.
    }

    // 3. Attempt interactive sign-in as fallback.
    try {
      await signInUseCase.execute();
      resolver.next(true);
      return;
    } catch (_) {
      // Interactive sign-in failed or user cancelled.
    }

    // 4. If all auth attempts fail, redirect to SplashRoute and reject navigation.
    router.replaceAll(const <PageRouteInfo>[SplashRoute()]);
    resolver.next(false);
  }
}
