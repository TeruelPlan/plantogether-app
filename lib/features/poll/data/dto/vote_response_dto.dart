import 'package:json_annotation/json_annotation.dart';

import '../../domain/model/poll_model.dart';

part 'vote_response_dto.g.dart';

@JsonSerializable()
class VoteResponseDto {
  final String slotId;
  final String status;
  final String deviceId;

  const VoteResponseDto({
    required this.slotId,
    required this.status,
    required this.deviceId,
  });

  factory VoteResponseDto.fromJson(Map<String, dynamic> json) =>
      _$VoteResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VoteResponseDtoToJson(this);

  PollVoteModel toDomain() {
    switch (status.toUpperCase()) {
      case 'YES':
        return PollVoteModel(deviceId: deviceId, status: VoteStatus.yes);
      case 'MAYBE':
        return PollVoteModel(deviceId: deviceId, status: VoteStatus.maybe);
      case 'NO':
        return PollVoteModel(deviceId: deviceId, status: VoteStatus.no);
      default:
        throw ArgumentError('Unknown VoteStatus: $status');
    }
  }
}
