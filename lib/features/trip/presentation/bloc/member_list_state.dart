import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/model/trip_member_model.dart';

part 'member_list_state.freezed.dart';

@freezed
sealed class MemberListState with _$MemberListState {
  const factory MemberListState.initial() = _Initial;
  const factory MemberListState.loading() = _Loading;
  const factory MemberListState.loaded({
    required List<TripMemberModel> members,
  }) = _Loaded;
  const factory MemberListState.failure({required String message}) = _Failure;
}
