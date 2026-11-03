import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/assets/presentation/pages/asset_detail_page.dart';
import '../../features/assets/presentation/pages/asset_form_page.dart';
import '../../features/assets/presentation/pages/sites_page.dart';
import '../../features/auth/domain/user_role.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/employee_home_page.dart';
import '../../features/home/presentation/pages/manager_home_page.dart';
import '../../features/home/presentation/pages/technician_home_page.dart';
import '../../features/qr/presentation/pages/asset_qr_page.dart';
import '../../features/qr/presentation/pages/label_sheet_page.dart';
import '../../features/qr/presentation/pages/scanner_page.dart';
import '../../features/tickets/presentation/pages/report_page.dart';
import '../../features/tickets/presentation/pages/ticket_detail_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
import 'go_router_refresh_stream.dart';
import 'routes.dart';

/// All screens of the app, plus the auth + role guard.
class AppRouter {
  AppRouter(this._authCubit);

  final AuthCubit _authCubit;

  /// Screens a logged-out user may open.
  static const _publicRoutes = {
    Routes.login,
    Routes.register,
    Routes.forgotPassword,
    Routes.resetPassword,
  };

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
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: Routes.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: Routes.employeeHome,
        builder: (context, state) => const EmployeeHomePage(),
      ),
      GoRoute(
        path: Routes.technicianHome,
        builder: (context, state) => const TechnicianHomePage(),
      ),
      GoRoute(
        path: Routes.managerHome,
        builder: (context, state) => const ManagerHomePage(),
        routes: [
          GoRoute(
            path: 'users',
            builder: (context, state) => const UsersPage(),
          ),
        ],
      ),

      // Shared screens, opened on top of a home with `context.push`
      // so the system Back button returns to where the user was.
      GoRoute(
        path: Routes.scan,
        builder: (context, state) => const ScannerPage(),
      ),
      GoRoute(
        path: '/asset/:id',
        builder: (context, state) =>
            AssetDetailPage(assetId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'qr',
            builder: (context, state) =>
                AssetQrPage(assetId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/report/:assetId',
        builder: (context, state) =>
            ReportPage(assetId: state.pathParameters['assetId']!),
      ),
      GoRoute(
        path: '/ticket/:id',
        builder: (context, state) =>
            TicketDetailPage(ticketId: state.pathParameters['id']!),
      ),

      // Manager-only screens (the guard below keeps others out).
      GoRoute(
        path: Routes.assetNew,
        builder: (context, state) => const AssetFormPage(),
      ),
      GoRoute(
        path: '/assets/:id/edit',
        builder: (context, state) =>
            AssetFormPage(assetId: state.pathParameters['id']),
      ),
      GoRoute(
        path: Routes.sites,
        builder: (context, state) => const SitesPage(),
      ),
      GoRoute(
        path: Routes.labelSheet,
        builder: (context, state) => const LabelSheetPage(),
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final authState = _authCubit.state;

    // Still reading the saved session: wait on the splash screen.
    if (authState is AuthInitial) {
      return location == Routes.splash ? null : Routes.splash;
    }

    // The user came from the reset email: they must set a new password.
    if (authState is PasswordRecovery) {
      return location == Routes.resetPassword ? null : Routes.resetPassword;
    }

    // Request in progress: stay where we are.
    if (authState is Authenticating) return null;

    if (authState is Authenticated) {
      final ownHome = Routes.homeFor(authState.user.role);
      final isEntryScreen =
          location == Routes.splash || _publicRoutes.contains(location);
      if (isEntryScreen) return ownHome;

      // A role may only open its own screens.
      final owner = Routes.roleOwning(location);
      if (owner != null && owner != authState.user.role) return ownHome;
      if (Routes.managerOnly(location) &&
          authState.user.role != UserRole.manager) {
        return ownHome;
      }
      return null;
    }

    // Unauthenticated, SignUpSuccess, PasswordResetSent or AuthError:
    // only public screens are allowed.
    return _publicRoutes.contains(location) ? null : Routes.login;
  }
}
