import 'package:json_annotation/json_annotation.dart';

import '../../domain/model/poll_model.dart';

part 'poll_dto.g.dart';

@JsonSerializable()
class PollSlotDto {
  final String id;
  final String startDate;
  final String endDate;
  final int slotIndex;

  const PollSlotDto({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.slotIndex,
  });

  factory PollSlotDto.fromJson(Map<String, dynamic> json) =>
      _$PollSlotDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PollSlotDtoToJson(this);

  PollSlotModel toDomain() => PollSlotModel(
        id: id,
        startDate: startDate,
        endDate: endDate,
        slotIndex: slotIndex,
      );
}

@JsonSerializable()
class PollDto {
  final String id;
  final String tripId;
  final String title;
  final String status;
  final String createdBy;
  final String createdAt;
  final List<PollSlotDto>? slots;

  const PollDto({
    required this.id,
    required this.tripId,
    required this.title,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.slots,
  });

  factory PollDto.fromJson(Map<String, dynamic> json) =>
      _$PollDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PollDtoToJson(this);

  PollModel toDomain() => PollModel(
        id: id,
        tripId: tripId,
        title: title,
        status: status.toUpperCase() == 'LOCKED'
            ? PollStatus.locked
            : PollStatus.open,
        createdBy: createdBy,
        createdAt: createdAt,
        slots: slots?.map((s) => s.toDomain()).toList() ?? [],
      );
}
