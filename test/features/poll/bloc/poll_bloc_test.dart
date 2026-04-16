import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/poll/data/datasource/poll_remote_datasource.dart';
import 'package:plantogether_app/features/poll/domain/model/poll_model.dart';
import 'package:plantogether_app/features/poll/domain/repository/poll_repository.dart';
import 'package:plantogether_app/features/poll/presentation/bloc/poll_bloc.dart';
import 'package:plantogether_app/features/poll/presentation/bloc/poll_event.dart';
import 'package:plantogether_app/features/poll/presentation/bloc/poll_state.dart';

class MockPollRepository extends Mock implements PollRepository {}

class FakeSlotInput extends Fake implements SlotInput {}

void main() {
  late MockPollRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeSlotInput());
  });

  setUp(() {
    mockRepository = MockPollRepository();
  });

  const tripId = 'trip-1';
  const poll = PollModel(
    id: 'poll-1',
    tripId: tripId,
    title: 'Summer trip',
    status: PollStatus.open,
    createdBy: 'device-1',
    createdAt: '2026-04-01T00:00:00Z',
    slots: [
      PollSlotModel(
          id: 's1', startDate: '2026-06-01', endDate: '2026-06-07', slotIndex: 0),
      PollSlotModel(
          id: 's2', startDate: '2026-06-15', endDate: '2026-06-21', slotIndex: 1),
    ],
  );

  group('PollBloc', () {
    blocTest<PollBloc, PollState>(
      'emits [loading, loaded] when LoadPolls succeeds',
      build: () {
        when(() => mockRepository.getPollsForTrip(tripId))
            .thenAnswer((_) async => const [poll]);
        return PollBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const LoadPolls(tripId)),
      expect: () => [
        const PollState.loading(),
        const PollState.loaded(polls: [poll]),
      ],
    );

    blocTest<PollBloc, PollState>(
      'emits [loading, error] when LoadPolls throws',
      build: () {
        when(() => mockRepository.getPollsForTrip(tripId))
            .thenThrow(Exception('Network failure'));
        return PollBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const LoadPolls(tripId)),
      expect: () => [
        const PollState.loading(),
        isA<PollState>().having(
          (s) => s.when(
            initial: () => '',
            loading: () => '',
            loaded: (_) => '',
            error: (m) => m,
          ),
          'error message',
          contains('Network failure'),
        ),
      ],
    );

    blocTest<PollBloc, PollState>(
      'emits [loading, loaded] when CreatePoll succeeds and reloads list',
      build: () {
        when(() => mockRepository.createPoll(
              tripId: tripId,
              title: any(named: 'title'),
              slots: any(named: 'slots'),
            )).thenAnswer((_) async => poll);
        when(() => mockRepository.getPollsForTrip(tripId))
            .thenAnswer((_) async => const [poll]);
        return PollBloc(mockRepository);
      },
      act: (bloc) => bloc.add(CreatePoll(
        tripId: tripId,
        title: 'Summer trip',
        slots: [
          SlotInput(
              startDate: DateTime(2026, 6, 1), endDate: DateTime(2026, 6, 7)),
          SlotInput(
              startDate: DateTime(2026, 6, 15), endDate: DateTime(2026, 6, 21)),
        ],
      )),
      expect: () => [
        const PollState.loading(),
        const PollState.loaded(polls: [poll]),
      ],
      verify: (_) {
        verify(() => mockRepository.createPoll(
              tripId: tripId,
              title: 'Summer trip',
              slots: any(named: 'slots'),
            )).called(1);
        verify(() => mockRepository.getPollsForTrip(tripId)).called(1);
      },
    );

    blocTest<PollBloc, PollState>(
      'emits [loading, error] when CreatePoll throws',
      build: () {
        when(() => mockRepository.createPoll(
              tripId: tripId,
              title: any(named: 'title'),
              slots: any(named: 'slots'),
            )).thenThrow(Exception('Forbidden'));
        return PollBloc(mockRepository);
      },
      act: (bloc) => bloc.add(CreatePoll(
        tripId: tripId,
        title: 'Nope',
        slots: [
          SlotInput(
              startDate: DateTime(2026, 6, 1), endDate: DateTime(2026, 6, 7)),
          SlotInput(
              startDate: DateTime(2026, 6, 15), endDate: DateTime(2026, 6, 21)),
        ],
      )),
      expect: () => [
        const PollState.loading(),
        isA<PollState>().having(
          (s) => s.when(
            initial: () => '',
            loading: () => '',
            loaded: (_) => '',
            error: (m) => m,
          ),
          'error message',
          contains('Forbidden'),
        ),
      ],
    );
  });
}
