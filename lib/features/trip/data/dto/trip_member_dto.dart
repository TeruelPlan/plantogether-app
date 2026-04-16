import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/date_parser.dart';
import '../../domain/model/trip_member_model.dart';

part 'trip_member_dto.g.dart';

@JsonSerializable()
class TripMemberDto {
  final String id;
  final String displayName;
  final String role;
  final String joinedAt;
  final bool isMe;

  const TripMemberDto({
    required this.id,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    required this.isMe,
  });

  factory TripMemberDto.fromJson(Map<String, dynamic> json) =>
      _$TripMemberDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TripMemberDtoToJson(this);

  TripMemberModel toDomain() => TripMemberModel(
        memberId: id,
        displayName: displayName,
        role: role,
        joinedAt: parseDate(joinedAt),
        isMe: isMe,
      );
}
