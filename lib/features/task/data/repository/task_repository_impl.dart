import 'package:dio/dio.dart';

import '../../domain/entity/task.dart';
import '../../domain/repository/task_repository.dart';
import '../datasource/task_remote_datasource.dart';
import '../model/task_dto.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDatasource _remoteDatasource;

  TaskRepositoryImpl(this._remoteDatasource);

  @override
  Future<Task> create(String tripId, CreateTaskInput input) async {
    try {
      final body = CreateTaskRequestDto(
        title: input.title,
        description: input.description,
        assigneeId: input.assigneeId,
        priority: input.priority.toWire(),
        deadline: input.deadline?.toUtc().toIso8601String(),
      );
      final dto = await _remoteDatasource.create(tripId, body);
      return dto.toDomain();
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Failed to create task');
    }
  }

  @override
  Future<List<Task>> list(String tripId) async {
    try {
      final dtos = await _remoteDatasource.list(tripId);
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Failed to load tasks');
    }
  }

  Exception _mapError(DioException e, {required String fallback}) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String? detail;
    if (data is Map<String, dynamic>) {
      detail = data['detail'] as String?;
    }
    if (statusCode == 403) {
      return Exception('You are not a member of this trip');
    }
    if (statusCode == 400) {
      return Exception(detail ?? 'Invalid request. Please check your inputs');
    }
    if (statusCode != null && statusCode >= 500) {
      return Exception('Server error. Please try again later');
    }
    return Exception('Network error. Please check your connection');
  }
}
