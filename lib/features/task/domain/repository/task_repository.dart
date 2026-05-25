import '../entity/task.dart';

abstract class TaskRepository {
  Future<Task> create(String tripId, CreateTaskInput input);
  Future<List<Task>> list(String tripId);
}

class CreateTaskInput {
  final String title;
  final String? description;
  final String? assigneeId;
  final TaskPriority priority;
  final DateTime? deadline;

  const CreateTaskInput({
    required this.title,
    this.description,
    this.assigneeId,
    this.priority = TaskPriority.medium,
    this.deadline,
  });
}
