import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repository/trip_repository.dart';
import 'trip_detail_event.dart';
import 'trip_detail_state.dart';

class TripDetailBloc extends Bloc<TripDetailEvent, TripDetailState> {
  final TripRepository _repository;

  TripDetailBloc(this._repository) : super(const TripDetailState.initial()) {
    on<LoadTripDetail>(_onLoadTripDetail, transformer: droppable());
  }

  Future<void> _onLoadTripDetail(
    LoadTripDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    emit(const TripDetailState.loading());
    try {
      final trip = await _repository.getTrip(event.tripId);
      emit(TripDetailState.loaded(trip: trip));
    } catch (e) {
      emit(TripDetailState.failure(message: e.toString()));
    }
  }
}
