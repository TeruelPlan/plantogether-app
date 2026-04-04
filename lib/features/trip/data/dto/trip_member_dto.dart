import 'package:json_annotation/json_annotation.dart';

import '../../domain/model/trip_member_model.dart';

part 'trip_member_dto.g.dart';

@JsonSerializable()
class TripMemberDto {
  final String deviceId;
  final String displayName;
  final String role;
  final String joinedAt;

  const TripMemberDto({
    required this.deviceId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  factory TripMemberDto.fromJson(Map<String, dynamic> json) =>
      _$TripMemberDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TripMemberDtoToJson(this);

  TripMemberModel toDomain() => TripMemberModel(
        deviceId: deviceId,
        displayName: displayName,
        role: role,
        joinedAt: joinedAt,
      );
}
