import 'package:json_annotation/json_annotation.dart';

import '../../domain/entity/task.dart';

part 'task_dto.g.dart';

@JsonSerializable()
class TaskDto {
  final String id;
  final String tripId;
  final String? parentTaskId;
  final String title;
  final String? description;
  final String? assigneeId;
  final String status;
  final String priority;
  final DateTime? deadline;
  final String createdBy;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskDto({
    required this.id,
    required this.tripId,
    this.parentTaskId,
    required this.title,
    this.description,
    this.assigneeId,
    required this.status,
    required this.priority,
    this.deadline,
    required this.createdBy,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskDto.fromJson(Map<String, dynamic> json) =>
      _$TaskDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TaskDtoToJson(this);

  Task toDomain() => Task(
        id: id,
        tripId: tripId,
        parentTaskId: parentTaskId,
        title: title,
        description: description,
        assigneeId: assigneeId,
        status: TaskStatus.fromWire(status),
        priority: TaskPriority.fromWire(priority),
        deadline: deadline,
        createdBy: createdBy,
        completedAt: completedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

@JsonSerializable(includeIfNull: false)
class CreateTaskRequestDto {
  final String title;
  final String? description;
  final String? assigneeId;
  final String? priority;
  final String? deadline;

  const CreateTaskRequestDto({
    required this.title,
    this.description,
    this.assigneeId,
    this.priority,
    this.deadline,
  });

  Map<String, dynamic> toJson() => _$CreateTaskRequestDtoToJson(this);

  factory CreateTaskRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateTaskRequestDtoFromJson(json);
}
