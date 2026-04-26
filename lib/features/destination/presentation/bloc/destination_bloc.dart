import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/stomp_client_manager.dart';
import '../../../../core/security/device_id_service.dart';
import '../../domain/model/destination_model.dart';
import '../../domain/model/vote_config_model.dart';
import '../../domain/repository/destination_repository.dart';
import 'destination_event.dart';
import 'destination_state.dart';

const Duration _kReloadDebounce = Duration(milliseconds: 250);

/// Kept local to avoid pulling in `stream_transform` just for this transformer.
EventTransformer<E> _debounce<E>(Duration duration) {
  return (events, mapper) {
    final controller = StreamController<E>();
    Timer? timer;
    E? pending;

    final subscription = events.listen(
      (event) {
        pending = event;
        timer?.cancel();
        timer = Timer(duration, () {
          final value = pending;
          pending = null;
          if (value != null) controller.add(value);
        });
      },
      onError: controller.addError,
      onDone: () {
        // Drop the pending event: the upstream is closing (bloc.close), so
        // dispatching would post on a closed bloc and throw StateError.
        timer?.cancel();
        pending = null;
        controller.close();
      },
    );
    controller.onCancel = () async {
      timer?.cancel();
      await subscription.cancel();
    };
    return controller.stream.asyncExpand(mapper);
  };
}

class DestinationBloc extends Bloc<DestinationEvent, DestinationState> {
  final DestinationRepository _repository;
  final DeviceIdService? _deviceIdService;
  final StompClientManager? _stompClientManager;

  VoteMode? _pendingMode;
  String? _currentTripId;
  String? _subscribedTripId;
  TripStompSubscription? _stompSubscription;
  StreamSubscription<StompConnectionState>? _connectionSubscription;
  StompConnectionState? _previousConnectionState;

  DestinationBloc(
    this._repository, {
    DeviceIdService? deviceIdService,
    StompClientManager? stompClientManager,
  })  : _deviceIdService = deviceIdService,
        _stompClientManager = stompClientManager,
        super(const DestinationState.initial()) {
    on<LoadDestinations>(_onLoad, transformer: droppable());
    on<ProposeDestination>(_onPropose, transformer: droppable());
    on<LoadVoteConfig>(_onLoadVoteConfig, transformer: droppable());
    on<UpdateVoteConfig>(_onUpdateVoteConfig, transformer: droppable());
    on<CastVote>(_onCastVote, transformer: sequential());
    on<RetractVote>(_onRetractVote, transformer: sequential());
    on<SelectDestination>(_onSelectDestination, transformer: droppable());
    on<TripUpdateReceived>(_onTripUpdateReceived);
    on<ConnectionStateChanged>(_onConnectionStateChanged,
        transformer: sequential());
    on<DebouncedReload>(_onDebouncedReload,
        transformer: _debounce(_kReloadDebounce));
  }

  Future<void> _onLoad(
    LoadDestinations event,
    Emitter<DestinationState> emit,
  ) async {
    _currentTripId = event.tripId;
    final snapshot = _currentLoaded();
    final preservedMode = snapshot?.mode ?? _pendingMode;
    final preservedMyDeviceId = snapshot?.myDeviceId;
    final preservedBanner = snapshot?.connectionBanner;

    if (snapshot == null) {
      emit(const DestinationState.loading());
    }
    try {
      final destinations = await _repository.list(event.tripId);
      if (emit.isDone) return;
      final myDeviceId = preservedMyDeviceId ??
          await _deviceIdService?.getOrCreateDeviceId();
      if (emit.isDone) return;
      emit(DestinationState.loaded(
        destinations: destinations,
        mode: preservedMode ?? _pendingMode,
        myDeviceId: myDeviceId,
        connectionBanner: preservedBanner,
      ));
      await _ensureStompSubscription(event.tripId);
    } catch (e) {
      if (emit.isDone) return;
      emit(DestinationState.error(message: _friendlyMessage(e)));
    }
  }

  Future<void> _onPropose(
    ProposeDestination event,
    Emitter<DestinationState> emit,
  ) async {
    try {
      await _repository.propose(event.tripId, event.input);
      add(LoadDestinations(event.tripId));
    } catch (e) {
      emit(DestinationState.error(message: _friendlyMessage(e)));
    }
  }

  Future<void> _onLoadVoteConfig(
    LoadVoteConfig event,
    Emitter<DestinationState> emit,
  ) async {
    try {
      final config = await _repository.getVoteConfig(event.tripId);
      _pendingMode = config.mode;
      final snapshot = _currentLoaded();
      if (snapshot != null && snapshot.mode != config.mode) {
        emit(snapshot.toState(mode: config.mode));
      }
    } catch (e) {
      final snapshot = _currentLoaded();
      if (snapshot == null) {
        emit(DestinationState.error(message: _friendlyMessage(e)));
      }
    }
  }

  Future<void> _onUpdateVoteConfig(
    UpdateVoteConfig event,
    Emitter<DestinationState> emit,
  ) async {
    await _runWithRecovery(event.tripId, emit, () async {
      final config =
          await _repository.updateVoteConfig(event.tripId, event.mode);
      final snapshot = _currentLoaded();
      if (snapshot != null && snapshot.mode != config.mode) {
        emit(snapshot.toState(mode: config.mode));
      }
    });
  }

  Future<void> _onCastVote(
    CastVote event,
    Emitter<DestinationState> emit,
  ) async {
    await _runWithRecovery(event.tripId, emit, () async {
      await _repository.castVote(event.destinationId, rank: event.rank);
    });
  }

  Future<void> _onRetractVote(
    RetractVote event,
    Emitter<DestinationState> emit,
  ) async {
    await _runWithRecovery(event.tripId, emit, () async {
      await _repository.retractVote(event.destinationId);
    });
  }

  Future<void> _onSelectDestination(
    SelectDestination event,
    Emitter<DestinationState> emit,
  ) async {
    try {
      await _repository.selectDestination(event.destinationId);
      add(LoadDestinations(event.tripId));
    } on DioException catch (e) {
      final snapshot = _currentLoaded();
      final message = e.response?.statusCode == 409
          ? 'Destination already chosen for this trip.'
          : _friendlyMessage(e);
      if (snapshot != null) {
        emit(snapshot.toState(transientError: message));
      } else {
        emit(DestinationState.error(message: message));
      }
    } catch (e) {
      emit(DestinationState.error(message: _friendlyMessage(e)));
    }
  }

  void _onTripUpdateReceived(
    TripUpdateReceived event,
    Emitter<DestinationState> emit,
  ) {
    if (_currentTripId == null) return;
    final payload = event.payload;
    final type = payload['type'];
    final tripId = payload['tripId'];
    if (type is! String || !type.startsWith('DESTINATION_')) return;
    if (tripId is! String || tripId != _currentTripId) return;
    add(DebouncedReload(_currentTripId!));
  }

  Future<void> _onDebouncedReload(
    DebouncedReload event,
    Emitter<DestinationState> emit,
  ) async {
    if (_currentTripId == null || event.tripId != _currentTripId) return;
    try {
      final destinations = await _repository.list(event.tripId);
      if (emit.isDone) return;
      final snapshot = _currentLoaded();
      if (snapshot == null) return;
      // Skip the rebuild when the server aggregate didn't actually change —
      // avoids re-emitting identical loaded states on every echo.
      if (listEquals(destinations, snapshot.destinations)) return;
      emit(snapshot.toState(destinations: destinations));
    } catch (error, stackTrace) {
      // Don't surface as an error state: a transient 5xx during a push-driven
      // reload should not disturb the already-visible list. Log so regressions
      // don't stay hidden.
      debugPrint('DestinationBloc push reload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _onConnectionStateChanged(
    ConnectionStateChanged event,
    Emitter<DestinationState> emit,
  ) {
    final prev = _previousConnectionState;
    _previousConnectionState = event.connectionState;
    final snapshot = _currentLoaded();
    if (snapshot == null) return;

    switch (event.connectionState) {
      case StompConnectionState.connecting:
        return;
      case StompConnectionState.connected:
        final recovering = prev == StompConnectionState.reconnecting ||
            prev == StompConnectionState.disconnected ||
            prev == StompConnectionState.rejected;
        if (recovering && _currentTripId != null) {
          add(LoadDestinations(_currentTripId!));
        }
        if (snapshot.connectionBanner == null) return;
        emit(snapshot.toState(connectionBanner: null));
        return;
      case StompConnectionState.reconnecting:
      case StompConnectionState.disconnected:
        if (snapshot.connectionBanner == _kBannerReconnecting) return;
        emit(snapshot.toState(connectionBanner: _kBannerReconnecting));
        return;
      case StompConnectionState.rejected:
        if (snapshot.connectionBanner == _kBannerOffline) return;
        emit(snapshot.toState(connectionBanner: _kBannerOffline));
        return;
    }
  }

  Future<void> _ensureStompSubscription(String tripId) async {
    if (_stompClientManager == null) return;
    if (_stompSubscription != null && _subscribedTripId == tripId) return;

    await _connectionSubscription?.cancel();
    _stompSubscription?.disconnect();
    _stompSubscription = null;
    _connectionSubscription = null;
    _previousConnectionState = null;

    final subscription = await _stompClientManager.connect(
      endpointPath: '/ws',
      tripId: tripId,
      onTripUpdate: (payload) => add(TripUpdateReceived(payload)),
    );
    if (isClosed) {
      subscription.disconnect();
      return;
    }
    _stompSubscription = subscription;
    _subscribedTripId = tripId;
    _connectionSubscription = subscription.connectionState
        .listen((state) => add(ConnectionStateChanged(state)));
  }

  Future<void> _runWithRecovery(
    String tripId,
    Emitter<DestinationState> emit,
    Future<void> Function() body,
  ) async {
    final hadSnapshot = _currentLoaded() != null;
    try {
      await body();
      add(LoadDestinations(tripId));
    } catch (e) {
      emit(DestinationState.error(message: _friendlyMessage(e)));
      if (hadSnapshot) {
        add(LoadDestinations(tripId));
      }
    }
  }

  _LoadedSnapshot? _currentLoaded() {
    return state.whenOrNull(
      loaded: (destinations, mode, myDeviceId, connectionBanner,
              transientError) =>
          _LoadedSnapshot(
        destinations: destinations,
        mode: mode,
        myDeviceId: myDeviceId,
        connectionBanner: connectionBanner,
      ),
    );
  }

  String _friendlyMessage(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 403) return 'You are not a member of this trip.';
      if (status == 400) return 'Please check the form fields and try again.';
      if (status != null && status >= 500) {
        return 'Server unavailable. Please try again later.';
      }
      return 'Network error. Please check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Future<void> close() async {
    await _connectionSubscription?.cancel();
    _stompSubscription?.disconnect();
    return super.close();
  }
}

const String _kBannerReconnecting = 'Reconnecting…';
const String _kBannerOffline = 'Offline — tap to retry';
const Object _kNoChange = Object();

class _LoadedSnapshot {
  final List<DestinationModel> destinations;
  final VoteMode? mode;
  final String? myDeviceId;
  final String? connectionBanner;

  const _LoadedSnapshot({
    required this.destinations,
    this.mode,
    this.myDeviceId,
    this.connectionBanner,
  });

  /// Rebuild the public state variant, overriding only the provided fields.
  /// Pass `connectionBanner: null` to clear — omit it to keep the current
  /// value (a nullable override needs the sentinel trick).
  DestinationState toState({
    List<DestinationModel>? destinations,
    VoteMode? mode,
    String? myDeviceId,
    Object? connectionBanner = _kNoChange,
    String? transientError,
  }) {
    return DestinationState.loaded(
      destinations: destinations ?? this.destinations,
      mode: mode ?? this.mode,
      myDeviceId: myDeviceId ?? this.myDeviceId,
      connectionBanner: identical(connectionBanner, _kNoChange)
          ? this.connectionBanner
          : connectionBanner as String?,
      transientError: transientError,
    );
  }
}
