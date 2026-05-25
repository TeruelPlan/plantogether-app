import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/features/task/domain/entity/task.dart';
import 'package:plantogether_app/features/task/presentation/widget/task_card.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_member_model.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';

void main() {
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

  // Builds a TaskCard inside a minimal widget tree.
  Widget buildCard(Task task, {VoidCallback? onAddSubtask}) {
    return MaterialApp(
      home: Scaffold(
        body: TaskCard(
          task: task,
          trip: sampleTrip,
          onAddSubtask: onAddSubtask,
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
}
