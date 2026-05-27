import 'package:equatable/equatable.dart';

abstract class MyTasksEvent extends Equatable {
  const MyTasksEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyTasks extends MyTasksEvent {
  const LoadMyTasks();

  @override
  List<Object?> get props => [];
}
