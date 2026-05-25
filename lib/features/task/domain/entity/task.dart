import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';

enum TaskStatus {
  todo,
  inProgress,
  done;

  String toWire() {
    switch (this) {
      case TaskStatus.todo:
        return 'TODO';
      case TaskStatus.inProgress:
        return 'IN_PROGRESS';
      case TaskStatus.done:
        return 'DONE';
    }
  }

  static TaskStatus fromWire(String s) {
    switch (s.toUpperCase()) {
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'DONE':
        return TaskStatus.done;
      case 'TODO':
      default:
        return TaskStatus.todo;
    }
  }
}

enum TaskPriority {
  high,
  medium,
  low;

  String toWire() => name.toUpperCase();

  static TaskPriority fromWire(String s) {
    switch (s.toUpperCase()) {
      case 'HIGH':
        return TaskPriority.high;
      case 'LOW':
        return TaskPriority.low;
      case 'MEDIUM':
      default:
        return TaskPriority.medium;
    }
  }
}

@freezed
sealed class Task with _$Task {
  const factory Task({
    required String id,
    required String tripId,
    String? parentTaskId,
    required String title,
    String? description,
    String? assigneeId,
    required TaskStatus status,
    required TaskPriority priority,
    DateTime? deadline,
    required String createdBy,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;
}
