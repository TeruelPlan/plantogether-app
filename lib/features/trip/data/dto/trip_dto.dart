import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/date_parser.dart';
import '../../domain/model/trip_model.dart';
import 'trip_member_dto.dart';

part 'trip_dto.g.dart';

@JsonSerializable()
class TripDto {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String? referenceCurrency;
  final String? startDate;
  final String? endDate;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  final int? memberCount;
  final List<TripMemberDto>? members;

  const TripDto({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.referenceCurrency,
    this.startDate,
    this.endDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount,
    this.members,
  });

  factory TripDto.fromJson(Map<String, dynamic> json) =>
      _$TripDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TripDtoToJson(this);

  TripModel toDomain() => TripModel(
        id: id,
        title: title,
        description: description,
        status: status,
        referenceCurrency: referenceCurrency,
        startDate: parseDateOrNull(startDate),
        endDate: parseDateOrNull(endDate),
        createdBy: createdBy,
        createdAt: parseDate(createdAt),
        updatedAt: parseDateOrNull(updatedAt),
        memberCount: memberCount ?? members?.length ?? 0,
        members: members?.map((m) => m.toDomain()).toList() ?? [],
      );
}
