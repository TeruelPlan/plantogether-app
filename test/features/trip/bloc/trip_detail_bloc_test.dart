import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';
import 'package:plantogether_app/features/trip/domain/repository/trip_repository.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/trip_detail_bloc.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/trip_detail_event.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/trip_detail_state.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
  });

  const tripId = 'test-trip-id';
  const tripModel = TripModel(
    id: tripId,
    title: 'Test Trip',
    status: 'PLANNING',
    createdBy: 'device-1',
    createdAt: '2026-01-01T00:00:00Z',
    memberCount: 2,
  );

  group('TripDetailBloc', () {
    blocTest<TripDetailBloc, TripDetailState>(
      'emits [loading, loaded] when LoadTripDetail succeeds',
      build: () {
        when(() => mockRepository.getTrip(tripId))
            .thenAnswer((_) async => tripModel);
        return TripDetailBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const LoadTripDetail(tripId: tripId)),
      expect: () => [
        const TripDetailState.loading(),
        const TripDetailState.loaded(trip: tripModel),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'emits [loading, failure] when LoadTripDetail throws',
      build: () {
        when(() => mockRepository.getTrip(tripId))
            .thenThrow(Exception('Network error'));
        return TripDetailBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const LoadTripDetail(tripId: tripId)),
      expect: () => [
        const TripDetailState.loading(),
        isA<TripDetailState>().having(
          (s) => s.when(
            initial: () => '',
            loading: () => '',
            loaded: (_) => '',
            failure: (m) => m,
          ),
          'failure message',
          contains('Network error'),
        ),
      ],
    );
  });
}
