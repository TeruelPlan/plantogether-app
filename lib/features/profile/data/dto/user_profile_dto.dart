import 'package:json_annotation/json_annotation.dart';
import 'package:plantogether_app/features/profile/domain/model/user_profile.dart';

part 'user_profile_dto.g.dart';

@JsonSerializable()
class UserProfileDto {
  final String displayName;
  final String? avatarUrl;

  const UserProfileDto({
    required this.displayName,
    this.avatarUrl,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);

  UserProfile toDomain() => UserProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
}
