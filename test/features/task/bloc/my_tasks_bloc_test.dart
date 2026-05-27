import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/core/security/device_id_service.dart';
import 'package:plantogether_app/features/task/domain/entity/task.dart';
import 'package:plantogether_app/features/task/domain/repository/task_repository.dart';
import 'package:plantogether_app/features/task/presentation/bloc/my_tasks_bloc.dart';
import 'package:plantogether_app/features/task/presentation/bloc/my_tasks_event.dart';
import 'package:plantogether_app/features/task/presentation/bloc/my_tasks_state.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';
import 'package:plantogether_app/features/trip/domain/repository/trip_repository.dart';

class MockTripRepository extends Mock implements TripRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockDeviceIdService extends Mock implements DeviceIdService {}

void main() {
  late MockTripRepository mockTripRepository;
  late MockTaskRepository mockTaskRepository;
  late MockDeviceIdService mockDeviceIdService;

  const deviceId = 'device-abc';

  final trip1 = TripModel(
    id: 'trip-1',
    title: 'Paris Trip',
    status: 'ACTIVE',
    createdBy: deviceId,
    createdAt: DateTime.utc(2026, 5, 1),
  );

  final trip2 = TripModel(
    id: 'trip-2',
    title: 'Rome Trip',
    status: 'ACTIVE',
    createdBy: deviceId,
    createdAt: DateTime.utc(2026, 5, 1),
  );

  final archivedTrip = TripModel(
    id: 'trip-archived',
    title: 'Old Trip',
    status: 'ARCHIVED',
    createdBy: deviceId,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  Task makeTask(String id, String tripId) => Task(
        id: id,
        tripId: tripId,
        title: 'Task $id',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        createdBy: deviceId,
        createdAt: DateTime.utc(2026, 5, 1),
        updatedAt: DateTime.utc(2026, 5, 1),
      );

  setUp(() {
    mockTripRepository = MockTripRepository();
    mockTaskRepository = MockTaskRepository();
    mockDeviceIdService = MockDeviceIdService();

    when(() => mockDeviceIdService.getOrCreateDeviceId())
        .thenAnswer((_) async => deviceId);
  });

  setUpAll(() {
    registerFallbackValue(TaskStatus.todo);
  });

  MyTasksBloc buildBloc() => MyTasksBloc(
        mockTripRepository,
        mockTaskRepository,
        mockDeviceIdService,
      );

  group('MyTasksBloc', () {
    blocTest<MyTasksBloc, MyTasksState>(
      'loadMyTasks_mergesTasksAcrossActiveTrips_taggedWithTripName',
      build: () {
        when(() => mockTripRepository.listTrips())
            .thenAnswer((_) async => [trip1, trip2, archivedTrip]);

        final task1 = makeTask('t1', 'trip-1');
        final task2 = makeTask('t2', 'trip-2');

        when(
          () => mockTaskRepository.list('trip-1', assignee: deviceId),
        ).thenAnswer((_) async => [task1]);

        when(
          () => mockTaskRepository.list('trip-2', assignee: deviceId),
        ).thenAnswer((_) async => [task2]);

        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadMyTasks()),
      expect: () => [
        const MyTasksState.loading(),
        isA<MyTasksState>().having(
          (s) => s.whenOrNull(
            loaded: (items, _) => items.map((i) => i.tripName).toList(),
          ),
          'tripNames present',
          containsAll(['Paris Trip', 'Rome Trip']),
        ),
      ],
    );

    blocTest<MyTasksBloc, MyTasksState>(
      'loadMyTasks_skipsArchivedTrips',
      build: () {
        when(() => mockTripRepository.listTrips())
            .thenAnswer((_) async => [trip1, archivedTrip]);

        when(
          () => mockTaskRepository.list('trip-1', assignee: deviceId),
        ).thenAnswer((_) async => [makeTask('t1', 'trip-1')]);

        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadMyTasks()),
      verify: (_) {
        // Archived trip should never be queried.
        verifyNever(
          () => mockTaskRepository.list('trip-archived', assignee: deviceId),
        );
      },
      expect: () => [
        const MyTasksState.loading(),
        isA<MyTasksState>().having(
          (s) => s.whenOrNull(loaded: (items, _) => items.length),
          'item count',
          1,
        ),
      ],
    );

    blocTest<MyTasksBloc, MyTasksState>(
      'loadMyTasks_oneTripFails_othersStillLoad_withFailedBanner',
      build: () {
        when(() => mockTripRepository.listTrips())
            .thenAnswer((_) async => [trip1, trip2]);

        when(
          () => mockTaskRepository.list('trip-1', assignee: deviceId),
        ).thenThrow(Exception('Network error'));

        when(
          () => mockTaskRepository.list('trip-2', assignee: deviceId),
        ).thenAnswer((_) async => [makeTask('t2', 'trip-2')]);

        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadMyTasks()),
      expect: () => [
        const MyTasksState.loading(),
        isA<MyTasksState>()
            .having(
              (s) => s.whenOrNull(loaded: (items, _) => items.length),
              'item count',
              1,
            )
            .having(
              (s) => s.whenOrNull(loaded: (_, failed) => failed),
              'failed trip names',
              ['Paris Trip'],
            ),
      ],
    );

    blocTest<MyTasksBloc, MyTasksState>(
      'loadMyTasks_noAssignedTasks_emitsLoadedEmpty',
      build: () {
        when(() => mockTripRepository.listTrips())
            .thenAnswer((_) async => [trip1]);

        when(
          () => mockTaskRepository.list('trip-1', assignee: deviceId),
        ).thenAnswer((_) async => []);

        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadMyTasks()),
      expect: () => [
        const MyTasksState.loading(),
        const MyTasksState.loaded(items: []),
      ],
    );

    blocTest<MyTasksBloc, MyTasksState>(
      'loadMyTasks_listTripsThrows_emitsError',
      build: () {
        when(() => mockTripRepository.listTrips())
            .thenThrow(Exception('Server error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadMyTasks()),
      expect: () => [
        const MyTasksState.loading(),
        const MyTasksState.error(message: 'Server error'),
      ],
    );
  });
}
