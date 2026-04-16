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
  final tripModel = TripModel(
    id: tripId,
    title: 'Test Trip',
    status: 'PLANNING',
    createdBy: 'device-1',
    createdAt: DateTime.utc(2026, 1, 1),
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
        TripDetailState.loaded(trip: tripModel),
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

    // --- UpdateTrip ---

    blocTest<TripDetailBloc, TripDetailState>(
      'emits [loading, loaded] when UpdateTrip succeeds',
      build: () {
        when(() => mockRepository.updateTrip(
              tripId,
              title: 'New Title',
              description: null,
              currency: null,
            )).thenAnswer((_) async => tripModel.copyWith(title: 'New Title'));
        return TripDetailBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const UpdateTrip(
        tripId: tripId,
        title: 'New Title',
      )),
      expect: () => [
        const TripDetailState.loading(),
        TripDetailState.loaded(trip: tripModel.copyWith(title: 'New Title')),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'emits [loading, failure] when UpdateTrip throws',
      build: () {
        when(() => mockRepository.updateTrip(
              tripId,
              title: any(named: 'title'),
              description: any(named: 'description'),
              currency: any(named: 'currency'),
            )).thenThrow(Exception('Forbidden'));
        return TripDetailBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const UpdateTrip(
        tripId: tripId,
        title: 'Hacked',
      )),
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
          contains('Forbidden'),
        ),
      ],
    );

    // --- ArchiveTrip ---

    blocTest<TripDetailBloc, TripDetailState>(
      'emits [loading, loaded] when ArchiveTrip succeeds',
      build: () {
        when(() => mockRepository.archiveTrip(tripId))
            .thenAnswer((_) async => tripModel.copyWith(status: 'ARCHIVED'));
        return TripDetailBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const ArchiveTrip(tripId: tripId)),
      expect: () => [
        const TripDetailState.loading(),
        TripDetailState.loaded(trip: tripModel.copyWith(status: 'ARCHIVED')),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'emits [loading, failure] when ArchiveTrip throws',
      build: () {
        when(() => mockRepository.archiveTrip(tripId))
            .thenThrow(Exception('Already archived'));
        return TripDetailBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const ArchiveTrip(tripId: tripId)),
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
          contains('Already archived'),
        ),
      ],
    );
  });
}
