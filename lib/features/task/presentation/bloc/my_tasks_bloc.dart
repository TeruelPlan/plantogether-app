import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/security/device_id_service.dart';
import '../../../trip/domain/repository/trip_repository.dart';
import '../../domain/repository/task_repository.dart';
import 'my_tasks_event.dart';
import 'my_tasks_state.dart';

class MyTasksBloc extends Bloc<MyTasksEvent, MyTasksState> {
  final TripRepository _tripRepository;
  final TaskRepository _taskRepository;
  final DeviceIdService _deviceIdService;

  MyTasksBloc(
    this._tripRepository,
    this._taskRepository,
    this._deviceIdService,
  ) : super(const MyTasksState.initial()) {
    on<LoadMyTasks>(_onLoad, transformer: restartable());
  }

  Future<void> _onLoad(
    LoadMyTasks event,
    Emitter<MyTasksState> emit,
  ) async {
    emit(const MyTasksState.loading());
    try {
      final deviceId = await _deviceIdService.getOrCreateDeviceId();
      final trips = await _tripRepository.listTrips();
      final active = trips.where((t) => t.status != 'ARCHIVED').toList();

      final failedNames = <String>[];
      final allItems = <MyTaskItem>[];

      await Future.wait(active.map((trip) async {
        try {
          final tasks = await _taskRepository.list(
            trip.id,
            assignee: deviceId,
          );
          for (final task in tasks) {
            allItems.add(
              MyTaskItem(task: task, tripId: trip.id, tripName: trip.title),
            );
          }
        } on Object catch (_) {
          failedNames.add(trip.title);
        }
      }));

      emit(MyTasksState.loaded(
        items: allItems,
        failedTripNames: failedNames,
      ));
    } on Exception catch (e) {
      emit(MyTasksState.error(message: _readableMessage(e)));
    }
  }

  String _readableMessage(Exception e) {
    final msg = e.toString();
    return msg.startsWith('Exception: ') ? msg.substring('Exception: '.length) : msg;
  }
}
