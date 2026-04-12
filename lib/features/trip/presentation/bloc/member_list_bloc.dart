import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/model/trip_member_model.dart';
import '../../domain/repository/trip_repository.dart';
import 'member_list_event.dart';
import 'member_list_state.dart';

class MemberListBloc extends Bloc<MemberListEvent, MemberListState> {
  final TripRepository _repository;

  MemberListBloc(this._repository) : super(const MemberListState.initial()) {
    on<LoadMembers>(_onLoadMembers, transformer: droppable());
    on<RemoveMember>(_onRemoveMember);
  }

  Future<void> _onLoadMembers(
    LoadMembers event,
    Emitter<MemberListState> emit,
  ) async {
    emit(const MemberListState.loading());
    try {
      final members = await _repository.getMembers(event.tripId);
      emit(MemberListState.loaded(members: members));
    } catch (e) {
      emit(MemberListState.failure(message: e.toString()));
    }
  }

  Future<void> _onRemoveMember(
    RemoveMember event,
    Emitter<MemberListState> emit,
  ) async {
    final previousMembers = state.whenOrNull(loaded: (members) => members);
    if (previousMembers == null) return;

    final optimisticMembers = previousMembers
        .where((m) => m.memberId != event.memberId)
        .toList();

    emit(MemberListState.loaded(members: optimisticMembers));

    try {
      await _repository.removeMember(event.tripId, event.memberId);
    } catch (e) {
      emit(MemberListState.loaded(members: previousMembers));
      emit(MemberListState.failure(message: e.toString()));
    }
  }
}
