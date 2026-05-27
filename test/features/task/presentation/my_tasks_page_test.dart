import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/features/task/domain/entity/task.dart';
import 'package:plantogether_app/features/task/presentation/bloc/my_tasks_bloc.dart';
import 'package:plantogether_app/features/task/presentation/bloc/my_tasks_event.dart';
import 'package:plantogether_app/features/task/presentation/bloc/my_tasks_state.dart';
import 'package:plantogether_app/features/task/presentation/page/my_tasks_page.dart';

class MockMyTasksBloc extends MockBloc<MyTasksEvent, MyTasksState>
    implements MyTasksBloc {}

void main() {
  Task makeTask(String id, String tripId) => Task(
        id: id,
        tripId: tripId,
        title: 'Task $id',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        createdBy: 'device-1',
        createdAt: DateTime.utc(2026, 5, 1),
        updatedAt: DateTime.utc(2026, 5, 1),
      );

  Widget buildWidget(MockMyTasksBloc bloc) {
    return MaterialApp(
      home: BlocProvider<MyTasksBloc>.value(
        value: bloc,
        child: const MyTasksView(),
      ),
    );
  }

  group('MyTasksPage', () {
    testWidgets('loaded_withItems_rendersGroupedSections', (tester) async {
      final bloc = MockMyTasksBloc();

      final items = [
        MyTaskItem(
          task: makeTask('t1', 'trip-1'),
          tripId: 'trip-1',
          tripName: 'Paris Trip',
        ),
        MyTaskItem(
          task: makeTask('t2', 'trip-1'),
          tripId: 'trip-1',
          tripName: 'Paris Trip',
        ),
        MyTaskItem(
          task: makeTask('t3', 'trip-2'),
          tripId: 'trip-2',
          tripName: 'Rome Trip',
        ),
      ];

      whenListen(
        bloc,
        Stream.fromIterable([
          MyTasksState.loaded(items: items),
        ]),
        initialState: MyTasksState.loaded(items: items),
      );

      await tester.pumpWidget(buildWidget(bloc));
      await tester.pump();

      // Section headers should appear.
      expect(find.text('Paris Trip'), findsOneWidget);
      expect(find.text('Rome Trip'), findsOneWidget);

      // Per-task items.
      expect(
        find.byKey(const ValueKey('my_task_item_t1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('my_task_item_t2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('my_task_item_t3')),
        findsOneWidget,
      );

      // The list container.
      expect(find.byKey(const ValueKey('my_tasks_list')), findsOneWidget);
    });

    testWidgets('loaded_empty_rendersAllCaughtUp', (tester) async {
      final bloc = MockMyTasksBloc();
      final completer = Completer<void>();

      whenListen(
        bloc,
        Stream<MyTasksState>.fromFuture(
          completer.future
              .then((_) => const MyTasksState.loaded(items: [])),
        ),
        initialState: const MyTasksState.loaded(items: []),
      );

      await tester.pumpWidget(buildWidget(bloc));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('my_tasks_empty_state')),
        findsOneWidget,
      );
      expect(find.text("You're all caught up"), findsOneWidget);
    });

    testWidgets('loaded_withFailedTripNames_rendersPartialFailureBanner',
        (tester) async {
      final bloc = MockMyTasksBloc();

      final items = [
        MyTaskItem(
          task: makeTask('t1', 'trip-2'),
          tripId: 'trip-2',
          tripName: 'Rome Trip',
        ),
      ];

      whenListen(
        bloc,
        Stream.fromIterable([
          MyTasksState.loaded(
            items: items,
            failedTripNames: ['Paris Trip'],
          ),
        ]),
        initialState: MyTasksState.loaded(
          items: items,
          failedTripNames: ['Paris Trip'],
        ),
      );

      await tester.pumpWidget(buildWidget(bloc));
      await tester.pump();

      // The failed banner should mention the trip name.
      expect(find.textContaining('Paris Trip'), findsOneWidget);
      // Items from the successful trip still render.
      expect(
        find.byKey(const ValueKey('my_task_item_t1')),
        findsOneWidget,
      );
    });
  });
}
