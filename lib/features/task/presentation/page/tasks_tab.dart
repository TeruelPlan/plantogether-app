import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../trip/domain/model/trip_model.dart';
import '../../domain/entity/task.dart';
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
  String? _activeAssignee;
  TaskStatus? _activeStatus;

  bool get _hasActiveFilters =>
      _activeAssignee != null || _activeStatus != null;

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

  void _applyFilters(BuildContext context, {
    String? assignee,
    TaskStatus? status,
    bool clearAll = false,
  }) {
    if (clearAll) {
      setState(() {
        _activeAssignee = null;
        _activeStatus = null;
      });
      context.read<TaskBloc>().add(LoadTasks(widget.tripId));
      return;
    }

    setState(() {
      _activeAssignee = assignee;
      _activeStatus = status;
    });

    if (assignee == null && status == null) {
      context.read<TaskBloc>().add(LoadTasks(widget.tripId));
    } else {
      context.read<TaskBloc>().add(ApplyTaskFilters(
        tripId: widget.tripId,
        assignee: assignee,
        status: status,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskBloc, TaskState>(
      listener: (context, state) {
        state.whenOrNull(
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message.isNotEmpty ? message : "Couldn't update the task",
                ),
              ),
            );
          },
        );
      },
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
            final topLevel =
                tasks.where((t) => t.parentTaskId == null).toList();

            if (topLevel.isEmpty && _hasActiveFilters) {
              return Column(
                children: [
                  _FilterRow(
                    trip: widget.trip,
                    activeAssignee: _activeAssignee,
                    activeStatus: _activeStatus,
                    onApply: _applyFilters,
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.filter_list_off,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No tasks match your filters',
                            key: ValueKey('tasks_filtered_empty_title'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            key: const ValueKey('task_filter_clear_button'),
                            onPressed: () =>
                                _applyFilters(context, clearAll: true),
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

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

            return Column(
              children: [
                _FilterRow(
                  trip: widget.trip,
                  activeAssignee: _activeAssignee,
                  activeStatus: _activeStatus,
                  onApply: _applyFilters,
                ),
                Expanded(
                  child: Stack(
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

class _FilterRow extends StatelessWidget {
  final TripModel trip;
  final String? activeAssignee;
  final TaskStatus? activeStatus;
  final void Function(
    BuildContext context, {
    String? assignee,
    TaskStatus? status,
    bool clearAll,
  }) onApply;

  const _FilterRow({
    required this.trip,
    required this.activeAssignee,
    required this.activeStatus,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Status filter chips
          FilterChip(
            key: const ValueKey('task_filter_status_all'),
            label: const Text('All'),
            selected: activeStatus == null,
            onSelected: (_) => onApply(
              context,
              assignee: activeAssignee,
              status: null,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const ValueKey('task_filter_status_todo'),
            label: const Text('To Do'),
            selected: activeStatus == TaskStatus.todo,
            onSelected: (_) => onApply(
              context,
              assignee: activeAssignee,
              status: TaskStatus.todo,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const ValueKey('task_filter_status_inprogress'),
            label: const Text('In Progress'),
            selected: activeStatus == TaskStatus.inProgress,
            onSelected: (_) => onApply(
              context,
              assignee: activeAssignee,
              status: TaskStatus.inProgress,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const ValueKey('task_filter_status_done'),
            label: const Text('Done'),
            selected: activeStatus == TaskStatus.done,
            onSelected: (_) => onApply(
              context,
              assignee: activeAssignee,
              status: TaskStatus.done,
            ),
          ),
          const SizedBox(width: 16),
          // Assignee filter chips
          FilterChip(
            key: const ValueKey('task_filter_assignee_anyone'),
            label: const Text('Anyone'),
            selected: activeAssignee == null,
            onSelected: (_) => onApply(
              context,
              assignee: null,
              status: activeStatus,
            ),
          ),
          ...trip.members.map((member) {
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                key: ValueKey('task_filter_assignee_${member.memberId}'),
                label: Text(member.displayName),
                selected: activeAssignee == member.memberId,
                onSelected: (_) => onApply(
                  context,
                  assignee: member.memberId,
                  status: activeStatus,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
