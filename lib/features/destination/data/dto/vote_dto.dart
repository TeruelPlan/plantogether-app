import 'package:json_annotation/json_annotation.dart';

part 'vote_dto.g.dart';

@JsonSerializable(includeIfNull: false)
class CastVoteRequestDto {
  final int? rank;

  const CastVoteRequestDto({this.rank});

  factory CastVoteRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CastVoteRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CastVoteRequestDtoToJson(this);
}

@JsonSerializable()
class VoteResponseDto {
  final String voterDeviceId;
  final String destinationId;
  final int? rank;

  const VoteResponseDto({
    required this.voterDeviceId,
    required this.destinationId,
    this.rank,
  });

  factory VoteResponseDto.fromJson(Map<String, dynamic> json) =>
      _$VoteResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VoteResponseDtoToJson(this);
}
