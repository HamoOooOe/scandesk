import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_settings.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// The root widget: theme, translations and router.
///
/// TODO(S1): wrap MaterialApp.router in a BlocProvider for the AuthCubit
/// and pass the cubit to AppRouter.
class ScanDeskApp extends StatefulWidget {
  const ScanDeskApp({super.key});

  @override
  State<ScanDeskApp> createState() => _ScanDeskAppState();
}

class _ScanDeskAppState extends State<ScanDeskApp> {
  late final GoRouter _router = AppRouter().router;

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppSettings.themeMode, AppSettings.locale]),
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
    );
  }
}
