import 'package:freezed_annotation/freezed_annotation.dart';

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
  }) = _TripModel;
}
