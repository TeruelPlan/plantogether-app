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
    registerFallbackValue(TaskStatus.todo);
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

    blocTest<TaskBloc, TaskState>(
      'createSubtask_success_reloads',
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
          input: const CreateTaskInput(
            title: 'Pack towels',
            parentTaskId: 'task-1',
          ),
        ),
      ),
      expect: () => [
        const TaskState.loading(),
        TaskState.loaded(tasks: [task]),
      ],
    );

    // UpdateTaskStatus: optimistic update then reload on success.
    // The TODO → IN_PROGRESS transition keeps completedAt null, so exact
    // equality works without a predicate matcher.
    blocTest<TaskBloc, TaskState>(
      'updateStatus_optimistic_thenReload',
      build: () {
        when(() => mockRepository.updateStatus(any(), any()))
            .thenAnswer((_) async => task.copyWith(status: TaskStatus.inProgress));
        when(() => mockRepository.list(tripId))
            .thenAnswer((_) async => [task.copyWith(status: TaskStatus.inProgress)]);
        return TaskBloc(mockRepository);
      },
      seed: () => TaskState.loaded(tasks: [task]),
      act: (bloc) => bloc.add(
        const UpdateTaskStatus(
          tripId: tripId,
          taskId: 'task-1',
          next: TaskStatus.inProgress,
        ),
      ),
      expect: () => [
        // Optimistic: status flipped to inProgress, completedAt stays null.
        TaskState.loaded(
          tasks: [task.copyWith(status: TaskStatus.inProgress)],
        ),
        // After LoadTasks reload.
        const TaskState.loading(),
        TaskState.loaded(
          tasks: [task.copyWith(status: TaskStatus.inProgress)],
        ),
      ],
    );

    // UpdateTaskStatus: repository throws → rollback + error emitted.
    blocTest<TaskBloc, TaskState>(
      'updateStatus_failure_rollsBack',
      build: () {
        when(() => mockRepository.updateStatus(any(), any()))
            .thenThrow(Exception('Network error'));
        return TaskBloc(mockRepository);
      },
      seed: () => TaskState.loaded(tasks: [task]),
      act: (bloc) => bloc.add(
        const UpdateTaskStatus(
          tripId: tripId,
          taskId: 'task-1',
          next: TaskStatus.inProgress,
        ),
      ),
      expect: () => [
        // Optimistic state (inProgress, completedAt null).
        TaskState.loaded(
          tasks: [task.copyWith(status: TaskStatus.inProgress)],
        ),
        // Rollback to original.
        TaskState.loaded(tasks: [task]),
        // Error surfaced.
        const TaskState.error(message: 'Network error'),
      ],
    );

    // UpdateTaskStatus: when taskId belongs to a subtask, only the nested
    // task's status is updated; the parent is unchanged.
    blocTest<TaskBloc, TaskState>(
      'updateStatus_onSubtask_targetsNestedTask',
      build: () {
        when(() => mockRepository.updateStatus(any(), any())).thenAnswer(
          (_) async => task.copyWith(status: TaskStatus.inProgress),
        );
        when(() => mockRepository.list(tripId)).thenAnswer((_) async => [task]);
        return TaskBloc(mockRepository);
      },
      seed: () {
        final subtask = Task(
          id: 'sub-1',
          tripId: tripId,
          parentTaskId: 'task-1',
          title: 'Pack towels',
          status: TaskStatus.todo,
          priority: TaskPriority.medium,
          createdBy: 'device-1',
          createdAt: DateTime.utc(2026, 5, 1),
          updatedAt: DateTime.utc(2026, 5, 1),
        );
        final parentWithSub = task.copyWith(subtasks: [subtask]);
        return TaskState.loaded(tasks: [parentWithSub]);
      },
      act: (bloc) => bloc.add(
        const UpdateTaskStatus(
          tripId: tripId,
          taskId: 'sub-1',
          next: TaskStatus.inProgress,
        ),
      ),
      expect: () {
        final updatedSubtask = Task(
          id: 'sub-1',
          tripId: tripId,
          parentTaskId: 'task-1',
          title: 'Pack towels',
          status: TaskStatus.inProgress,
          priority: TaskPriority.medium,
          createdBy: 'device-1',
          createdAt: DateTime.utc(2026, 5, 1),
          updatedAt: DateTime.utc(2026, 5, 1),
        );
        final parentUnchanged = task.copyWith(subtasks: [updatedSubtask]);
        return [
          // Optimistic: only the subtask status is flipped.
          TaskState.loaded(tasks: [parentUnchanged]),
          // Reload sequence.
          const TaskState.loading(),
          TaskState.loaded(tasks: [task]),
        ];
      },
    );

    // UpdateTaskStatus: when not in loaded state, event is a no-op.
    blocTest<TaskBloc, TaskState>(
      'updateStatus_whenNotLoaded_isNoOp',
      build: () => TaskBloc(mockRepository),
      // seed is initial state (default)
      act: (bloc) => bloc.add(
        const UpdateTaskStatus(
          tripId: tripId,
          taskId: 'task-1',
          next: TaskStatus.inProgress,
        ),
      ),
      expect: () => <TaskState>[],
    );
  });
}
