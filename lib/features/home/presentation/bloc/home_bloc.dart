import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../trip/domain/repository/trip_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TripRepository _repository;

  HomeBloc(this._repository) : super(const HomeState.initial()) {
    on<LoadTrips>(_onLoadTrips, transformer: droppable());
  }

  Future<void> _onLoadTrips(
    LoadTrips event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeState.loading());
    try {
      final trips = await _repository.listTrips();
      emit(HomeState.loaded(trips: trips));
    } catch (e) {
      emit(HomeState.failure(message: e.toString()));
    }
  }
}
