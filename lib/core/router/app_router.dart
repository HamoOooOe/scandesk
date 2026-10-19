import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import 'go_router_refresh_stream.dart';
import 'routes.dart';

/// All screens of the app, plus the auth guard.
class AppRouter {
  AppRouter(this._authCubit);

  final AuthCubit _authCubit;

  /// Screens a logged-out user may open.
  static const _publicRoutes = {Routes.login};

  late final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    // Re-run `redirect` every time the auth state changes.
    refreshListenable: GoRouterRefreshStream(_authCubit.stream),
    redirect: _redirect,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(path: Routes.home, builder: (context, state) => const HomePage()),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final authState = _authCubit.state;

    // Still reading the saved session: wait on the splash screen.
    if (authState is AuthInitial) {
      return location == Routes.splash ? null : Routes.splash;
    }

    // Login request in progress: stay where we are.
    if (authState is Authenticating) return null;

    if (authState is Authenticated) {
      final isEntryScreen =
          location == Routes.splash || _publicRoutes.contains(location);
      return isEntryScreen ? Routes.home : null;
    }

    // Unauthenticated or AuthError: only public screens are allowed.
    return _publicRoutes.contains(location) ? null : Routes.login;
  }
}
