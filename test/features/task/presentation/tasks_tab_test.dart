import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/task/domain/entity/task.dart';
import 'package:plantogether_app/features/task/presentation/bloc/task_bloc.dart';
import 'package:plantogether_app/features/task/presentation/bloc/task_event.dart';
import 'package:plantogether_app/features/task/presentation/bloc/task_state.dart';
import 'package:plantogether_app/features/task/presentation/page/tasks_tab.dart';
import 'package:plantogether_app/features/task/presentation/widget/task_card.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_member_model.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';

class MockTaskBloc extends MockBloc<TaskEvent, TaskState> implements TaskBloc {}

void main() {
  const tripId = 'trip-1';

  final sampleTrip = TripModel(
    id: tripId,
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

  final sampleTask = Task(
    id: 'task-1',
    tripId: tripId,
    title: 'Buy sunscreen',
    status: TaskStatus.todo,
    priority: TaskPriority.medium,
    createdBy: 'device-1',
    createdAt: DateTime.utc(2026, 5, 1),
    updatedAt: DateTime.utc(2026, 5, 1),
  );

  Widget buildWidget(MockTaskBloc bloc) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<TaskBloc>.value(
          value: bloc,
          child: TasksTab(tripId: tripId, trip: sampleTrip),
        ),
      ),
    );
  }

  testWidgets('emptyState_rendersNothingToDo', (tester) async {
    final bloc = MockTaskBloc();
    // initState will call LoadTasks because state is initial; we use loaded directly
    whenListen(
      bloc,
      Stream.fromIterable([TaskState.loaded(tasks: const [])]),
      initialState: TaskState.loaded(tasks: const []),
    );

    await tester.pumpWidget(buildWidget(bloc));
    await tester.pump();

    expect(find.text('Nothing to do yet'), findsOneWidget);
    expect(find.text('Add a task'), findsOneWidget);
  });

  testWidgets('loadedState_rendersTaskCards', (tester) async {
    final bloc = MockTaskBloc();
    whenListen(
      bloc,
      Stream.fromIterable([TaskState.loaded(tasks: [sampleTask])]),
      initialState: TaskState.loaded(tasks: [sampleTask]),
    );

    await tester.pumpWidget(buildWidget(bloc));
    await tester.pump();

    expect(find.byType(TaskCard), findsOneWidget);
  });

  testWidgets('loadingState_rendersProgressIndicator', (tester) async {
    final bloc = MockTaskBloc();
    final completer = Completer<void>();
    whenListen(
      bloc,
      Stream<TaskState>.fromFuture(
        completer.future.then((_) => TaskState.loaded(tasks: const [])),
      ),
      initialState: const TaskState.loading(),
    );

    await tester.pumpWidget(buildWidget(bloc));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('fab_doubleTap_opensOnlyOneSheet', (tester) async {
    final bloc = MockTaskBloc();
    whenListen(
      bloc,
      Stream.fromIterable([TaskState.loaded(tasks: [sampleTask])]),
      initialState: TaskState.loaded(tasks: [sampleTask]),
    );

    await tester.pumpWidget(buildWidget(bloc));
    await tester.pump();

    final fab = find.byKey(const ValueKey('tasks_fab'));
    expect(fab, findsOneWidget);

    // Rapid double-tap: the guard flag prevents a second sheet from opening.
    // warnIfMissed: false because the FAB lives in a Positioned widget at the
    // bottom of a Stack and can be outside the test viewport bounds.
    await tester.tap(fab, warnIfMissed: false);
    await tester.tap(fab, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Only one modal bottom sheet should be present in the widget tree.
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('statusChip_todo_dispatchesApplyTaskFilters', (tester) async {
    final bloc = MockTaskBloc();
    whenListen(
      bloc,
      Stream.fromIterable([TaskState.loaded(tasks: [sampleTask])]),
      initialState: TaskState.loaded(tasks: [sampleTask]),
    );

    await tester.pumpWidget(buildWidget(bloc));
    await tester.pump();

    // The filter chip row is rendered above the task list when tasks are present.
    // Use warnIfMissed: false in case the chip is in a scrollable area.
    await tester.tap(
      find.byKey(const ValueKey('task_filter_status_todo')),
      warnIfMissed: false,
    );
    await tester.pump();

    verify(
      () => bloc.add(
        const ApplyTaskFilters(
          tripId: tripId,
          status: TaskStatus.todo,
        ),
      ),
    ).called(1);
  });

  testWidgets(
      'emptyFilteredState_rendersNoMatchMessage_and_clearFiltersButton',
      (tester) async {
    final bloc = MockTaskBloc();

    // Use a stream controller to manually control state transitions.
    final controller = StreamController<TaskState>();

    whenListen(
      bloc,
      controller.stream,
      initialState: TaskState.loaded(tasks: [sampleTask]),
    );

    await tester.pumpWidget(buildWidget(bloc));
    await tester.pump();

    // Tap the To Do chip to set _activeStatus = TaskStatus.todo in local state.
    await tester.tap(
      find.byKey(const ValueKey('task_filter_status_todo')),
      warnIfMissed: false,
    );
    await tester.pump();

    // Now simulate the bloc returning empty tasks (filter applied server-side).
    controller.add(const TaskState.loaded(tasks: []));
    await tester.pump();

    // With a local filter active and empty results, must show "no match" message.
    expect(find.text('No tasks match your filters'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('task_filter_clear_button')),
      findsOneWidget,
    );

    await controller.close();
  });
}
