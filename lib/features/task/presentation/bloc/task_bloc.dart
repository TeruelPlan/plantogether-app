import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repository/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _repository;

  TaskBloc(this._repository) : super(const TaskState.initial()) {
    on<LoadTasks>(_onLoad, transformer: droppable());
    on<CreateTask>(_onCreate, transformer: droppable());
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

  String _readableMessage(Exception e) {
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) return msg.substring('Exception: '.length);
    return msg;
  }
}
