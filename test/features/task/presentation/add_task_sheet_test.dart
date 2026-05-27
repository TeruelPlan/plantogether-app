import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plantogether_app/features/task/domain/entity/task.dart';
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

  // Opens the sheet by tapping a button that calls showAddTaskSheet.
  // The bloc is NOT wrapped in an outer BlocProvider so that only the
  // BlocProvider.value inside showAddTaskSheet subscribes to bloc.stream.
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
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('AddTaskSheet', () {
    testWidgets('blankTitle_showsInlineError_noDispatch', (tester) async {
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

      expect(find.text('Task title is required'), findsOneWidget);
      verifyNever(() => bloc.add(any()));
      await controller.close();
    });

    testWidgets('validForm_dispatchesCreateTask', (tester) async {
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
        'Buy sunscreen',
      );
      await tester.tap(find.byKey(const ValueKey('task_submit_button')));
      await tester.pump();

      final captured = verify(() => bloc.add(captureAny())).captured;
      expect(captured, hasLength(1));
      final event = captured.first as CreateTask;
      expect(event.tripId, tripId);
      expect(event.input.title, 'Buy sunscreen');
      expect(event.input.priority, TaskPriority.medium);
      expect(event.input.assigneeId, isNull);
      await controller.close();
    });

    testWidgets('backgroundLoaded_doesNotCloseSheet', (tester) async {
      final controller = StreamController<TaskState>.broadcast();
      final bloc = MockTaskBloc();
      // _createRequested is never set, so a loaded event should not close the sheet.
      whenListen(
        bloc,
        controller.stream,
        initialState: const TaskState.initial(),
      );

      await tester.pumpWidget(buildScaffold(bloc));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Emit a loaded state without the user having submitted the form.
      controller.add(const TaskState.loaded(tasks: []));
      await tester.pumpAndSettle();

      // Sheet should still be open because _createRequested was never set.
      expect(find.byKey(const ValueKey('task_title_field')), findsOneWidget);
      await controller.close();
    });
  });
}
