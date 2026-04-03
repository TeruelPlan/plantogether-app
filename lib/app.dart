import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/dio_client.dart';
import 'core/network/stomp_client_manager.dart';
import 'core/router/app_router.dart';
import 'core/security/device_id_service.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/data/datasource/profile_remote_datasource.dart';
import 'features/profile/data/repository/profile_repository_impl.dart';
import 'features/profile/domain/repository/profile_repository.dart';

class PlanTogetherApp extends StatelessWidget {
  const PlanTogetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => DeviceIdService()),
        RepositoryProvider(
            create: (ctx) => DioClient(ctx.read<DeviceIdService>())),
        RepositoryProvider(
            create: (ctx) => StompClientManager(ctx.read<DeviceIdService>())),
        RepositoryProvider(
            create: (ctx) =>
                ProfileRemoteDatasource(ctx.read<DioClient>())),
        RepositoryProvider<ProfileRepository>(
            create: (ctx) => ProfileRepositoryImpl(
                ctx.read<ProfileRemoteDatasource>())),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatefulWidget {
  const _AppContent();

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  AppRouter? _appRouter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appRouter ??= AppRouter(deviceIdService: context.read<DeviceIdService>());
  }

  @override
  void dispose() {
    _appRouter?.router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PlanTogether',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _appRouter!.router,
    );
  }
}
