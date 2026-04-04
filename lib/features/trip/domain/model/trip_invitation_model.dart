import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_invitation_model.freezed.dart';

@freezed
abstract class TripInvitationModel with _$TripInvitationModel {
  const factory TripInvitationModel({
    required String inviteUrl,
    required String token,
  }) = _TripInvitationModel;
}
