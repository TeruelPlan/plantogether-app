import 'package:equatable/equatable.dart';

import '../../domain/entity/task.dart';
import '../../domain/repository/task_repository.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {
  final String tripId;

  const LoadTasks(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class CreateTask extends TaskEvent {
  final String tripId;
  final CreateTaskInput input;

  const CreateTask({required this.tripId, required this.input});

  @override
  List<Object?> get props => [tripId, input];
}

class UpdateTaskStatus extends TaskEvent {
  final String tripId;
  final String taskId;
  final TaskStatus next;

  const UpdateTaskStatus({
    required this.tripId,
    required this.taskId,
    required this.next,
  });

  @override
  List<Object?> get props => [tripId, taskId, next];
}
