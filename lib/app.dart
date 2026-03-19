import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/dio_client.dart';
import 'core/security/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'core/network/stomp_client_manager.dart';

class PlanTogetherApp extends StatelessWidget {
  const PlanTogetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthService()),
        RepositoryProvider(create: (ctx) => DioClient(ctx.read<AuthService>())),
        RepositoryProvider(create: (ctx) => StompClientManager(ctx.read<AuthService>())),
      ],
      child: MaterialApp.router(
        title: 'PlanTogether',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // routerConfig: AppRouter.router,  // TODO: configure go_router
      ),
    );
  }
}
