import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repository/trip_repository.dart';
import 'create_trip_event.dart';
import 'create_trip_state.dart';

class CreateTripBloc extends Bloc<CreateTripEvent, CreateTripState> {
  final TripRepository _repository;

  CreateTripBloc(this._repository) : super(const CreateTripState.initial()) {
    on<SubmitCreateTrip>(_onSubmitCreateTrip);
  }

  Future<void> _onSubmitCreateTrip(
    SubmitCreateTrip event,
    Emitter<CreateTripState> emit,
  ) async {
    emit(const CreateTripState.loading());
    try {
      final trip = await _repository.createTrip(
        title: event.title,
        description: event.description,
        currency: event.currency,
      );
      emit(CreateTripState.success(trip: trip));
    } catch (e) {
      emit(CreateTripState.failure(message: e.toString()));
    }
  }
}
