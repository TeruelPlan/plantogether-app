import 'package:json_annotation/json_annotation.dart';

import '../../domain/model/current_member_model.dart';

part 'current_member_dto.g.dart';

@JsonSerializable()
class CurrentMemberDto {
  final String tripMemberId;
  final String displayName;
  final String role;

  const CurrentMemberDto({
    required this.tripMemberId,
    required this.displayName,
    required this.role,
  });

  factory CurrentMemberDto.fromJson(Map<String, dynamic> json) =>
      _$CurrentMemberDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentMemberDtoToJson(this);

  CurrentMemberModel toDomain() => CurrentMemberModel(
        tripMemberId: tripMemberId,
        displayName: displayName,
        role: role,
      );
}
