import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/model/trip_model.dart';
import '../../domain/repository/trip_repository.dart';
import 'join_trip_event.dart';
import 'join_trip_state.dart';

class JoinTripBloc extends Bloc<JoinTripEvent, JoinTripState> {
  final TripRepository _repository;

  JoinTripBloc(this._repository) : super(const JoinTripState.initial()) {
    on<LoadPreview>(_onLoadPreview);
    on<SubmitJoin>(_onSubmitJoin);
  }

  Future<void> _onLoadPreview(
    LoadPreview event,
    Emitter<JoinTripState> emit,
  ) async {
    emit(const JoinTripState.loadingPreview());
    try {
      final preview =
          await _repository.getTripPreview(event.tripId, event.token);
      if (preview.isMember) {
        // Already a member — construct a minimal TripModel for navigation
        final trip = TripModel(
          id: preview.id,
          title: preview.title,
          description: preview.description,
          status: 'PLANNING',
          createdBy: '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        );
        emit(JoinTripState.joined(trip: trip));
      } else {
        emit(JoinTripState.previewLoaded(preview: preview));
      }
    } catch (e) {
      emit(JoinTripState.failure(message: e.toString()));
    }
  }

  Future<void> _onSubmitJoin(
    SubmitJoin event,
    Emitter<JoinTripState> emit,
  ) async {
    emit(const JoinTripState.joining());
    try {
      final trip = await _repository.joinTrip(event.tripId, event.token);
      emit(JoinTripState.joined(trip: trip));
    } catch (e) {
      emit(JoinTripState.failure(message: e.toString()));
    }
  }
}
