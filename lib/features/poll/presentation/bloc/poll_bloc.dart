import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repository/poll_repository.dart';
import 'poll_event.dart';
import 'poll_state.dart';

class PollBloc extends Bloc<PollEvent, PollState> {
  final PollRepository _repository;

  PollBloc(this._repository) : super(const PollState.initial()) {
    on<LoadPolls>(_onLoadPolls, transformer: droppable());
    on<CreatePoll>(_onCreatePoll, transformer: droppable());
  }

  Future<void> _onLoadPolls(LoadPolls event, Emitter<PollState> emit) async {
    emit(const PollState.loading());
    try {
      final polls = await _repository.getPollsForTrip(event.tripId);
      emit(PollState.loaded(polls: polls));
    } catch (e) {
      emit(PollState.error(message: e.toString()));
    }
  }

  Future<void> _onCreatePoll(CreatePoll event, Emitter<PollState> emit) async {
    emit(const PollState.loading());
    try {
      await _repository.createPoll(
        tripId: event.tripId,
        title: event.title,
        slots: event.slots,
      );
      final polls = await _repository.getPollsForTrip(event.tripId);
      emit(PollState.loaded(polls: polls));
    } catch (e) {
      emit(PollState.error(message: e.toString()));
    }
  }
}
