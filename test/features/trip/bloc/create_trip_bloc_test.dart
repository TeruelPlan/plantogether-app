import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';
import 'package:plantogether_app/features/trip/domain/repository/trip_repository.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/create_trip_bloc.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/create_trip_event.dart';
import 'package:plantogether_app/features/trip/presentation/bloc/create_trip_state.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  group('CreateTripBloc', () {
    late CreateTripBloc bloc;
    late MockTripRepository mockRepository;

    setUp(() {
      mockRepository = MockTripRepository();
      bloc = CreateTripBloc(mockRepository);
    });

    tearDown(() {
      bloc.close();
    });

    const testTrip = TripModel(
      id: '123',
      title: 'Beach Trip',
      description: 'Fun at the beach',
      status: 'PLANNING',
      referenceCurrency: 'EUR',
      createdBy: 'device-1',
      createdAt: '2026-04-04T00:00:00Z',
    );

    blocTest<CreateTripBloc, CreateTripState>(
      'emits [loading, success] when SubmitCreateTrip succeeds',
      build: () {
        when(() => mockRepository.createTrip(
              title: 'Beach Trip',
              description: 'Fun at the beach',
              currency: 'EUR',
            )).thenAnswer((_) async => testTrip);
        return bloc;
      },
      act: (bloc) => bloc.add(const SubmitCreateTrip(
        title: 'Beach Trip',
        description: 'Fun at the beach',
        currency: 'EUR',
      )),
      expect: () => [
        const CreateTripState.loading(),
        const CreateTripState.success(trip: testTrip),
      ],
    );

    blocTest<CreateTripBloc, CreateTripState>(
      'emits [loading, failure] when SubmitCreateTrip throws',
      build: () {
        when(() => mockRepository.createTrip(
              title: 'Beach Trip',
              description: null,
              currency: null,
            )).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (bloc) => bloc.add(const SubmitCreateTrip(
        title: 'Beach Trip',
      )),
      expect: () => [
        const CreateTripState.loading(),
        isA<CreateTripState>().having(
          (s) => s.whenOrNull(failure: (msg) => msg),
          'failure message',
          isNotNull,
        ),
      ],
    );
  });
}
