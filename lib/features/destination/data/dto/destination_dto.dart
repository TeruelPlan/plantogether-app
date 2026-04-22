import 'package:json_annotation/json_annotation.dart';

import '../../domain/model/destination_model.dart';

part 'destination_dto.g.dart';

@JsonSerializable()
class DestinationVotesDto {
  final int totalVotes;
  final Map<String, int>? rankVotes;

  const DestinationVotesDto({
    this.totalVotes = 0,
    this.rankVotes,
  });

  factory DestinationVotesDto.fromJson(Map<String, dynamic> json) =>
      _$DestinationVotesDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DestinationVotesDtoToJson(this);

  DestinationVotesModel toDomain() => DestinationVotesModel(
        totalVotes: totalVotes,
        rankVotes: rankVotes ?? const {},
      );
}

@JsonSerializable()
class DestinationDto {
  final String id;
  final String tripId;
  final String name;
  final String? description;
  final String? imageKey;
  final double? estimatedBudget;
  final String? currency;
  final String? externalUrl;
  final String proposedByDeviceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DestinationVotesDto? votes;

  const DestinationDto({
    required this.id,
    required this.tripId,
    required this.name,
    this.description,
    this.imageKey,
    this.estimatedBudget,
    this.currency,
    this.externalUrl,
    required this.proposedByDeviceId,
    required this.createdAt,
    required this.updatedAt,
    this.votes,
  });

  factory DestinationDto.fromJson(Map<String, dynamic> json) =>
      _$DestinationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DestinationDtoToJson(this);

  DestinationModel toDomain() => DestinationModel(
        id: id,
        tripId: tripId,
        name: name,
        description: description,
        imageKey: imageKey,
        estimatedBudget: estimatedBudget,
        currency: currency,
        externalUrl: externalUrl,
        proposedByDeviceId: proposedByDeviceId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        votes: votes?.toDomain() ?? const DestinationVotesModel(),
      );
}

@JsonSerializable(includeIfNull: false)
class ProposeDestinationRequestDto {
  final String name;
  final String? description;
  final String? imageKey;
  final double? estimatedBudget;
  final String? currency;
  final String? externalUrl;

  const ProposeDestinationRequestDto({
    required this.name,
    this.description,
    this.imageKey,
    this.estimatedBudget,
    this.currency,
    this.externalUrl,
  });

  factory ProposeDestinationRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ProposeDestinationRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProposeDestinationRequestDtoToJson(this);
}
