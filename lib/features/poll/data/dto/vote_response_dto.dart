import 'package:json_annotation/json_annotation.dart';

import '../../domain/model/poll_model.dart';

part 'vote_response_dto.g.dart';

@JsonSerializable()
class VoteResponseDto {
  final String slotId;
  final String status;
  final String deviceId;
  final String? tripMemberId;

  const VoteResponseDto({
    required this.slotId,
    required this.status,
    required this.deviceId,
    this.tripMemberId,
  });

  factory VoteResponseDto.fromJson(Map<String, dynamic> json) =>
      _$VoteResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VoteResponseDtoToJson(this);

  PollVoteModel toDomain() {
    final voteStatus = switch (status.toUpperCase()) {
      'YES' => VoteStatus.yes,
      'MAYBE' => VoteStatus.maybe,
      'NO' => VoteStatus.no,
      _ => throw ArgumentError('Unknown VoteStatus: $status'),
    };
    return PollVoteModel(
      deviceId: deviceId,
      tripMemberId: tripMemberId,
      status: voteStatus,
    );
  }
}
