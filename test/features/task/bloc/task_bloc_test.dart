import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/task/domain/entity/task.dart';
import 'package:plantogether_app/features/task/domain/repository/task_repository.dart';
import 'package:plantogether_app/features/task/presentation/bloc/task_bloc.dart';
import 'package:plantogether_app/features/task/presentation/bloc/task_event.dart';
import 'package:plantogether_app/features/task/presentation/bloc/task_state.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class FakeCreateTaskInput extends Fake implements CreateTaskInput {}

void main() {
  late MockTaskRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeCreateTaskInput());
  });

  setUp(() {
    mockRepository = MockTaskRepository();
  });

  const tripId = 'trip-1';
  final task = Task(
    id: 'task-1',
    tripId: tripId,
    title: 'Buy sunscreen',
    status: TaskStatus.todo,
    priority: TaskPriority.medium,
    createdBy: 'device-1',
    createdAt: DateTime.utc(2026, 5, 1),
    updatedAt: DateTime.utc(2026, 5, 1),
  );

  group('TaskBloc', () {
    blocTest<TaskBloc, TaskState>(
      'loadTasks_success_emitsLoaded',
      build: () {
        when(() => mockRepository.list(tripId))
            .thenAnswer((_) async => [task]);
        return TaskBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const LoadTasks(tripId)),
      expect: () => [
        const TaskState.loading(),
        TaskState.loaded(tasks: [task]),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'loadTasks_failure_emitsError',
      build: () {
        when(() => mockRepository.list(tripId))
            .thenThrow(Exception('Network error'));
        return TaskBloc(mockRepository);
      },
      act: (bloc) => bloc.add(const LoadTasks(tripId)),
      expect: () => [
        const TaskState.loading(),
        const TaskState.error(message: 'Network error'),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'createTask_success_reloads',
      build: () {
        when(() => mockRepository.create(any(), any()))
            .thenAnswer((_) async => task);
        when(() => mockRepository.list(tripId))
            .thenAnswer((_) async => [task]);
        return TaskBloc(mockRepository);
      },
      act: (bloc) => bloc.add(
        CreateTask(
          tripId: tripId,
          input: const CreateTaskInput(title: 'Buy sunscreen'),
        ),
      ),
      // The bloc emits loading() once for CreateTask, then loaded() after the
      // internal LoadTasks completes. The second loading() is deduplicated by
      // flutter_bloc because it is identical to the first (const factory).
      expect: () => [
        const TaskState.loading(),
        TaskState.loaded(tasks: [task]),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'createTask_failure_emitsError',
      build: () {
        when(() => mockRepository.create(any(), any()))
            .thenThrow(Exception('Server error'));
        return TaskBloc(mockRepository);
      },
      act: (bloc) => bloc.add(
        CreateTask(
          tripId: tripId,
          input: const CreateTaskInput(title: 'Buy sunscreen'),
        ),
      ),
      expect: () => [
        const TaskState.loading(),
        const TaskState.error(message: 'Server error'),
      ],
    );
  });
}
