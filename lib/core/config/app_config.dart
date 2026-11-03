/// Build-time switches.
///
/// Start the app with `flutter run --dart-define=DEMO=true` to run it on
/// built-in demo data. No Supabase account is needed: it is meant for
/// screenshots, interviews and trying the UI offline.
class AppConfig {
  const AppConfig._();

  static const bool demo = bool.fromEnvironment('DEMO');
}
