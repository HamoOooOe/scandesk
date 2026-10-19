import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import 'package:scandesk/core/router/app_router.dart';
import 'package:scandesk/core/router/routes.dart';
import 'package:scandesk/features/auth/domain/app_user.dart';
import 'package:scandesk/features/auth/domain/user_role.dart';
import 'package:scandesk/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:scandesk/features/auth/presentation/cubit/auth_state.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

AppUser userWith(UserRole role) => AppUser(
  id: 'u1',
  email: 'a@b.com',
  fullName: 'Test',
  role: role,
);

Future<GoRouter> pumpApp(WidgetTester tester, AuthState state) async {
  final cubit = MockAuthCubit();
  when(() => cubit.state).thenReturn(state);
  final router = AppRouter(cubit).router;
  addTearDown(router.dispose);

  await tester.pumpWidget(
    BlocProvider<AuthCubit>.value(
      value: cubit,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String locationOf(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('logged-out user is sent to login', (tester) async {
    final router = await pumpApp(tester, const Unauthenticated());
    expect(locationOf(router), Routes.login);
  });

  testWidgets('logged-out user cannot open an inner screen', (tester) async {
    final router = await pumpApp(tester, const Unauthenticated());
    router.go(Routes.managerHome);
    await tester.pumpAndSettle();
    expect(locationOf(router), Routes.login);
  });

  testWidgets('while checking the session the splash is shown', (tester) async {
    final cubit = MockAuthCubit();
    when(() => cubit.state).thenReturn(const AuthInitial());
    final router = AppRouter(cubit).router;
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    expect(locationOf(router), Routes.splash);
  });

  for (final role in UserRole.values) {
    testWidgets('${role.name} lands on its own home', (tester) async {
      final router = await pumpApp(tester, Authenticated(userWith(role)));
      expect(locationOf(router), Routes.homeFor(role));
    });
  }

  testWidgets('an employee cannot open the manager home', (tester) async {
    final router = await pumpApp(
      tester,
      Authenticated(userWith(UserRole.employee)),
    );
    router.go(Routes.managerHome);
    await tester.pumpAndSettle();
    expect(locationOf(router), Routes.employeeHome);
  });
}
