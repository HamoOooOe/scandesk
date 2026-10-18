import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import 'routes.dart';

/// All screens of the app.
///
/// Sprint 0: no login yet, the app opens straight on the home screen.
///
/// TODO(S1): add the auth guard. Pass the AuthCubit in, then add:
///   refreshListenable: GoRouterRefreshStream(authCubit.stream),
///   redirect: still checking -> splash, logged out -> login,
///             logged in -> never splash/login again.
/// and add GoRoutes for SplashPage and LoginPage (features/auth).
class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
