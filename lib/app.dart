import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_settings.dart';
import 'core/di/injection.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

/// The root widget: theme, translations, router and the shared AuthCubit.
class ScanDeskApp extends StatefulWidget {
  const ScanDeskApp({super.key});

  @override
  State<ScanDeskApp> createState() => _ScanDeskAppState();
}

class _ScanDeskAppState extends State<ScanDeskApp> {
  // One AuthCubit for the whole app; the router listens to it.
  // `..checkSession()` reads the saved login as soon as the app starts.
  final AuthCubit _authCubit = sl<AuthCubit>()..checkSession();
  late final GoRouter _router = AppRouter(_authCubit).router;

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          AppSettings.themeMode,
          AppSettings.locale,
        ]),
        builder: (context, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: AppSettings.themeMode.value,
          locale: AppSettings.locale.value,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
        ),
      ),
    );
  }
}
