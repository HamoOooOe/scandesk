import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/users/data/users_repository_impl.dart';
import '../../features/users/domain/users_repository.dart';
import '../../features/users/presentation/cubit/users_cubit.dart';
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

  // The repository is registered by its interface, so everything else
  // depends on `AuthRepository`, never on the Supabase class.
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl()));

  sl.registerLazySingleton<UsersRepository>(() => UsersRepositoryImpl(sl()));
  // Factory: every time the users screen opens it gets a fresh cubit.
  sl.registerFactory<UsersCubit>(() => UsersCubit(sl()));
}
