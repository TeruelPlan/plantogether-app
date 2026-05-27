import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';

class TaskStatusToggle extends StatelessWidget {
  final Task task;
  final String tripId;

  const TaskStatusToggle({
    super.key,
    required this.task,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: ValueKey('task_status_toggle_${task.id}'),
      onPressed: () {
        context.read<TaskBloc>().add(
              UpdateTaskStatus(
                tripId: tripId,
                taskId: task.id,
                next: task.status.next,
              ),
            );
      },
      icon: _icon(),
      tooltip: _tooltip(),
    );
  }

  Widget _icon() {
    return switch (task.status) {
      TaskStatus.todo => const Icon(Icons.radio_button_unchecked),
      TaskStatus.inProgress => const Icon(
          Icons.timelapse,
          color: Colors.orange,
        ),
      TaskStatus.done => const Icon(
          Icons.check_circle,
          color: Colors.green,
        ),
    };
  }

  String _tooltip() {
    return switch (task.status) {
      TaskStatus.todo => 'Mark in progress',
      TaskStatus.inProgress => 'Mark done',
      TaskStatus.done => 'Reopen',
    };
  }
}
