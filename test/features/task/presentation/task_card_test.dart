import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/task/domain/entity/task.dart';
import 'package:plantogether_app/features/task/presentation/bloc/task_bloc.dart';
import 'package:plantogether_app/features/task/presentation/bloc/task_event.dart';
import 'package:plantogether_app/features/task/presentation/bloc/task_state.dart';
import 'package:plantogether_app/features/task/presentation/widget/task_card.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_member_model.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';

// Use MockBloc so we can control the state and verify dispatched events.
class MockTaskBloc extends MockBloc<TaskEvent, TaskState> implements TaskBloc {}

void main() {
  late MockTaskBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(
      const UpdateTaskStatus(
        tripId: 'trip-1',
        taskId: 'task-1',
        next: TaskStatus.inProgress,
      ),
    );
    registerFallbackValue(const LoadTasks('trip-1'));
  });

  setUp(() {
    mockBloc = MockTaskBloc();
    // Default state: loaded with an empty task list.
    when(() => mockBloc.state)
        .thenReturn(const TaskState.loaded(tasks: []));
    whenListen(mockBloc, Stream<TaskState>.empty());
  });

  tearDown(() => mockBloc.close());

  final sampleTrip = TripModel(
    id: 'trip-1',
    title: 'Paris Trip',
    status: 'ACTIVE',
    createdBy: 'device-1',
    createdAt: DateTime.utc(2026, 5, 1),
    members: [
      TripMemberModel(
        memberId: 'device-1',
        displayName: 'Alice',
        role: 'ORGANIZER',
        joinedAt: DateTime.utc(2026, 5, 1),
        isMe: true,
      ),
    ],
  );

  final now = DateTime.utc(2026, 5, 1);

  // Builds a TaskCard inside a minimal widget tree that includes TaskBloc.
  Widget buildCard(Task task, {VoidCallback? onAddSubtask}) {
    return BlocProvider<TaskBloc>.value(
      value: mockBloc,
      child: MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task,
            trip: sampleTrip,
            onAddSubtask: onAddSubtask,
          ),
        ),
      ),
    );
  }

  group('TaskCard subtask indicator', () {
    testWidgets(
        'parentTaskWithSubtasks_shows_subtaskDoneCount', (tester) async {
      final subtask1 = Task(
        id: 'sub-1',
        tripId: 'trip-1',
        parentTaskId: 'task-1',
        title: 'Subtask A',
        status: TaskStatus.done,
        priority: TaskPriority.medium,
        createdBy: 'device-1',
        createdAt: now,
        updatedAt: now,
      );
      final subtask2 = Task(
        id: 'sub-2',
        tripId: 'trip-1',
        parentTaskId: 'task-1',
        title: 'Subtask B',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        createdBy: 'device-1',
        createdAt: now,
        updatedAt: now,
      );
      final parentTask = Task(
        id: 'task-1',
        tripId: 'trip-1',
        title: 'Parent task',
        status: TaskStatus.inProgress,
        priority: TaskPriority.medium,
        createdBy: 'device-1',
        createdAt: now,
        updatedAt: now,
        subtasks: [subtask1, subtask2],
      );

      await tester.pumpWidget(buildCard(parentTask));

      expect(
        find.byKey(const ValueKey('task_subtask_count_task-1')),
        findsOneWidget,
      );
      expect(find.text('1/2 subtasks done'), findsOneWidget);
    });

    testWidgets('parentTaskWithNoSubtasks_hidesIndicator', (tester) async {
      final task = Task(
        id: 'task-2',
        tripId: 'trip-1',
        title: 'Top-level task',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        createdBy: 'device-1',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildCard(task));

      expect(find.textContaining('subtasks done'), findsNothing);
    });
  });

  group('TaskCard add subtask button', () {
    testWidgets('topLevelTask_showsAddSubtaskButton', (tester) async {
      final task = Task(
        id: 'task-3',
        tripId: 'trip-1',
        title: 'Top-level task',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        createdBy: 'device-1',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildCard(task));

      expect(
        find.byKey(const ValueKey('add_subtask_button_task-3')),
        findsOneWidget,
      );
    });

    testWidgets('subtask_hidesAddSubtaskButton', (tester) async {
      final subtask = Task(
        id: 'sub-3',
        tripId: 'trip-1',
        parentTaskId: 'task-1',
        title: 'A subtask',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        createdBy: 'device-1',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(buildCard(subtask));

      // Tasks with parentTaskId must not show the "Add subtask" button.
      expect(
        find.byKey(const ValueKey('add_subtask_button_sub-3')),
        findsNothing,
      );
    });
  });

  group('TaskStatusToggle', () {
    testWidgets(
        'tappingToggle_withStatusTodo_dispatches_UpdateTaskStatus_inProgress',
        (tester) async {
      final task = _makeTask('task-toggle-1', TaskStatus.todo);
      await tester.pumpWidget(buildCard(task));

      await tester.tap(find.byKey(const ValueKey('task_status_toggle_task-toggle-1')));
      await tester.pump();

      verify(
        () => mockBloc.add(
          const UpdateTaskStatus(
            tripId: 'trip-1',
            taskId: 'task-toggle-1',
            next: TaskStatus.inProgress,
          ),
        ),
      ).called(1);
    });

    testWidgets(
        'tappingToggle_withStatusDone_dispatches_UpdateTaskStatus_todo',
        (tester) async {
      final task = _makeTask('task-toggle-2', TaskStatus.done);
      await tester.pumpWidget(buildCard(task));

      await tester.tap(find.byKey(const ValueKey('task_status_toggle_task-toggle-2')));
      await tester.pump();

      verify(
        () => mockBloc.add(
          const UpdateTaskStatus(
            tripId: 'trip-1',
            taskId: 'task-toggle-2',
            next: TaskStatus.todo,
          ),
        ),
      ).called(1);
    });

    testWidgets(
        'tappingToggle_withStatusInProgress_dispatches_UpdateTaskStatus_done',
        (tester) async {
      final task = _makeTask('task-toggle-3', TaskStatus.inProgress);
      await tester.pumpWidget(buildCard(task));

      await tester.tap(find.byKey(const ValueKey('task_status_toggle_task-toggle-3')));
      await tester.pump();

      verify(
        () => mockBloc.add(
          const UpdateTaskStatus(
            tripId: 'trip-1',
            taskId: 'task-toggle-3',
            next: TaskStatus.done,
          ),
        ),
      ).called(1);
    });

    testWidgets('toggle_todo_renders_unchecked_icon', (tester) async {
      final task = _makeTask('task-icon-1', TaskStatus.todo);
      await tester.pumpWidget(buildCard(task));

      // The IconButton with the toggle key should exist.
      expect(
        find.byKey(const ValueKey('task_status_toggle_task-icon-1')),
        findsOneWidget,
      );
      // Verify the radio_button_unchecked icon is present.
      expect(find.byIcon(Icons.radio_button_unchecked), findsWidgets);
    });

    testWidgets('toggle_inProgress_renders_timelapse_icon', (tester) async {
      final task = _makeTask('task-icon-2', TaskStatus.inProgress);
      await tester.pumpWidget(buildCard(task));

      expect(find.byIcon(Icons.timelapse), findsOneWidget);
    });

    testWidgets('toggle_done_renders_check_circle_icon', (tester) async {
      final task = _makeTask('task-icon-3', TaskStatus.done);
      await tester.pumpWidget(buildCard(task));

      // check_circle appears for the toggle.
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });
  });

  group('TaskStatusCycle extension', () {
    test('todo_next_is_inProgress', () {
      expect(TaskStatus.todo.next, TaskStatus.inProgress);
    });

    test('inProgress_next_is_done', () {
      expect(TaskStatus.inProgress.next, TaskStatus.done);
    });

    test('done_next_is_todo', () {
      expect(TaskStatus.done.next, TaskStatus.todo);
    });
  });
}

Task _makeTask(String id, TaskStatus status) => Task(
      id: id,
      tripId: 'trip-1',
      title: 'Test task',
      status: status,
      priority: TaskPriority.medium,
      createdBy: 'device-1',
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 1),
    );
