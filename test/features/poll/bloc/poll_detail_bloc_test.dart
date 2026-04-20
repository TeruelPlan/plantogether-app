import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/core/network/stomp_client_manager.dart';
import 'package:plantogether_app/core/security/device_id_service.dart';
import 'package:plantogether_app/features/poll/domain/model/poll_model.dart';
import 'package:plantogether_app/features/poll/domain/repository/poll_repository.dart';
import 'package:plantogether_app/features/poll/presentation/bloc/poll_detail_bloc.dart';
import 'package:plantogether_app/features/poll/presentation/bloc/poll_detail_event.dart';
import 'package:plantogether_app/features/poll/presentation/bloc/poll_detail_state.dart';

class MockPollRepository extends Mock implements PollRepository {}

class MockDeviceIdService extends Mock implements DeviceIdService {}

class FakeStompClientManager implements StompClientManager {
  final StreamController<StompConnectionState> stateController =
      StreamController<StompConnectionState>.broadcast();
  void Function(Map<String, dynamic>)? lastCallback;

  @override
  Future<TripStompSubscription> connect({
    required String endpointPath,
    required String tripId,
    required void Function(Map<String, dynamic>) onTripUpdate,
  }) async {
    lastCallback = onTripUpdate;
    return _FakeSubscription(stateController.stream);
  }
}

class _FakeSubscription implements TripStompSubscription {
  final Stream<StompConnectionState> _stream;
  _FakeSubscription(this._stream);

  @override
  Stream<StompConnectionState> get connectionState => _stream;

  @override
  void disconnect() {}
}

void main() {
  late MockPollRepository mockRepository;
  late MockDeviceIdService mockDeviceIdService;
  late FakeStompClientManager fakeStomp;

  const pollId = 'poll-1';
  const tripId = 'trip-1';
  const myDeviceId = 'device-me';
  const otherDeviceId = 'device-other';
  const slotAId = 'slot-a';
  const slotBId = 'slot-b';

  PollDetailModel sampleDetail({
    int slotAScore = 0,
    List<PollVoteModel>? slotAVotes,
    int slotBScore = 0,
    List<PollVoteModel>? slotBVotes,
  }) {
    return PollDetailModel(
      id: pollId,
      tripId: tripId,
      title: 'When?',
      status: PollStatus.open,
      createdBy: 'organizer',
      createdAt: DateTime.utc(2026, 4, 1),
      slots: [
        PollSlotDetailModel(
          id: slotAId,
          startDate: DateTime(2026, 6, 6),
          endDate: DateTime(2026, 6, 8),
          slotIndex: 0,
          score: slotAScore,
          votes: slotAVotes ?? const [],
        ),
        PollSlotDetailModel(
          id: slotBId,
          startDate: DateTime(2026, 7, 6),
          endDate: DateTime(2026, 7, 8),
          slotIndex: 1,
          score: slotBScore,
          votes: slotBVotes ?? const [],
        ),
      ],
      members: const [
        PollMemberModel(
            deviceId: myDeviceId, role: 'PARTICIPANT', displayName: 'Me'),
        PollMemberModel(
            deviceId: otherDeviceId,
            role: 'PARTICIPANT',
            displayName: 'Other'),
      ],
    );
  }

  setUp(() {
    mockRepository = MockPollRepository();
    mockDeviceIdService = MockDeviceIdService();
    fakeStomp = FakeStompClientManager();
    when(() => mockDeviceIdService.getOrCreateDeviceId())
        .thenAnswer((_) async => myDeviceId);
  });

  PollDetailBloc buildBloc() => PollDetailBloc(
      mockRepository, mockDeviceIdService, fakeStomp);

  group('PollDetailBloc', () {
    blocTest<PollDetailBloc, PollDetailState>(
      'loadPollDetail_success_emitsLoaded',
      build: () {
        when(() => mockRepository.getPollDetail(pollId))
            .thenAnswer((_) async => sampleDetail());
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadPollDetail(pollId)),
      expect: () => [
        const PollDetailState.loading(),
        PollDetailState.loaded(detail: sampleDetail(), myDeviceId: myDeviceId),
      ],
    );

    blocTest<PollDetailBloc, PollDetailState>(
      'tripUpdate_othersVote_updatesMatrixAndScore',
      build: () {
        when(() => mockRepository.getPollDetail(pollId))
            .thenAnswer((_) async => sampleDetail());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const LoadPollDetail(pollId));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const TripUpdateReceived({
          'type': 'POLL_VOTE_CAST',
          'pollId': pollId,
          'slotId': slotAId,
          'deviceId': otherDeviceId,
          'status': 'YES',
          'newSlotScore': 2,
        }));
      },
      verify: (bloc) {
        final detail = bloc.state.whenOrNull(loaded: (d, _, _, _, _, _) => d);
        expect(detail, isNotNull);
        final slotA = detail!.slots.firstWhere((s) => s.id == slotAId);
        expect(slotA.score, 2);
        expect(slotA.votes.any((v) => v.deviceId == otherDeviceId), isTrue);
      },
    );

    blocTest<PollDetailBloc, PollDetailState>(
      'tripUpdate_wrongPollId_isIgnored',
      build: () {
        when(() => mockRepository.getPollDetail(pollId))
            .thenAnswer((_) async => sampleDetail());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const LoadPollDetail(pollId));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const TripUpdateReceived({
          'type': 'POLL_VOTE_CAST',
          'pollId': 'other-poll',
          'slotId': slotAId,
          'deviceId': otherDeviceId,
          'status': 'YES',
          'newSlotScore': 2,
        }));
      },
      verify: (bloc) {
        final slotA = bloc.state
            .whenOrNull(loaded: (d, _, _, _, _, _) => d)!
            .slots
            .firstWhere((s) => s.id == slotAId);
        expect(slotA.score, 0);
        expect(slotA.votes, isEmpty);
      },
    );

    blocTest<PollDetailBloc, PollDetailState>(
      'connectionState_disconnect_setsBanner',
      build: () {
        when(() => mockRepository.getPollDetail(pollId))
            .thenAnswer((_) async => sampleDetail());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const LoadPollDetail(pollId));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const ConnectionStateChanged(StompConnectionState.reconnecting));
      },
      verify: (bloc) {
        final banner = bloc.state.whenOrNull(
            loaded: (_, _, _, connectionBanner, _, _) => connectionBanner);
        expect(banner, 'Reconnecting…');
      },
    );

    test('castVote_failure_perSlotRollback_preservesOtherOptimistic',
        () async {
      when(() => mockRepository.getPollDetail(pollId))
          .thenAnswer((_) async => sampleDetail());
      // Slot A succeeds, slot B fails
      when(() => mockRepository.respond(
            pollId: pollId,
            slotId: slotAId,
            status: VoteStatus.yes,
          )).thenAnswer((_) async => const PollVoteModel(
          deviceId: myDeviceId, status: VoteStatus.yes));
      when(() => mockRepository.respond(
            pollId: pollId,
            slotId: slotBId,
            status: VoteStatus.maybe,
          )).thenThrow(Exception('boom'));

      final bloc = buildBloc();
      bloc.add(const LoadPollDetail(pollId));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const CastVote(slotId: slotAId, status: VoteStatus.yes));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const CastVote(slotId: slotBId, status: VoteStatus.maybe));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final detail =
          bloc.state.whenOrNull(loaded: (d, _, _, _, _, _) => d);
      final slotA = detail!.slots.firstWhere((s) => s.id == slotAId);
      final slotB = detail.slots.firstWhere((s) => s.id == slotBId);
      expect(slotA.score, 2,
          reason: 'slot A optimistic value preserved after slot B rollback');
      expect(slotB.score, 0, reason: 'slot B reverted');
      final banner =
          bloc.state.whenOrNull(loaded: (_, _, e, _, _, _) => e);
      expect(banner, contains('Could not save vote for'));

      await bloc.close();
    });

    PollDetailModel lockedDetail() => sampleDetail().copyWith(
          status: PollStatus.locked,
          lockedSlotId: slotAId,
        );

    blocTest<PollDetailBloc, PollDetailState>(
      'lockPoll_success_emitsLockedDetail',
      build: () {
        when(() => mockRepository.getPollDetail(pollId))
            .thenAnswer((_) async => sampleDetail());
        when(() => mockRepository.lockPoll(pollId: pollId, slotId: slotAId))
            .thenAnswer((_) async => lockedDetail());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const LoadPollDetail(pollId));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const LockPoll(slotAId));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final detail = bloc.state.whenOrNull(loaded: (d, _, _, _, _, _) => d);
        expect(detail, isNotNull);
        expect(detail!.status, PollStatus.locked);
        expect(detail.lockedSlotId, slotAId);
        final banner = bloc.state
            .whenOrNull(loaded: (_, _, _, _, s, _) => s);
        expect(banner, contains('Dates confirmed'));
      },
    );

    blocTest<PollDetailBloc, PollDetailState>(
      'lockPoll_409_emitsConflictBanner',
      build: () {
        when(() => mockRepository.getPollDetail(pollId))
            .thenAnswer((_) async => sampleDetail());
        when(() => mockRepository.lockPoll(pollId: pollId, slotId: slotAId))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/lock'),
          response: Response(
              requestOptions: RequestOptions(path: '/lock'), statusCode: 409),
        ));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const LoadPollDetail(pollId));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const LockPoll(slotAId));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final banner = bloc.state
            .whenOrNull(loaded: (_, _, e, _, _, _) => e);
        expect(banner, 'Poll is already locked');
      },
    );

    blocTest<PollDetailBloc, PollDetailState>(
      'lockPoll_403_emitsForbiddenBanner',
      build: () {
        when(() => mockRepository.getPollDetail(pollId))
            .thenAnswer((_) async => sampleDetail());
        when(() => mockRepository.lockPoll(pollId: pollId, slotId: slotAId))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/lock'),
          response: Response(
              requestOptions: RequestOptions(path: '/lock'), statusCode: 403),
        ));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const LoadPollDetail(pollId));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const LockPoll(slotAId));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final banner = bloc.state
            .whenOrNull(loaded: (_, _, e, _, _, _) => e);
        expect(banner, 'Only the organizer can lock this poll');
      },
    );

    blocTest<PollDetailBloc, PollDetailState>(
      'tripUpdate_pollLocked_transitionsStateToLocked',
      build: () {
        when(() => mockRepository.getPollDetail(pollId))
            .thenAnswer((_) async => sampleDetail());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const LoadPollDetail(pollId));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const TripUpdateReceived({
          'type': 'POLL_LOCKED',
          'pollId': pollId,
          'tripId': tripId,
          'slotId': slotAId,
          'startDate': '2026-06-07',
          'endDate': '2026-06-08',
        }));
      },
      verify: (bloc) {
        final detail =
            bloc.state.whenOrNull(loaded: (d, _, _, _, _, _) => d);
        expect(detail!.status, PollStatus.locked);
        expect(detail.lockedSlotId, slotAId);
        final banner = bloc.state
            .whenOrNull(loaded: (_, _, _, _, s, _) => s);
        expect(banner, contains('Dates confirmed'));
      },
    );

    blocTest<PollDetailBloc, PollDetailState>(
      'tripUpdate_pollLocked_wrongPollId_isIgnored',
      build: () {
        when(() => mockRepository.getPollDetail(pollId))
            .thenAnswer((_) async => sampleDetail());
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const LoadPollDetail(pollId));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const TripUpdateReceived({
          'type': 'POLL_LOCKED',
          'pollId': 'other-poll',
          'tripId': tripId,
          'slotId': slotAId,
          'startDate': '2026-06-07',
          'endDate': '2026-06-08',
        }));
      },
      verify: (bloc) {
        final detail =
            bloc.state.whenOrNull(loaded: (d, _, _, _, _, _) => d);
        expect(detail!.status, PollStatus.open);
        expect(detail.lockedSlotId, isNull);
      },
    );
  });
}
