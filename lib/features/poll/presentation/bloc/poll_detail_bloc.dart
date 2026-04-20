import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/stomp_client_manager.dart';
import '../../../../core/security/device_id_service.dart';
import '../../domain/model/poll_model.dart';
import '../../domain/repository/poll_repository.dart';
import '../widgets/date_poll_matrix_widget.dart';
import 'poll_detail_event.dart';
import 'poll_detail_state.dart';

class PollDetailBloc extends Bloc<PollDetailEvent, PollDetailState> {
  final PollRepository _repository;
  final DeviceIdService _deviceIdService;
  final StompClientManager _stompClientManager;

  String? _pollId;
  TripStompSubscription? _stompSubscription;
  StreamSubscription<StompConnectionState>? _connectionSubscription;
  StompConnectionState? _previousConnectionState;

  PollDetailBloc(
    this._repository,
    this._deviceIdService,
    this._stompClientManager,
  ) : super(const PollDetailState.initial()) {
    on<LoadPollDetail>(_onLoadPollDetail, transformer: droppable());
    on<CastVote>(_onCastVote, transformer: sequential());
    on<TripUpdateReceived>(_onTripUpdateReceived);
    on<ConnectionStateChanged>(_onConnectionStateChanged);
  }

  Future<void> _onLoadPollDetail(
      LoadPollDetail event, Emitter<PollDetailState> emit) async {
    final alreadyLoaded = _currentLoaded() != null && _pollId == event.pollId;
    if (!alreadyLoaded) {
      emit(const PollDetailState.loading());
    }
    try {
      _pollId = event.pollId;
      final detail = await _repository.getPollDetail(event.pollId);
      final myDeviceId = await _deviceIdService.getOrCreateDeviceId();
      emit(PollDetailState.loaded(detail: detail, myDeviceId: myDeviceId));
      await _ensureStompSubscription(detail.tripId);
    } catch (e) {
      emit(PollDetailState.error(message: e.toString()));
    }
  }

  Future<void> _ensureStompSubscription(String tripId) async {
    if (_stompSubscription != null) return;
    final subscription = await _stompClientManager.connect(
      endpointPath: '/ws-poll',
      tripId: tripId,
      onTripUpdate: (payload) => add(TripUpdateReceived(payload)),
    );
    _stompSubscription = subscription;
    _connectionSubscription = subscription.connectionState
        .listen((state) => add(ConnectionStateChanged(state)));
  }

  void _onTripUpdateReceived(
      TripUpdateReceived event, Emitter<PollDetailState> emit) {
    final loaded = _currentLoaded();
    if (loaded == null || _pollId == null) return;

    final payload = event.payload;
    if (payload['pollId'] != _pollId) return;
    if (payload['type'] != 'POLL_VOTE_CAST') {
      // Forward-compat: any other known/unknown event type (e.g. POLL_LOCKED in 3-4) triggers a full refresh.
      add(LoadPollDetail(_pollId!));
      return;
    }

    final slotId = payload['slotId'] as String?;
    final remoteDeviceId = payload['deviceId'] as String?;
    final statusRaw = payload['status'] as String?;
    final newSlotScore = (payload['newSlotScore'] as num?)?.toInt();
    if (slotId == null ||
        remoteDeviceId == null ||
        statusRaw == null ||
        newSlotScore == null) {
      return;
    }

    final remoteStatus = _voteStatusFromWire(statusRaw);
    if (remoteStatus == null) return;

    final isOwnEcho = remoteDeviceId == loaded.myDeviceId;
    PollSlotDetailModel? affectedSlot;
    for (final s in loaded.detail.slots) {
      if (s.id == slotId) {
        affectedSlot = s;
        break;
      }
    }
    if (affectedSlot == null) return;

    if (isOwnEcho && affectedSlot.score == newSlotScore) {
      // Optimistic update already matches the server; nothing to reconcile.
      return;
    }

    final updatedSlots = loaded.detail.slots.map((slot) {
      if (slot.id != slotId) return slot;
      final withoutVoter =
          slot.votes.where((v) => v.deviceId != remoteDeviceId).toList();
      final updatedVotes = [
        ...withoutVoter,
        PollVoteModel(deviceId: remoteDeviceId, status: remoteStatus),
      ];
      return slot.copyWith(votes: updatedVotes, score: newSlotScore);
    }).toList();

    emit(PollDetailState.loaded(
      detail: loaded.detail.copyWith(slots: updatedSlots),
      myDeviceId: loaded.myDeviceId,
      errorBanner: loaded.errorBanner,
      connectionBanner: loaded.connectionBanner,
    ));
  }

  void _onConnectionStateChanged(
      ConnectionStateChanged event, Emitter<PollDetailState> emit) {
    final loaded = _currentLoaded();
    final prev = _previousConnectionState;
    _previousConnectionState = event.connectionState;
    if (loaded == null) return;

    switch (event.connectionState) {
      case StompConnectionState.connecting:
        return;
      case StompConnectionState.connected:
        // Only trigger a re-sync when recovering from an actual outage (reconnecting/disconnected),
        // not on the initial CONNECT right after first subscribe (the page already fetched the detail).
        final recovering = prev == StompConnectionState.reconnecting ||
            prev == StompConnectionState.disconnected;
        if (recovering && _pollId != null) {
          add(LoadPollDetail(_pollId!));
        }
        if (loaded.connectionBanner == null) return;
        emit(PollDetailState.loaded(
          detail: loaded.detail,
          myDeviceId: loaded.myDeviceId,
          errorBanner: loaded.errorBanner,
        ));
        return;
      case StompConnectionState.reconnecting:
      case StompConnectionState.disconnected:
        if (loaded.connectionBanner == 'Reconnecting…') return;
        emit(PollDetailState.loaded(
          detail: loaded.detail,
          myDeviceId: loaded.myDeviceId,
          errorBanner: loaded.errorBanner,
          connectionBanner: 'Reconnecting…',
        ));
        return;
      case StompConnectionState.rejected:
        // Terminal authorization failure (server sent STOMP ERROR frame).
        emit(PollDetailState.loaded(
          detail: loaded.detail,
          myDeviceId: loaded.myDeviceId,
          errorBanner: 'You lost access to this trip',
          connectionBanner: 'Offline — tap to retry',
        ));
        return;
    }
  }

  Future<void> _onCastVote(
      CastVote event, Emitter<PollDetailState> emit) async {
    final loaded = _currentLoaded();
    if (loaded == null || _pollId == null) return;

    PollSlotDetailModel? previousSlot;
    for (final s in loaded.detail.slots) {
      if (s.id == event.slotId) {
        previousSlot = s;
        break;
      }
    }
    if (previousSlot == null) return;

    final optimistic = _applyOptimisticVote(
      loaded.detail,
      slotId: event.slotId,
      myDeviceId: loaded.myDeviceId,
      status: event.status,
    );
    emit(PollDetailState.loaded(
      detail: optimistic,
      myDeviceId: loaded.myDeviceId,
      connectionBanner: loaded.connectionBanner,
    ));

    try {
      await _repository.respond(
        pollId: _pollId!,
        slotId: event.slotId,
        status: event.status,
      );
    } on DioException catch (error, stackTrace) {
      debugPrint('CastVote failed (${error.response?.statusCode}): $error');
      debugPrintStack(stackTrace: stackTrace);
      if (emit.isDone) return;
      _emitPerSlotRollback(emit, previousSlot,
          banner: _bannerForStatus(error.response?.statusCode, previousSlot));
    } catch (error, stackTrace) {
      debugPrint('CastVote failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (emit.isDone) return;
      _emitPerSlotRollback(emit, previousSlot,
          banner: 'Could not save vote for ${_slotLabel(previousSlot)}');
    }
  }

  void _emitPerSlotRollback(
    Emitter<PollDetailState> emit,
    PollSlotDetailModel previousSlot, {
    required String banner,
  }) {
    final loaded = _currentLoaded();
    if (loaded == null) return;
    final restored = loaded.detail.copyWith(
      slots: loaded.detail.slots
          .map((s) => s.id == previousSlot.id ? previousSlot : s)
          .toList(),
    );
    emit(PollDetailState.loaded(
      detail: restored,
      myDeviceId: loaded.myDeviceId,
      errorBanner: banner,
      connectionBanner: loaded.connectionBanner,
    ));
  }

  String _bannerForStatus(int? statusCode, PollSlotDetailModel slot) {
    switch (statusCode) {
      case 409:
        return 'Poll is already locked';
      case 403:
        return 'You are not a member of this trip';
      default:
        return 'Could not save vote for ${_slotLabel(slot)}';
    }
  }

  String _slotLabel(PollSlotDetailModel slot) =>
      DatePollMatrixWidget.formatSlotLabel(slot);

  PollDetailModel _applyOptimisticVote(
    PollDetailModel detail, {
    required String slotId,
    required String myDeviceId,
    required VoteStatus status,
  }) {
    final updatedSlots = detail.slots.map((slot) {
      if (slot.id != slotId) return slot;
      final withoutMine =
          slot.votes.where((v) => v.deviceId != myDeviceId).toList();
      final updatedVotes = [
        ...withoutMine,
        PollVoteModel(deviceId: myDeviceId, status: status),
      ];
      final score = _computeScore(updatedVotes);
      return slot.copyWith(votes: updatedVotes, score: score);
    }).toList();
    return detail.copyWith(slots: updatedSlots);
  }

  int _computeScore(List<PollVoteModel> votes) {
    int score = 0;
    for (final v in votes) {
      if (v.status == VoteStatus.yes) {
        score += 2;
      } else if (v.status == VoteStatus.maybe) {
        score += 1;
      }
    }
    return score;
  }

  VoteStatus? _voteStatusFromWire(String raw) {
    try {
      return VoteStatus.values.byName(raw.toLowerCase());
    } on ArgumentError {
      return null;
    }
  }

  _LoadedHelper? _currentLoaded() {
    return state.whenOrNull(
      loaded: (detail, myDeviceId, errorBanner, connectionBanner) =>
          _LoadedHelper(detail, myDeviceId, errorBanner, connectionBanner),
    );
  }

  @override
  Future<void> close() async {
    await _connectionSubscription?.cancel();
    _stompSubscription?.disconnect();
    return super.close();
  }
}

class _LoadedHelper {
  final PollDetailModel detail;
  final String myDeviceId;
  final String? errorBanner;
  final String? connectionBanner;

  _LoadedHelper(
      this.detail, this.myDeviceId, this.errorBanner, this.connectionBanner);
}
