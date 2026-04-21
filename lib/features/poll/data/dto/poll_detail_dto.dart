import 'package:json_annotation/json_annotation.dart';

import '../../domain/model/poll_model.dart';

part 'poll_detail_dto.g.dart';

VoteStatus _voteStatusFromWire(String raw) {
  switch (raw.toUpperCase()) {
    case 'YES':
      return VoteStatus.yes;
    case 'MAYBE':
      return VoteStatus.maybe;
    case 'NO':
      return VoteStatus.no;
    default:
      throw ArgumentError('Unknown VoteStatus: $raw');
  }
}

PollStatus _pollStatusFromWire(String raw) {
  switch (raw.toUpperCase()) {
    case 'OPEN':
      return PollStatus.open;
    case 'LOCKED':
      return PollStatus.locked;
    default:
      throw ArgumentError('Unknown PollStatus: $raw');
  }
}

@JsonSerializable()
class PollVoteDto {
  final String deviceId;
  final String status;

  const PollVoteDto({required this.deviceId, required this.status});

  factory PollVoteDto.fromJson(Map<String, dynamic> json) =>
      _$PollVoteDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PollVoteDtoToJson(this);

  PollVoteModel toDomain() => PollVoteModel(
        deviceId: deviceId,
        status: _voteStatusFromWire(status),
      );
}

@JsonSerializable()
class PollSlotDetailDto {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final int slotIndex;
  final int score;
  final List<PollVoteDto>? votes;

  const PollSlotDetailDto({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.slotIndex,
    required this.score,
    this.votes,
  });

  factory PollSlotDetailDto.fromJson(Map<String, dynamic> json) =>
      _$PollSlotDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PollSlotDetailDtoToJson(this);

  PollSlotDetailModel toDomain() => PollSlotDetailModel(
        id: id,
        startDate: startDate,
        endDate: endDate,
        slotIndex: slotIndex,
        score: score,
        votes: votes?.map((v) => v.toDomain()).toList() ?? const [],
      );
}

@JsonSerializable()
class PollMemberDto {
  final String deviceId;
  final String role;
  final String displayName;

  const PollMemberDto({
    required this.deviceId,
    required this.role,
    required this.displayName,
  });

  factory PollMemberDto.fromJson(Map<String, dynamic> json) =>
      _$PollMemberDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PollMemberDtoToJson(this);

  PollMemberModel toDomain() => PollMemberModel(
        deviceId: deviceId,
        role: role,
        displayName: displayName,
      );
}

@JsonSerializable()
class PollDetailDto {
  final String id;
  final String tripId;
  final String title;
  final String status;
  final String? lockedSlotId;
  final String createdBy;
  final DateTime createdAt;
  final List<PollSlotDetailDto>? slots;
  final List<PollMemberDto>? members;

  const PollDetailDto({
    required this.id,
    required this.tripId,
    required this.title,
    required this.status,
    this.lockedSlotId,
    required this.createdBy,
    required this.createdAt,
    this.slots,
    this.members,
  });

  factory PollDetailDto.fromJson(Map<String, dynamic> json) =>
      _$PollDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PollDetailDtoToJson(this);

  PollDetailModel toDomain() => PollDetailModel(
        id: id,
        tripId: tripId,
        title: title,
        status: _pollStatusFromWire(status),
        lockedSlotId: lockedSlotId,
        createdBy: createdBy,
        createdAt: createdAt,
        slots: slots?.map((s) => s.toDomain()).toList() ?? const [],
        members: members?.map((m) => m.toDomain()).toList() ?? const [],
      );
}
