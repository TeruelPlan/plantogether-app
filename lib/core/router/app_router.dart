import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../constants/route_constants.dart';
import '../security/device_id_service.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/bloc/home_event.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/page/profile_page.dart';
import '../../features/profile/domain/repository/profile_repository.dart';
import '../../features/profile/presentation/bloc/settings_bloc.dart';
import '../../features/profile/presentation/page/settings_page.dart';
import '../../features/trip/domain/repository/trip_repository.dart';
import '../../features/trip/presentation/bloc/create_trip_bloc.dart';
import '../../features/trip/presentation/bloc/trip_detail_bloc.dart';
import '../../features/trip/presentation/pages/create_trip_page.dart';
import '../../features/trip/presentation/pages/trip_workspace_page.dart';

class _OnboardingNotifier extends ChangeNotifier {
  final DeviceIdService _svc;
  bool _initialized = false;
  bool _needsOnboarding = false;

  _OnboardingNotifier(this._svc) {
    _initialize();
  }

  bool get initialized => _initialized;
  bool get needsOnboarding => _needsOnboarding;

  Future<void> _initialize() async {
    try {
      await _svc.getOrCreateDeviceId();
      _needsOnboarding = await _svc.getDisplayName() == null;
    } catch (_) {
      _needsOnboarding = true; // safe fallback: show onboarding on storage error
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  void markOnboardingComplete() {
    _needsOnboarding = false;
    notifyListeners();
  }
}

class AppRouter {
  late final _OnboardingNotifier _notifier;
  late final GoRouter router;

  AppRouter({required DeviceIdService deviceIdService}) {
    _notifier = _OnboardingNotifier(deviceIdService);
    router = GoRouter(
      refreshListenable: _notifier,
      initialLocation: RouteConstants.splash,
      redirect: _redirect,
      routes: [
        GoRoute(
          path: RouteConstants.splash,
          builder: (ctx, state) => const SplashPage(),
        ),
        GoRoute(
          path: RouteConstants.onboarding,
          builder: (ctx, state) => OnboardingPage(
            onComplete: _notifier.markOnboardingComplete,
          ),
        ),
        GoRoute(
          path: RouteConstants.home,
          builder: (ctx, state) => BlocProvider(
            create: (ctx) =>
                HomeBloc(ctx.read<TripRepository>())..add(const LoadTrips()),
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: RouteConstants.profile,
          name: 'profile',
          builder: (ctx, state) => BlocProvider(
            create: (ctx) => ProfileBloc(ctx.read<ProfileRepository>()),
            child: const ProfilePage(),
          ),
        ),
        GoRoute(
          path: RouteConstants.settings,
          name: 'settings',
          builder: (ctx, state) => BlocProvider(
            create: (ctx) => SettingsBloc(ctx.read<DeviceIdService>()),
            child: const SettingsPage(),
          ),
        ),
        GoRoute(
          path: RouteConstants.createTrip,
          name: 'createTrip',
          builder: (ctx, state) => BlocProvider(
            create: (ctx) => CreateTripBloc(ctx.read<TripRepository>()),
            child: const CreateTripPage(),
          ),
        ),
        GoRoute(
          path: RouteConstants.tripWorkspace,
          name: 'tripWorkspace',
          builder: (ctx, state) {
            final tripId = state.pathParameters['id']!;
            return BlocProvider(
              create: (ctx) => TripDetailBloc(ctx.read<TripRepository>()),
              child: TripWorkspacePage(tripId: tripId),
            );
          },
        ),
      ],
    );
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    if (!_notifier.initialized) return null; // stay on splash until init completes
    final path = state.uri.path;
    if (path == RouteConstants.splash) {
      return _notifier.needsOnboarding
          ? RouteConstants.onboarding
          : RouteConstants.home;
    }
    if (_notifier.needsOnboarding && path != RouteConstants.onboarding) {
      return RouteConstants.onboarding;
    }
    if (!_notifier.needsOnboarding && path == RouteConstants.onboarding) {
      return RouteConstants.home;
    }
    return null;
  }
}
