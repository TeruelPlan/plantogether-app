import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_preview_model.dart';
import 'package:plantogether_app/features/trip/domain/repository/trip_repository.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/join_trip_bloc.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/join_trip_event.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/join_trip_state.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  group('JoinTripBloc', () {
    late JoinTripBloc bloc;
    late MockTripRepository mockRepository;

    setUp(() {
      mockRepository = MockTripRepository();
      bloc = JoinTripBloc(mockRepository);
    });

    tearDown(() {
      bloc.close();
    });

    const tripId = 'trip-1';
    const token = 'tok-abc';

    const preview = TripPreviewModel(
      id: tripId,
      title: 'Beach Trip',
      memberCount: 3,
      isMember: false,
    );

    final trip = TripModel(
      id: tripId,
      title: 'Beach Trip',
      status: 'PLANNING',
      createdBy: 'device-1',
      createdAt: DateTime.utc(2026, 4, 4),
    );

    blocTest<JoinTripBloc, JoinTripState>(
      'LoadPreview emits [loadingPreview, previewLoaded] for non-member',
      build: () {
        when(() => mockRepository.getTripPreview(tripId, token))
            .thenAnswer((_) async => preview);
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const LoadPreview(tripId: tripId, token: token)),
      expect: () => [
        const JoinTripState.loadingPreview(),
        const JoinTripState.previewLoaded(preview: preview),
      ],
    );

    blocTest<JoinTripBloc, JoinTripState>(
      'LoadPreview auto-joins when already member',
      build: () {
        const memberPreview = TripPreviewModel(
          id: tripId,
          title: 'Beach Trip',
          memberCount: 3,
          isMember: true,
        );
        when(() => mockRepository.getTripPreview(tripId, token))
            .thenAnswer((_) async => memberPreview);
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const LoadPreview(tripId: tripId, token: token)),
      expect: () => [
        const JoinTripState.loadingPreview(),
        isA<JoinTripState>().having(
          (s) => s.whenOrNull(joined: (t) => t.id),
          'joined trip id',
          equals(tripId),
        ),
      ],
    );

    blocTest<JoinTripBloc, JoinTripState>(
      'SubmitJoin emits [joining, joined] on success',
      build: () {
        when(() => mockRepository.joinTrip(tripId, token))
            .thenAnswer((_) async => trip);
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const SubmitJoin(tripId: tripId, token: token)),
      expect: () => [
        const JoinTripState.joining(),
        JoinTripState.joined(trip: trip),
      ],
    );

    blocTest<JoinTripBloc, JoinTripState>(
      'SubmitJoin emits [joining, failure] when join throws',
      build: () {
        when(() => mockRepository.joinTrip(tripId, token))
            .thenThrow(Exception('Display name required'));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const SubmitJoin(tripId: tripId, token: token)),
      expect: () => [
        const JoinTripState.joining(),
        isA<JoinTripState>().having(
          (s) => s.whenOrNull(failure: (msg) => msg),
          'failure message',
          isNotNull,
        ),
      ],
    );

    blocTest<JoinTripBloc, JoinTripState>(
      'LoadPreview emits [loadingPreview, failure] when preview throws',
      build: () {
        when(() => mockRepository.getTripPreview(tripId, token))
            .thenThrow(Exception('Not found'));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const LoadPreview(tripId: tripId, token: token)),
      expect: () => [
        const JoinTripState.loadingPreview(),
        isA<JoinTripState>().having(
          (s) => s.whenOrNull(failure: (msg) => msg),
          'failure message',
          isNotNull,
        ),
      ],
    );
  });
}
