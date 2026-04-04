import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_preview_model.freezed.dart';

@freezed
abstract class TripPreviewModel with _$TripPreviewModel {
  const factory TripPreviewModel({
    required String id,
    required String title,
    String? description,
    String? coverImageKey,
    required int memberCount,
    required bool isMember,
  }) = _TripPreviewModel;
}
