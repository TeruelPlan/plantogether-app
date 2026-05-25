import '../../../../core/network/dio_client.dart';
import '../../domain/entity/task.dart';
import '../model/task_dto.dart';

class TaskRemoteDatasource {
  final DioClient _dioClient;

  TaskRemoteDatasource(this._dioClient);

  Future<TaskDto> create(String tripId, CreateTaskRequestDto body) async {
    final response = await _dioClient.dio.post(
      '/api/v1/trips/$tripId/tasks',
      data: body.toJson(),
    );
    return TaskDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TaskDto>> list(String tripId) async {
    final response = await _dioClient.dio.get(
      '/api/v1/trips/$tripId/tasks',
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => TaskDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TaskDto> updateStatus(String taskId, TaskStatus next) async {
    final body = UpdateTaskStatusRequestDto(status: next.toWire());
    final response = await _dioClient.dio.patch(
      '/api/v1/tasks/$taskId/status',
      data: body.toJson(),
    );
    return TaskDto.fromJson(response.data as Map<String, dynamic>);
  }
}
