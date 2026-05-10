import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/model/current_member_model.dart';
import '../../domain/repository/trip_repository.dart';

sealed class CurrentMemberState {
  const CurrentMemberState();
}

final class CurrentMemberLoading extends CurrentMemberState {
  const CurrentMemberLoading();
}

final class CurrentMemberLoaded extends CurrentMemberState {
  final CurrentMemberModel member;
  const CurrentMemberLoaded(this.member);
}

final class CurrentMemberFailed extends CurrentMemberState {
  final Object error;
  const CurrentMemberFailed(this.error);
}

class CurrentMemberCubit extends Cubit<CurrentMemberState> {
  final TripRepository _repository;
  final String _tripId;

  CurrentMemberCubit(this._repository, this._tripId)
      : super(const CurrentMemberLoading());

  Future<void> load({bool forceRefresh = false}) async {
    if (!forceRefresh && state is CurrentMemberLoaded) return;
    emit(const CurrentMemberLoading());
    try {
      final member =
          await _repository.getCurrentMember(_tripId, forceRefresh: forceRefresh);
      emit(CurrentMemberLoaded(member));
    } catch (e) {
      emit(CurrentMemberFailed(e));
    }
  }

  String? get tripMemberIdOrNull =>
      switch (state) { CurrentMemberLoaded(:final member) => member.tripMemberId, _ => null };
}
