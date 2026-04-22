import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repository/destination_repository.dart';
import 'destination_event.dart';
import 'destination_state.dart';

class DestinationBloc extends Bloc<DestinationEvent, DestinationState> {
  final DestinationRepository _repository;

  DestinationBloc(this._repository) : super(const DestinationState.initial()) {
    on<LoadDestinations>(_onLoad, transformer: droppable());
    on<ProposeDestination>(_onPropose, transformer: droppable());
  }

  Future<void> _onLoad(
    LoadDestinations event,
    Emitter<DestinationState> emit,
  ) async {
    emit(const DestinationState.loading());
    try {
      final destinations = await _repository.list(event.tripId);
      emit(DestinationState.loaded(destinations: destinations));
    } catch (e) {
      emit(DestinationState.error(message: _friendlyMessage(e)));
    }
  }

  Future<void> _onPropose(
    ProposeDestination event,
    Emitter<DestinationState> emit,
  ) async {
    try {
      await _repository.propose(event.tripId, event.input);
      add(LoadDestinations(event.tripId));
    } catch (e) {
      emit(DestinationState.error(message: _friendlyMessage(e)));
    }
  }

  String _friendlyMessage(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 403) return 'You are not a member of this trip.';
      if (status == 400) return 'Please check the form fields and try again.';
      if (status != null && status >= 500) {
        return 'Server unavailable. Please try again later.';
      }
      return 'Network error. Please check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
