import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/task/domain/repository/task_repository.dart';
import 'package:plantogether_app/features/task/presentation/bloc/task_bloc.dart';
import 'package:plantogether_app/features/task/presentation/bloc/task_event.dart';
import 'package:plantogether_app/features/task/presentation/bloc/task_state.dart';
import 'package:plantogether_app/features/task/presentation/widget/add_task_sheet.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_member_model.dart';
import 'package:plantogether_app/features/trip/domain/model/trip_model.dart';

class MockTaskBloc extends MockBloc<TaskEvent, TaskState> implements TaskBloc {}

class FakeCreateTaskInput extends Fake implements CreateTaskInput {}

class FakeTaskEvent extends Fake implements TaskEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCreateTaskInput());
    registerFallbackValue(FakeTaskEvent());
  });

  const tripId = 'trip-1';
  const parentTaskId = 'parent-task-1';

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

  // Opens the sheet via a button so showAddTaskSheet receives a valid context.
  Widget buildScaffold(MockTaskBloc bloc) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showAddTaskSheet(
              ctx,
              tripId: tripId,
              trip: sampleTrip,
              taskBloc: bloc,
              parentTaskId: parentTaskId,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('AddSubtaskSheet', () {
    testWidgets('showsAddSubtaskTitle', (tester) async {
      final controller = StreamController<TaskState>.broadcast();
      final bloc = MockTaskBloc();
      whenListen(
        bloc,
        controller.stream,
        initialState: const TaskState.initial(),
      );

      await tester.pumpWidget(buildScaffold(bloc));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Add subtask'), findsOneWidget);
      await controller.close();
    });

    testWidgets('blankTitle_showsSubtaskError_noDispatch', (tester) async {
      final controller = StreamController<TaskState>.broadcast();
      final bloc = MockTaskBloc();
      whenListen(
        bloc,
        controller.stream,
        initialState: const TaskState.initial(),
      );

      await tester.pumpWidget(buildScaffold(bloc));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('task_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Subtask title is required'), findsOneWidget);
      verifyNever(() => bloc.add(any()));
      await controller.close();
    });

    testWidgets('validForm_dispatchesCreateTask_withParentTaskId',
        (tester) async {
      final controller = StreamController<TaskState>.broadcast();
      final bloc = MockTaskBloc();
      whenListen(
        bloc,
        controller.stream,
        initialState: const TaskState.initial(),
      );

      await tester.pumpWidget(buildScaffold(bloc));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('task_title_field')),
        'Pack towels',
      );
      await tester.tap(find.byKey(const ValueKey('task_submit_button')));
      await tester.pump();

      final captured = verify(() => bloc.add(captureAny())).captured;
      expect(captured, hasLength(1));
      final event = captured.first as CreateTask;
      expect(event.tripId, tripId);
      expect(event.input.title, 'Pack towels');
      expect(event.input.parentTaskId, parentTaskId);
      await controller.close();
    });
  });
}
