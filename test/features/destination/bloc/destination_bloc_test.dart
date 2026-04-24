import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/destination/domain/model/destination_model.dart';
import 'package:plantogether_app/features/destination/domain/repository/destination_repository.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_bloc.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_event.dart';
import 'package:plantogether_app/features/destination/presentation/bloc/destination_state.dart';

class MockDestinationRepository extends Mock implements DestinationRepository {}

class FakeProposeInput extends Fake implements ProposeDestinationInput {}

void main() {
  late MockDestinationRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeProposeInput());
  });

  setUp(() {
    mockRepository = MockDestinationRepository();
  });

  const tripId = 'trip-1';
  final destination = DestinationModel(
    id: 'dest-1',
    tripId: tripId,
    name: 'Paris',
    description: 'City of lights',
    estimatedBudget: 1200.0,
    currency: 'EUR',
    proposedByDeviceId: 'device-1',
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );

  group('DestinationBloc', () {
    blocTest<DestinationBloc, DestinationState>(
      'loadDestinations_success_emitsLoaded',
      build: () {
        when(() => mockRepository.list(tripId))
            .thenAnswer((_) async => [destination]);
        return DestinationBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const LoadDestinations(tripId)),
      expect: () => [
        const DestinationState.loading(),
        DestinationState.loaded(destinations: [destination]),
      ],
    );

    blocTest<DestinationBloc, DestinationState>(
      'loadDestinations_failure_emitsError',
      build: () {
        when(() => mockRepository.list(tripId))
            .thenThrow(Exception('Network failure'));
        return DestinationBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const LoadDestinations(tripId)),
      expect: () => [
        const DestinationState.loading(),
        isA<DestinationState>().having(
          (s) => s.when(
            initial: () => '',
            loading: () => '',
            loaded: (_, mode, myDeviceId) => '',
            error: (m) => m,
          ),
          'error message',
          isNotEmpty,
        ),
      ],
    );

    blocTest<DestinationBloc, DestinationState>(
      'proposeDestination_success_reloads',
      build: () {
        when(() => mockRepository.propose(tripId, any()))
            .thenAnswer((_) async => destination);
        when(() => mockRepository.list(tripId))
            .thenAnswer((_) async => [destination]);
        return DestinationBloc(mockRepository);
      },
      act: (bloc) => bloc.add(ProposeDestination(
        tripId: tripId,
        input: const ProposeDestinationInput(name: 'Paris'),
      )),
      expect: () => [
        const DestinationState.loading(),
        DestinationState.loaded(destinations: [destination]),
      ],
      verify: (_) {
        verify(() => mockRepository.propose(tripId, any())).called(1);
        verify(() => mockRepository.list(tripId)).called(1);
      },
    );

    blocTest<DestinationBloc, DestinationState>(
      'proposeDestination_failure_emitsError',
      build: () {
        when(() => mockRepository.propose(tripId, any()))
            .thenThrow(Exception('Forbidden'));
        return DestinationBloc(mockRepository);
      },
      act: (bloc) => bloc.add(ProposeDestination(
        tripId: tripId,
        input: const ProposeDestinationInput(name: 'Paris'),
      )),
      expect: () => [
        isA<DestinationState>().having(
          (s) => s.when(
            initial: () => '',
            loading: () => '',
            loaded: (_, mode, myDeviceId) => '',
            error: (m) => m,
          ),
          'error message',
          isNotEmpty,
        ),
      ],
    );
  });
}
