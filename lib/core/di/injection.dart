import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Global service locator. Widgets never call constructors of
/// repositories or cubits directly; they ask `sl` for them.
final GetIt sl = GetIt.instance;

/// Registers everything the app needs. Called once in `main()`.
///
/// Rule of thumb:
///  - registerLazySingleton: one shared instance (clients, repositories,
///    app-wide cubits like AuthCubit)
///  - registerFactory: a new instance every time (screen-level cubits)
void configureDependencies() {
  if (Env.isSupabaseConfigured) {
    sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  }

  // TODO(S1): register auth (the code already exists in features/auth):
  // sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  // sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl()));
}
