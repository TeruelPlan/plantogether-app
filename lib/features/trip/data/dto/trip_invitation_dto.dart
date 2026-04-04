import 'package:json_annotation/json_annotation.dart';

import '../../domain/model/trip_invitation_model.dart';

part 'trip_invitation_dto.g.dart';

@JsonSerializable()
class TripInvitationDto {
  final String inviteUrl;
  final String token;

  const TripInvitationDto({
    required this.inviteUrl,
    required this.token,
  });

  factory TripInvitationDto.fromJson(Map<String, dynamic> json) =>
      _$TripInvitationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TripInvitationDtoToJson(this);

  TripInvitationModel toDomain() => TripInvitationModel(
        inviteUrl: inviteUrl,
        token: token,
      );
}
