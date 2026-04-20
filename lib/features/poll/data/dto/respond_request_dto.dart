import 'package:json_annotation/json_annotation.dart';

import '../../domain/model/poll_model.dart';

part 'respond_request_dto.g.dart';

String voteStatusToWire(VoteStatus status) {
  switch (status) {
    case VoteStatus.yes:
      return 'YES';
    case VoteStatus.maybe:
      return 'MAYBE';
    case VoteStatus.no:
      return 'NO';
  }
}

@JsonSerializable()
class RespondRequestDto {
  final String slotId;
  final String status;

  const RespondRequestDto({required this.slotId, required this.status});

  factory RespondRequestDto.from({
    required String slotId,
    required VoteStatus status,
  }) =>
      RespondRequestDto(slotId: slotId, status: voteStatusToWire(status));

  factory RespondRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RespondRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RespondRequestDtoToJson(this);
}
