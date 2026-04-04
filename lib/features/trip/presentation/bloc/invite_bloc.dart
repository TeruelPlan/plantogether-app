import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repository/trip_repository.dart';
import 'invite_event.dart';
import 'invite_state.dart';

class InviteBloc extends Bloc<InviteEvent, InviteState> {
  final TripRepository _repository;

  InviteBloc(this._repository) : super(const InviteState.initial()) {
    on<LoadInvitation>(_onLoadInvitation);
  }

  Future<void> _onLoadInvitation(
    LoadInvitation event,
    Emitter<InviteState> emit,
  ) async {
    emit(const InviteState.loading());
    try {
      final invitation = await _repository.getInvitation(event.tripId);
      emit(InviteState.loaded(invitation: invitation));
    } catch (e) {
      emit(InviteState.failure(message: e.toString()));
    }
  }
}
