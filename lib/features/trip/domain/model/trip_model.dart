import 'package:freezed_annotation/freezed_annotation.dart';

import 'trip_member_model.dart';

part 'trip_model.freezed.dart';

@freezed
abstract class TripModel with _$TripModel {
  const factory TripModel({
    required String id,
    required String title,
    String? description,
    required String status,
    String? referenceCurrency,
    String? startDate,
    String? endDate,
    required String createdBy,
    required String createdAt,
    String? updatedAt,
    @Default(0) int memberCount,
    @Default([]) List<TripMemberModel> members,
  }) = _TripModel;
}
