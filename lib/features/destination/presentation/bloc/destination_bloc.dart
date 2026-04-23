import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/security/device_id_service.dart';
import '../../domain/model/destination_model.dart';
import '../../domain/model/vote_config_model.dart';
import '../../domain/repository/destination_repository.dart';
import 'destination_event.dart';
import 'destination_state.dart';

class DestinationBloc extends Bloc<DestinationEvent, DestinationState> {
  final DestinationRepository _repository;
  final DeviceIdService? _deviceIdService;

  VoteMode? _pendingMode;

  DestinationBloc(this._repository, {DeviceIdService? deviceIdService})
      : _deviceIdService = deviceIdService,
        super(const DestinationState.initial()) {
    on<LoadDestinations>(_onLoad, transformer: droppable());
    on<ProposeDestination>(_onPropose, transformer: droppable());
    on<LoadVoteConfig>(_onLoadVoteConfig, transformer: droppable());
    on<UpdateVoteConfig>(_onUpdateVoteConfig, transformer: droppable());
    // sequential() — rapid successive taps must be processed in order.
    on<CastVote>(_onCastVote, transformer: sequential());
    on<RetractVote>(_onRetractVote, transformer: sequential());
  }

  Future<void> _onLoad(
    LoadDestinations event,
    Emitter<DestinationState> emit,
  ) async {
    final snapshot = _currentLoaded();
    final preservedMode = snapshot?.mode ?? _pendingMode;
    final preservedMyDeviceId = snapshot?.myDeviceId;

    if (snapshot == null) {
      emit(const DestinationState.loading());
    }
    try {
      final destinations = await _repository.list(event.tripId);
      final myDeviceId = preservedMyDeviceId ??
          await _deviceIdService?.getOrCreateDeviceId();
      emit(DestinationState.loaded(
        destinations: destinations,
        mode: preservedMode ?? _pendingMode,
        myDeviceId: myDeviceId,
      ));
    } catch (e) {
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
        emit(DestinationState.loaded(
          destinations: snapshot.destinations,
          mode: config.mode,
          myDeviceId: snapshot.myDeviceId,
        ));
      }
      // else: destinations still loading. The mode will be applied when
      // LoadDestinations completes via `_pendingMode`.
    } catch (e) {
      // Non-fatal: server falls back to SIMPLE. Do not overwrite a valid
      // loaded destinations list with an error state.
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
    try {
      final config =
          await _repository.updateVoteConfig(event.tripId, event.mode);
      final snapshot = _currentLoaded();
      if (snapshot == null || snapshot.mode != config.mode) {
        emit(DestinationState.loaded(
          destinations: snapshot?.destinations ?? const [],
          mode: config.mode,
          myDeviceId: snapshot?.myDeviceId,
        ));
      }
      // Server may have nulled ranks on transition — refresh aggregates.
      add(LoadDestinations(event.tripId));
    } catch (e) {
      emit(DestinationState.error(message: _friendlyMessage(e)));
    }
  }

  Future<void> _onCastVote(
    CastVote event,
    Emitter<DestinationState> emit,
  ) async {
    try {
      await _repository.castVote(event.destinationId, rank: event.rank);
      add(LoadDestinations(event.tripId));
    } catch (e) {
      emit(DestinationState.error(message: _friendlyMessage(e)));
    }
  }

  Future<void> _onRetractVote(
    RetractVote event,
    Emitter<DestinationState> emit,
  ) async {
    try {
      await _repository.retractVote(event.destinationId);
      add(LoadDestinations(event.tripId));
    } catch (e) {
      emit(DestinationState.error(message: _friendlyMessage(e)));
    }
  }

  _LoadedSnapshot? _currentLoaded() {
    return state.whenOrNull(
      loaded: (destinations, mode, myDeviceId) => _LoadedSnapshot(
        destinations: destinations,
        mode: mode,
        myDeviceId: myDeviceId,
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
}

class _LoadedSnapshot {
  final List<DestinationModel> destinations;
  final VoteMode? mode;
  final String? myDeviceId;

  const _LoadedSnapshot({
    required this.destinations,
    this.mode,
    this.myDeviceId,
  });
}
