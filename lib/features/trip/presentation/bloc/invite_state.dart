import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/model/trip_invitation_model.dart';

part 'invite_state.freezed.dart';

@freezed
sealed class InviteState with _$InviteState {
  const factory InviteState.initial() = _Initial;
  const factory InviteState.loading() = _Loading;
  const factory InviteState.loaded({required TripInvitationModel invitation}) =
      _Loaded;
  const factory InviteState.failure({required String message}) = _Failure;
}
