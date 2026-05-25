import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/task.dart';
import '../../domain/repository/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _repository;

  TaskBloc(this._repository) : super(const TaskState.initial()) {
    on<LoadTasks>(_onLoad, transformer: droppable());
    on<CreateTask>(_onCreate, transformer: droppable());
    on<UpdateTaskStatus>(_onUpdateStatus, transformer: droppable());
  }

  Future<void> _onLoad(LoadTasks event, Emitter<TaskState> emit) async {
    emit(const TaskState.loading());
    try {
      final tasks = await _repository.list(event.tripId);
      emit(TaskState.loaded(tasks: tasks));
    } on Exception catch (e) {
      emit(TaskState.error(message: _readableMessage(e)));
    }
  }

  Future<void> _onCreate(CreateTask event, Emitter<TaskState> emit) async {
    emit(const TaskState.loading());
    try {
      await _repository.create(event.tripId, event.input);
      add(LoadTasks(event.tripId));
    } on Exception catch (e) {
      emit(TaskState.error(message: _readableMessage(e)));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateTaskStatus event,
    Emitter<TaskState> emit,
  ) async {
    final current = state;
    // No-op if not in loaded state.
    final currentTasks = current.whenOrNull(loaded: (tasks) => tasks);
    if (currentTasks == null) return;

    // Build optimistic state by searching root tasks and their subtasks.
    final optimisticTasks = _applyStatusUpdate(
      currentTasks,
      event.taskId,
      event.next,
    );
    emit(TaskState.loaded(tasks: optimisticTasks));

    try {
      await _repository.updateStatus(event.taskId, event.next);
      add(LoadTasks(event.tripId));
    } on Exception catch (e) {
      // Rollback to the snapshot, then surface the error.
      emit(current);
      emit(TaskState.error(message: _readableMessage(e)));
    }
  }

  /// Applies a status update to [taskId] anywhere in the two-level task tree
  /// (root tasks and their direct subtasks). Returns a new list; never mutates.
  List<Task> _applyStatusUpdate(
    List<Task> tasks,
    String taskId,
    TaskStatus next,
  ) {
    return tasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(
          status: next,
          completedAt: next == TaskStatus.done ? DateTime.now() : null,
        );
      }
      // Check one level of subtasks.
      final updatedSubtasks = task.subtasks.map((subtask) {
        if (subtask.id == taskId) {
          return subtask.copyWith(
            status: next,
            completedAt: next == TaskStatus.done ? DateTime.now() : null,
          );
        }
        return subtask;
      }).toList();
      return task.copyWith(subtasks: updatedSubtasks);
    }).toList();
  }

  String _readableMessage(Exception e) {
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) return msg.substring('Exception: '.length);
    return msg;
  }
}
