import 'package:equatable/equatable.dart';

import '../entity/task.dart';

abstract class TaskRepository {
  Future<Task> create(String tripId, CreateTaskInput input);
  Future<List<Task>> list(String tripId, {String? assignee, TaskStatus? status});
  Future<Task> updateStatus(String taskId, TaskStatus next);
}

class CreateTaskInput extends Equatable {
  final String title;
  final String? description;
  final String? assigneeId;
  final TaskPriority priority;
  final DateTime? deadline;
  final String? parentTaskId;

  const CreateTaskInput({
    required this.title,
    this.description,
    this.assigneeId,
    this.priority = TaskPriority.medium,
    this.deadline,
    this.parentTaskId,
  });

  @override
  List<Object?> get props =>
      [title, description, assigneeId, priority, deadline, parentTaskId];
}
