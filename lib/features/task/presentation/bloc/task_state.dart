import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/task.dart';

part 'task_state.freezed.dart';

@freezed
sealed class TaskState with _$TaskState {
  const factory TaskState.initial() = _Initial;
  const factory TaskState.loading() = _Loading;
  const factory TaskState.loaded({required List<Task> tasks}) = _Loaded;
  const factory TaskState.error({required String message}) = _Error;
}
