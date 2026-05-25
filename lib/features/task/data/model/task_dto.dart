import 'package:json_annotation/json_annotation.dart';

import '../../domain/entity/task.dart';

part 'task_dto.g.dart';

@JsonSerializable()
class SubtaskSummaryDto {
  final int total;
  final int done;

  const SubtaskSummaryDto({
    required this.total,
    required this.done,
  });

  factory SubtaskSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$SubtaskSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SubtaskSummaryDtoToJson(this);
}

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
  final List<TaskDto>? subtasks;
  final SubtaskSummaryDto? subtaskSummary;

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
    this.subtasks,
    this.subtaskSummary,
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
        subtasks: subtasks?.map((s) => s.toDomain()).toList() ?? [],
      );
}

@JsonSerializable(includeIfNull: false)
class CreateTaskRequestDto {
  final String title;
  final String? description;
  final String? assigneeId;
  final String? priority;
  final String? deadline;
  final String? parentTaskId;

  const CreateTaskRequestDto({
    required this.title,
    this.description,
    this.assigneeId,
    this.priority,
    this.deadline,
    this.parentTaskId,
  });

  Map<String, dynamic> toJson() => _$CreateTaskRequestDtoToJson(this);

  factory CreateTaskRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateTaskRequestDtoFromJson(json);
}
