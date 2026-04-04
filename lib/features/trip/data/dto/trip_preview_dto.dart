import 'package:json_annotation/json_annotation.dart';

import '../../domain/model/trip_preview_model.dart';

part 'trip_preview_dto.g.dart';

@JsonSerializable()
class TripPreviewDto {
  final String id;
  final String title;
  final String? description;
  final String? coverImageKey;
  final int memberCount;
  @JsonKey(name: 'isMember')
  final bool isMember;

  const TripPreviewDto({
    required this.id,
    required this.title,
    this.description,
    this.coverImageKey,
    required this.memberCount,
    required this.isMember,
  });

  factory TripPreviewDto.fromJson(Map<String, dynamic> json) =>
      _$TripPreviewDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TripPreviewDtoToJson(this);

  TripPreviewModel toDomain() => TripPreviewModel(
        id: id,
        title: title,
        description: description,
        coverImageKey: coverImageKey,
        memberCount: memberCount,
        isMember: isMember,
      );
}
