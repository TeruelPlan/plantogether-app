import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../constants/route_constants.dart';
import '../security/device_id_service.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/page/profile_page.dart';
import '../../features/profile/domain/repository/profile_repository.dart';
import '../../features/profile/presentation/bloc/settings_bloc.dart';
import '../../features/profile/presentation/page/settings_page.dart';
import '../../features/trip/domain/model/trip_model.dart';
import '../../features/trip/domain/repository/trip_repository.dart';
import '../../features/trip/presentation/bloc/create_trip_bloc.dart';
import '../../features/trip/presentation/bloc/invite_bloc.dart';
import '../../features/trip/presentation/bloc/invite_event.dart';
import '../../features/trip/presentation/bloc/join_trip_bloc.dart';
import '../../features/trip/presentation/bloc/join_trip_event.dart';
import '../../features/trip/presentation/pages/create_trip_page.dart';
import '../../features/trip/presentation/pages/invite_page.dart';
import '../../features/trip/presentation/pages/trip_preview_page.dart';
import '../../features/trip/presentation/pages/trip_workspace_page.dart';

class _OnboardingNotifier extends ChangeNotifier {
  final DeviceIdService _svc;
  bool _initialized = false;
  bool _needsOnboarding = false;
  String? _pendingDeepLink;

  _OnboardingNotifier(this._svc) {
    _initialize();
  }

  bool get initialized => _initialized;
  bool get needsOnboarding => _needsOnboarding;
  String? get pendingDeepLink => _pendingDeepLink;

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

  void savePendingDeepLink(String path) {
    _pendingDeepLink = path;
  }

  void markOnboardingComplete() {
    _needsOnboarding = false;
    notifyListeners();
  }

  String? consumePendingDeepLink() {
    final link = _pendingDeepLink;
    _pendingDeepLink = null;
    return link;
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
          builder: (ctx, state) => const HomePage(),
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
          path: RouteConstants.invite,
          name: 'invite',
          builder: (ctx, state) {
            final tripId = state.pathParameters['id']!;
            final tripName = state.extra as String? ?? 'Trip';
            return BlocProvider(
              create: (ctx) => InviteBloc(ctx.read<TripRepository>())
                ..add(LoadInvitation(tripId: tripId)),
              child: InvitePage(tripId: tripId, tripName: tripName),
            );
          },
        ),
        GoRoute(
          path: RouteConstants.tripPreview,
          name: 'tripPreview',
          builder: (ctx, state) {
            final tripId = state.pathParameters['id']!;
            final token = state.uri.queryParameters['token'] ?? '';
            if (token.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('Invalid invite link — no token provided.')),
              );
            }
            return BlocProvider(
              create: (ctx) => JoinTripBloc(ctx.read<TripRepository>())
                ..add(LoadPreview(tripId: tripId, token: token)),
              child: TripPreviewPage(tripId: tripId, token: token),
            );
          },
        ),
        GoRoute(
          path: RouteConstants.tripWorkspace,
          name: 'tripWorkspace',
          builder: (ctx, state) {
            final tripId = state.pathParameters['id']!;
            final trip = state.extra as TripModel?;
            final deviceIdService = ctx.read<DeviceIdService>();
            return FutureBuilder<String>(
              future: deviceIdService.getOrCreateDeviceId(),
              builder: (context, snapshot) {
                final deviceId = snapshot.data;
                final isOrganizer = trip != null &&
                    deviceId != null &&
                    trip.createdBy == deviceId;
                return TripWorkspacePage(
                  tripId: tripId,
                  tripTitle: trip?.title ?? 'Trip',
                  isOrganizer: isOrganizer,
                );
              },
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
      if (path != RouteConstants.splash) {
        _notifier.savePendingDeepLink(state.uri.toString());
      }
      return RouteConstants.onboarding;
    }
    if (!_notifier.needsOnboarding && path == RouteConstants.onboarding) {
      return _notifier.consumePendingDeepLink() ?? RouteConstants.home;
    }
    return null;
  }
}
