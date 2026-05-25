import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../trip/domain/model/trip_model.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widget/add_task_sheet.dart';
import '../widget/task_card.dart';

class TasksTab extends StatefulWidget {
  final String tripId;
  final TripModel trip;

  const TasksTab({
    super.key,
    required this.tripId,
    required this.trip,
  });

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  bool _fabPressed = false;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<TaskBloc>();
    bloc.state.maybeWhen(
      initial: () => bloc.add(LoadTasks(widget.tripId)),
      orElse: () {},
    );
  }

  void _openAddSheet(BuildContext context) {
    if (_fabPressed) return;
    _fabPressed = true;
    showAddTaskSheet(
      context,
      tripId: widget.tripId,
      trip: widget.trip,
      taskBloc: context.read<TaskBloc>(),
    ).whenComplete(() => _fabPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskBloc, TaskState>(
      listener: (context, state) {},
      builder: (context, state) {
        return state.when(
          initial: () => const Center(child: CircularProgressIndicator()),
          loading: () => const Center(
            key: ValueKey('tasks_loading'),
            child: CircularProgressIndicator(),
          ),
          error: (message) => Center(
            key: const ValueKey('tasks_error'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(message),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const ValueKey('tasks_retry_button'),
                  onPressed: () =>
                      context.read<TaskBloc>().add(LoadTasks(widget.tripId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          loaded: (tasks) {
            // Only render top-level tasks; subtasks are nested inside TaskCard.
            final topLevel =
                tasks.where((t) => t.parentTaskId == null).toList();

            if (topLevel.isEmpty) {
              return Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Nothing to do yet',
                          key: ValueKey('tasks_empty_title'),
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          key: const ValueKey('tasks_add_cta'),
                          onPressed: () => _openAddSheet(context),
                          child: const Text('Add a task'),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      key: const ValueKey('tasks_fab'),
                      tooltip: 'Add task',
                      onPressed: () => _openAddSheet(context),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              );
            }

            return Stack(
              children: [
                ListView.builder(
                  key: const ValueKey('tasks_list'),
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: topLevel.length,
                  itemBuilder: (context, index) {
                    final task = topLevel[index];
                    final taskBloc = context.read<TaskBloc>();
                    return TaskCard(
                      key: ValueKey('task_card_${task.id}'),
                      task: task,
                      trip: widget.trip,
                      onAddSubtask: () => showAddTaskSheet(
                        context,
                        tripId: widget.tripId,
                        trip: widget.trip,
                        taskBloc: taskBloc,
                        parentTaskId: task.id,
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    key: const ValueKey('tasks_fab'),
                    tooltip: 'Add task',
                    onPressed: () => _openAddSheet(context),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
