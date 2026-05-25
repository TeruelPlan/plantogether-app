import 'package:flutter/material.dart';

import '../../../trip/domain/model/trip_model.dart';
import '../../domain/entity/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final TripModel trip;
  final VoidCallback? onAddSubtask;

  const TaskCard({
    super.key,
    required this.task,
    required this.trip,
    this.onAddSubtask,
  });

  String _resolveDisplayName(String? assigneeId) {
    if (assigneeId == null) return 'Unassigned';
    final member =
        trip.members.where((m) => m.memberId == assigneeId).firstOrNull;
    return member?.displayName ?? 'Unassigned';
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  String? _formatDeadline(DateTime? deadline) {
    if (deadline == null) return null;
    final now = DateTime.now();
    final diff = deadline.difference(now).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days';
  }

  @override
  Widget build(BuildContext context) {
    final isTopLevel = task.parentTaskId == null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: task.status == TaskStatus.done
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            // Priority + status row
            Row(
              children: [
                Chip(
                  key: ValueKey('task_priority_${task.id}'),
                  label: Text(
                    _priorityLabel(task.priority),
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor:
                      _priorityColor(task.priority).withOpacity(0.15),
                  side:
                      BorderSide(color: _priorityColor(task.priority), width: 1),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Text(
                  _statusLabel(task.status),
                  key: ValueKey('task_status_${task.id}'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _resolveDisplayName(task.assigneeId),
              key: ValueKey('task_assignee_${task.id}'),
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            if (_formatDeadline(task.deadline) != null) ...[
              const SizedBox(height: 2),
              Text(
                _formatDeadline(task.deadline)!,
                key: ValueKey('task_deadline_${task.id}'),
                style: TextStyle(
                  fontSize: 12,
                  color: task.deadline != null &&
                          task.deadline!.isBefore(DateTime.now())
                      ? Colors.red
                      : Colors.grey[600],
                ),
              ),
            ],
            // Subtask count indicator
            if (task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${task.subtaskDoneCount}/${task.subtaskTotal} subtasks done',
                key: ValueKey('task_subtask_count_${task.id}'),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              // Subtask rows
              ...task.subtasks.map(
                (subtask) => Padding(
                  key: ValueKey('subtask_tile_${subtask.id}'),
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      Icon(
                        subtask.status == TaskStatus.done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: subtask.status == TaskStatus.done
                            ? Colors.green
                            : Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subtask.title,
                          style: TextStyle(
                            fontSize: 13,
                            decoration: subtask.status == TaskStatus.done
                                ? TextDecoration.lineThrough
                                : null,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // "Add subtask" button — only on top-level tasks
            if (isTopLevel) ...[
              const SizedBox(height: 4),
              TextButton(
                key: ValueKey('add_subtask_button_${task.id}'),
                onPressed: onAddSubtask,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('+ Add subtask'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
