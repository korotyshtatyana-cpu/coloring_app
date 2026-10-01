import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation/navigation.dart';
import 'package:splash/splash.dart';

class FakeCheckAuthUseCase extends Fake implements CheckAuthUseCase {
  final bool result;
  FakeCheckAuthUseCase(this.result);

  @override
  Future<bool> execute([NoParams? params]) async => result;
}

class FakeSignInSilentlyUseCase extends Fake implements SignInSilentlyUseCase {
  final bool shouldSucceed;
  bool executed = false;

  FakeSignInSilentlyUseCase({this.shouldSucceed = true});

  @override
  Future<UserEntity> execute([NoParams? params]) async {
    executed = true;
    if (!shouldSucceed) {
      throw Exception('Silent sign in failed');
    }
    return const UserEntity(id: '1', email: 'test@example.com', name: 'Test');
  }
}

class FakeSignInUseCase extends Fake implements SignInUseCase {
  final bool shouldSucceed;
  bool executed = false;

  FakeSignInUseCase({this.shouldSucceed = true});

  @override
  Future<UserEntity> execute([NoParams? params]) async {
    executed = true;
    if (!shouldSucceed) {
      throw Exception('Sign in failed');
    }
    return const UserEntity(id: '1', email: 'test@example.com', name: 'Test');
  }
}

class FakeNavigationResolver extends Fake implements NavigationResolver {
  bool? nextCalledWith;

  @override
  void next([bool continueNavigation = true]) {
    nextCalledWith = continueNavigation;
  }
}

class FakeStackRouter extends Fake implements StackRouter {
  List<PageRouteInfo>? replacedRoutes;

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool updateUrl = true,
    bool updateExistingRoutes = true,
  }) async {
    replacedRoutes = routes;
  }
}

void main() {
  group('AuthGuard', () {
    test('allows navigation directly when checkAuth is true', () async {
      final checkAuth = FakeCheckAuthUseCase(true);
      final signInSilently = FakeSignInSilentlyUseCase();
      final signIn = FakeSignInUseCase();

      final guard = AuthGuard(
        checkAuthUseCase: checkAuth,
        signInSilentlyUseCase: signInSilently,
        signInUseCase: signIn,
      );

      final resolver = FakeNavigationResolver();
      final router = FakeStackRouter();

      await guard.onNavigation(resolver, router);

      expect(resolver.nextCalledWith, true);
      expect(signInSilently.executed, false);
      expect(signIn.executed, false);
    });

    test('allows navigation after silent sign in when checkAuth is false', () async {
      final checkAuth = FakeCheckAuthUseCase(false);
      final signInSilently = FakeSignInSilentlyUseCase(shouldSucceed: true);
      final signIn = FakeSignInUseCase();

      final guard = AuthGuard(
        checkAuthUseCase: checkAuth,
        signInSilentlyUseCase: signInSilently,
        signInUseCase: signIn,
      );

      final resolver = FakeNavigationResolver();
      final router = FakeStackRouter();

      await guard.onNavigation(resolver, router);

      expect(resolver.nextCalledWith, true);
      expect(signInSilently.executed, true);
      expect(signIn.executed, false);
    });

    test('allows navigation after interactive sign in when silent sign in fails', () async {
      final checkAuth = FakeCheckAuthUseCase(false);
      final signInSilently = FakeSignInSilentlyUseCase(shouldSucceed: false);
      final signIn = FakeSignInUseCase(shouldSucceed: true);

      final guard = AuthGuard(
        checkAuthUseCase: checkAuth,
        signInSilentlyUseCase: signInSilently,
        signInUseCase: signIn,
      );

      final resolver = FakeNavigationResolver();
      final router = FakeStackRouter();

      await guard.onNavigation(resolver, router);

      expect(resolver.nextCalledWith, true);
      expect(signInSilently.executed, true);
      expect(signIn.executed, true);
    });

    test('redirects to SplashRoute and denies navigation when all auth attempts fail', () async {
      final checkAuth = FakeCheckAuthUseCase(false);
      final signInSilently = FakeSignInSilentlyUseCase(shouldSucceed: false);
      final signIn = FakeSignInUseCase(shouldSucceed: false);

      final guard = AuthGuard(
        checkAuthUseCase: checkAuth,
        signInSilentlyUseCase: signInSilently,
        signInUseCase: signIn,
      );

      final resolver = FakeNavigationResolver();
      final router = FakeStackRouter();

      await guard.onNavigation(resolver, router);

      expect(resolver.nextCalledWith, false);
      expect(router.replacedRoutes, isNotNull);
      expect(router.replacedRoutes!.length, 1);
      expect(router.replacedRoutes!.first, isA<SplashRoute>());
    });
  });
}
