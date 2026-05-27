import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/task.dart';

part 'my_tasks_state.freezed.dart';

class MyTaskItem extends Equatable {
  final Task task;
  final String tripId;
  final String tripName;

  const MyTaskItem({
    required this.task,
    required this.tripId,
    required this.tripName,
  });

  @override
  List<Object?> get props => [task.id, tripId];
}

@freezed
sealed class MyTasksState with _$MyTasksState {
  const factory MyTasksState.initial() = _Initial;
  const factory MyTasksState.loading() = _Loading;
  const factory MyTasksState.loaded({
    required List<MyTaskItem> items,
    @Default([]) List<String> failedTripNames,
  }) = _Loaded;
  const factory MyTasksState.error({required String message}) = _Error;
}
