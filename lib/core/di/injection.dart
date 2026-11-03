import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/assets/data/assets_repository_impl.dart';
import '../../features/assets/domain/assets_repository.dart';
import '../../features/assets/presentation/cubit/asset_detail_cubit.dart';
import '../../features/assets/presentation/cubit/asset_form_cubit.dart';
import '../../features/assets/presentation/cubit/assets_list_cubit.dart';
import '../../features/assets/presentation/cubit/sites_cubit.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/qr/presentation/cubit/scan_cubit.dart';
import '../../features/tickets/data/tickets_repository_impl.dart';
import '../../features/tickets/domain/tickets_repository.dart';
import '../../features/tickets/presentation/cubit/report_cubit.dart';
import '../../features/tickets/presentation/cubit/ticket_detail_cubit.dart';
import '../../features/tickets/presentation/cubit/tickets_cubit.dart';
import '../../features/users/data/users_repository_impl.dart';
import '../../features/users/domain/users_repository.dart';
import '../../features/users/presentation/cubit/users_cubit.dart';
import '../config/app_config.dart';
import '../config/env.dart';
import '../demo/demo_repositories.dart';
import '../demo/demo_store.dart';

/// Global service locator. Widgets never call constructors of
/// repositories or cubits directly; they ask `sl` for them.
final GetIt sl = GetIt.instance;

/// Registers everything the app needs. Called once in `main()`.
///
/// Rule of thumb:
///  - registerLazySingleton: one shared instance (clients, repositories,
///    app-wide cubits like AuthCubit)
///  - registerFactory: a new instance every time (screen-level cubits)
///
/// In demo mode (`--dart-define=DEMO=true`) every repository is the
/// in-memory version over seeded data. Nothing else in the app changes,
/// which is the point of programming against interfaces.
void configureDependencies({bool demo = AppConfig.demo}) {
  if (demo) {
    _registerDemoRepositories();
  } else {
    _registerSupabaseRepositories();
  }

  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl()));
  sl.registerLazySingleton<SeenTickets>(SeenTickets.new);

  // Factories: every time a screen opens it gets a fresh cubit.
  sl.registerFactory<UsersCubit>(() => UsersCubit(sl()));
  sl.registerFactory<AssetsListCubit>(() => AssetsListCubit(sl(), sl()));
  sl.registerFactory<AssetDetailCubit>(() => AssetDetailCubit(sl(), sl(), sl()));
  sl.registerFactory<AssetFormCubit>(() => AssetFormCubit(sl(), sl()));
  sl.registerFactory<SitesCubit>(() => SitesCubit(sl()));
  sl.registerFactory<TicketsCubit>(() => TicketsCubit(sl(), sl()));
  sl.registerFactory<TicketDetailCubit>(() => TicketDetailCubit(sl()));
  sl.registerFactory<ReportCubit>(() => ReportCubit(sl(), sl()));
  sl.registerFactory<ScanCubit>(() => ScanCubit(sl()));
  sl.registerFactory<DashboardCubit>(() => DashboardCubit(sl(), sl()));
}

void _registerSupabaseRepositories() {
  if (Env.isSupabaseConfigured) {
    sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  }
  // Each repository is registered by its interface, so everything else
  // depends on the contract, never on the Supabase class.
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<UsersRepository>(() => UsersRepositoryImpl(sl()));
  sl.registerLazySingleton<AssetsRepository>(() => AssetsRepositoryImpl(sl()));
  sl.registerLazySingleton<SitesRepository>(() => SitesRepositoryImpl(sl()));
  sl.registerLazySingleton<TicketsRepository>(() => TicketsRepositoryImpl(sl()));
}

void _registerDemoRepositories() {
  sl.registerLazySingleton<DemoStore>(DemoStore.new);
  sl.registerLazySingleton<DemoAuthRepository>(DemoAuthRepository.new);
  sl.registerLazySingleton<AuthRepository>(() => sl<DemoAuthRepository>());
  sl.registerLazySingleton<UsersRepository>(() => DemoUsersRepository(sl()));
  sl.registerLazySingleton<AssetsRepository>(() => DemoAssetsRepository(sl()));
  sl.registerLazySingleton<SitesRepository>(() => DemoSitesRepository(sl()));
  sl.registerLazySingleton<TicketsRepository>(
    () => DemoTicketsRepository(sl(), sl()),
  );
}
