import 'package:json_annotation/json_annotation.dart';

import '../../domain/model/vote_config_model.dart';

part 'vote_config_dto.g.dart';

/// Converts [VoteMode] to/from the backend wire format (uppercase string).
class VoteModeConverter implements JsonConverter<VoteMode, String> {
  const VoteModeConverter();

  @override
  VoteMode fromJson(String json) => VoteMode.fromWire(json);

  @override
  String toJson(VoteMode mode) => mode.toWire();
}

@JsonSerializable()
class VoteConfigDto {
  final String tripId;
  @VoteModeConverter()
  final VoteMode mode;
  final DateTime updatedAt;

  const VoteConfigDto({
    required this.tripId,
    required this.mode,
    required this.updatedAt,
  });

  factory VoteConfigDto.fromJson(Map<String, dynamic> json) =>
      _$VoteConfigDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VoteConfigDtoToJson(this);

  VoteConfigModel toDomain() => VoteConfigModel(
        tripId: tripId,
        mode: mode,
        updatedAt: updatedAt,
      );
}

@JsonSerializable()
class VoteConfigRequestDto {
  @VoteModeConverter()
  final VoteMode mode;

  const VoteConfigRequestDto({required this.mode});

  factory VoteConfigRequestDto.fromJson(Map<String, dynamic> json) =>
      _$VoteConfigRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VoteConfigRequestDtoToJson(this);
}
