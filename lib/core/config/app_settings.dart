import 'package:flutter/material.dart';

/// Theme and language chosen by the user.
///
/// Sprint 0 version: kept in memory only (resets when the app restarts).
/// Later: replace with a SettingsCubit saved with shared_preferences.
class AppSettings {
  const AppSettings._();

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.system,
  );

  /// null = follow the phone's language.
  static final ValueNotifier<Locale?> locale = ValueNotifier(null);
}
