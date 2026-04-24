import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/destination/domain/model/destination_model.dart';
import 'package:plantogether_app/features/destination/domain/model/vote_config_model.dart';
import 'package:plantogether_app/features/destination/domain/repository/destination_repository.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_bloc.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_event.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_state.dart';

class MockDestinationRepository extends Mock implements DestinationRepository {}

void main() {
  late MockDestinationRepository repo;

  setUp(() {
    repo = MockDestinationRepository();
  });

  const tripId = 'trip-1';
  const destId = 'dest-1';
  final destination = DestinationModel(
    id: destId,
    tripId: tripId,
    name: 'Paris',
    proposedByDeviceId: 'device-1',
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );
  final configSimple = VoteConfigModel(
    tripId: tripId,
    mode: VoteMode.simple,
    updatedAt: DateTime.utc(2026, 4, 1),
  );
  final configRanking = VoteConfigModel(
    tripId: tripId,
    mode: VoteMode.ranking,
    updatedAt: DateTime.utc(2026, 4, 2),
  );

  group('DestinationBloc vote flows', () {
    blocTest<DestinationBloc, DestinationState>(
      'loadVoteConfig_success_emitsLoadedWithMode',
      build: () {
        when(() => repo.getVoteConfig(tripId))
            .thenAnswer((_) async => configSimple);
        when(() => repo.list(tripId))
            .thenAnswer((_) async => [destination]);
        return DestinationBloc(repo);
      },
      act: (bloc) {
        bloc.add(const LoadDestinations(tripId));
        bloc.add(const LoadVoteConfig(tripId));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final mode = bloc.state.maybeWhen(
          loaded: (_, m, _) => m,
          orElse: () => null,
        );
        expect(mode, VoteMode.simple);
      },
    );

    blocTest<DestinationBloc, DestinationState>(
      'updateVoteConfig_organizer_emitsLoadedWithNewMode',
      build: () {
        when(() => repo.updateVoteConfig(tripId, VoteMode.ranking))
            .thenAnswer((_) async => configRanking);
        when(() => repo.list(tripId))
            .thenAnswer((_) async => [destination]);
        return DestinationBloc(repo);
      },
      act: (bloc) => bloc.add(
        const UpdateVoteConfig(tripId: tripId, mode: VoteMode.ranking),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repo.updateVoteConfig(tripId, VoteMode.ranking))
            .called(1);
        verify(() => repo.list(tripId)).called(1);
      },
    );

    blocTest<DestinationBloc, DestinationState>(
      'updateVoteConfig_participantReceives403_emitsError',
      build: () {
        when(() => repo.updateVoteConfig(tripId, VoteMode.ranking)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 403,
            ),
          ),
        );
        return DestinationBloc(repo);
      },
      act: (bloc) => bloc.add(
        const UpdateVoteConfig(tripId: tripId, mode: VoteMode.ranking),
      ),
      expect: () => [
        isA<DestinationState>().having(
          (s) => s.maybeWhen(error: (m) => m, orElse: () => null),
          'error message',
          contains('not a member'),
        ),
      ],
    );

    blocTest<DestinationBloc, DestinationState>(
      'castVote_simple_reloadsDestinations',
      build: () {
        when(() => repo.castVote(destId, rank: null))
            .thenAnswer((_) async {});
        when(() => repo.list(tripId))
            .thenAnswer((_) async => [destination]);
        return DestinationBloc(repo);
      },
      act: (bloc) => bloc.add(
        const CastVote(tripId: tripId, destinationId: destId),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repo.castVote(destId, rank: null)).called(1);
        verify(() => repo.list(tripId)).called(1);
      },
    );

    blocTest<DestinationBloc, DestinationState>(
      'castVote_ranking_reloadsDestinations_withRank',
      build: () {
        when(() => repo.castVote(destId, rank: 2))
            .thenAnswer((_) async {});
        when(() => repo.list(tripId))
            .thenAnswer((_) async => [destination]);
        return DestinationBloc(repo);
      },
      act: (bloc) => bloc.add(
        const CastVote(tripId: tripId, destinationId: destId, rank: 2),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repo.castVote(destId, rank: 2)).called(1);
        verify(() => repo.list(tripId)).called(1);
      },
    );

    blocTest<DestinationBloc, DestinationState>(
      'retractVote_reloadsDestinations',
      build: () {
        when(() => repo.retractVote(destId)).thenAnswer((_) async {});
        when(() => repo.list(tripId))
            .thenAnswer((_) async => [destination]);
        return DestinationBloc(repo);
      },
      act: (bloc) => bloc.add(
        const RetractVote(tripId: tripId, destinationId: destId),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repo.retractVote(destId)).called(1);
        verify(() => repo.list(tripId)).called(1);
      },
    );
  });
}
