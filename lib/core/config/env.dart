import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads configuration from the `.env` file at the project root.
///
/// Values are loaded once in `main()` with `Env.load()`.
class Env {
  const Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// False while `.env` still has the placeholder values from `.env.example`.
  static bool get isSupabaseConfigured =>
      supabaseUrl.startsWith('https://') &&
      !supabaseUrl.contains('your-project-id') &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'your-anon-public-key';
}
