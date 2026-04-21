import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/stomp_client_manager.dart';
import '../../../../core/security/device_id_service.dart';
import '../../domain/model/poll_model.dart';
import '../../domain/repository/poll_repository.dart';
import '../widgets/date_poll_matrix_widget.dart';
import 'poll_detail_event.dart';
import 'poll_detail_state.dart';

class PollDetailBloc extends Bloc<PollDetailEvent, PollDetailState> {
  static final DateFormat _dateLabelFormat = DateFormat('MMM d');

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
    on<LockPoll>(_onLockPoll, transformer: droppable());
    on<TripUpdateReceived>(_onTripUpdateReceived);
    on<ConnectionStateChanged>(_onConnectionStateChanged);
    on<SuccessBannerConsumed>(_onSuccessBannerConsumed);
    on<ErrorBannerConsumed>(_onErrorBannerConsumed);
  }

  void _onSuccessBannerConsumed(
      SuccessBannerConsumed event, Emitter<PollDetailState> emit) {
    final loaded = _currentLoaded();
    if (loaded == null || loaded.successBanner == null) return;
    emit(loaded.copyWith(clearSuccessBanner: true));
  }

  void _onErrorBannerConsumed(
      ErrorBannerConsumed event, Emitter<PollDetailState> emit) {
    final loaded = _currentLoaded();
    if (loaded == null || loaded.errorBanner == null) return;
    emit(loaded.copyWith(clearErrorBanner: true));
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

    final type = payload['type'];
    if (type == 'POLL_LOCKED') {
      _applyPollLockedFrame(loaded, payload, emit);
      return;
    }
    if (type != 'POLL_VOTE_CAST') {
      // Forward-compat: unknown event type → trigger a full refresh.
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

    emit(loaded.copyWith(
      detail: loaded.detail.copyWith(slots: updatedSlots),
    ));
  }

  void _applyPollLockedFrame(_LoadedSnapshot loaded, Map<String, dynamic> payload,
      Emitter<PollDetailState> emit) {
    final slotId = payload['slotId'] as String?;
    final startDate = payload['startDate'] as String?;
    final endDate = payload['endDate'] as String?;
    if (slotId == null) return;
    if (loaded.detail.status == PollStatus.locked &&
        loaded.detail.lockedSlotId == slotId) {
      return;
    }
    final updatedDetail = loaded.detail.copyWith(
      status: PollStatus.locked,
      lockedSlotId: slotId,
    );
    final banner = _formatDatesBanner(startDate, endDate);
    emit(loaded.copyWith(
      detail: updatedDetail,
      successBanner: banner,
      locking: false,
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
        final recovering = prev == StompConnectionState.reconnecting ||
            prev == StompConnectionState.disconnected;
        if (recovering && _pollId != null) {
          add(LoadPollDetail(_pollId!));
        }
        if (loaded.connectionBanner == null) return;
        emit(loaded.copyWith(clearConnectionBanner: true));
        return;
      case StompConnectionState.reconnecting:
      case StompConnectionState.disconnected:
        if (loaded.connectionBanner == 'Reconnecting…') return;
        emit(loaded.copyWith(connectionBanner: 'Reconnecting…'));
        return;
      case StompConnectionState.rejected:
        emit(loaded.copyWith(
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
    emit(loaded.copyWith(detail: optimistic));

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

  Future<void> _onLockPoll(
      LockPoll event, Emitter<PollDetailState> emit) async {
    final loaded = _currentLoaded();
    if (loaded == null || _pollId == null) return;
    if (loaded.detail.status != PollStatus.open) return;

    emit(loaded.copyWith(locking: true));

    try {
      final updated = await _repository.lockPoll(
        pollId: _pollId!,
        slotId: event.slotId,
      );
      if (emit.isDone) return;
      final winning = updated.slots.firstWhere(
        (s) => s.id == updated.lockedSlotId,
        orElse: () => updated.slots.first,
      );
      emit(loaded.copyWith(
        detail: updated,
        locking: false,
        successBanner: _formatSlotDatesBanner(winning),
      ));
    } on DioException catch (error, stackTrace) {
      debugPrint('LockPoll failed (${error.response?.statusCode}): $error');
      debugPrintStack(stackTrace: stackTrace);
      if (emit.isDone) return;
      final current = _currentLoaded() ?? loaded;
      emit(current.copyWith(
        locking: false,
        errorBanner: _bannerForLockStatus(error.response?.statusCode),
      ));
    } catch (error, stackTrace) {
      debugPrint('LockPoll failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (emit.isDone) return;
      final current = _currentLoaded() ?? loaded;
      emit(current.copyWith(
        locking: false,
        errorBanner: 'Could not lock the poll',
      ));
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
    emit(loaded.copyWith(detail: restored, errorBanner: banner));
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

  String _bannerForLockStatus(int? statusCode) {
    switch (statusCode) {
      case 403:
        return 'Only the organizer can lock this poll';
      case 409:
        return 'Poll is already locked';
      case 400:
        return 'Selected slot does not belong to this poll';
      case 404:
        return 'Poll not found';
      default:
        return 'Could not lock the poll';
    }
  }

  String _slotLabel(PollSlotDetailModel slot) =>
      DatePollMatrixWidget.formatSlotLabel(slot);

  String _formatSlotDatesBanner(PollSlotDetailModel slot) {
    final start = _dateLabelFormat.format(slot.startDate);
    final end = _dateLabelFormat.format(slot.endDate);
    if (start == end) {
      return 'Dates confirmed: $start';
    }
    return 'Dates confirmed: $start–$end';
  }

  String _formatDatesBanner(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) {
      return 'Dates confirmed';
    }
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final s = _dateLabelFormat.format(start);
      final e = _dateLabelFormat.format(end);
      if (s == e) return 'Dates confirmed: $s';
      return 'Dates confirmed: $s–$e';
    } catch (_) {
      return 'Dates confirmed: $startDate–$endDate';
    }
  }

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

  _LoadedSnapshot? _currentLoaded() {
    return state.whenOrNull(
      loaded: (detail, myDeviceId, errorBanner, connectionBanner,
              successBanner, locking) =>
          _LoadedSnapshot(
        detail: detail,
        myDeviceId: myDeviceId,
        errorBanner: errorBanner,
        connectionBanner: connectionBanner,
        successBanner: successBanner,
        locking: locking,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _connectionSubscription?.cancel();
    _stompSubscription?.disconnect();
    return super.close();
  }
}

class _LoadedSnapshot {
  final PollDetailModel detail;
  final String myDeviceId;
  final String? errorBanner;
  final String? connectionBanner;
  final String? successBanner;
  final bool locking;

  const _LoadedSnapshot({
    required this.detail,
    required this.myDeviceId,
    this.errorBanner,
    this.connectionBanner,
    this.successBanner,
    this.locking = false,
  });

  PollDetailState copyWith({
    PollDetailModel? detail,
    String? errorBanner,
    String? connectionBanner,
    String? successBanner,
    bool? locking,
    bool clearConnectionBanner = false,
    bool clearErrorBanner = false,
    bool clearSuccessBanner = false,
  }) {
    return PollDetailState.loaded(
      detail: detail ?? this.detail,
      myDeviceId: myDeviceId,
      errorBanner: clearErrorBanner ? null : (errorBanner ?? this.errorBanner),
      connectionBanner:
          clearConnectionBanner ? null : (connectionBanner ?? this.connectionBanner),
      successBanner:
          clearSuccessBanner ? null : (successBanner ?? this.successBanner),
      locking: locking ?? this.locking,
    );
  }
}
