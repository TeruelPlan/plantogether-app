import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_member_model.freezed.dart';

@freezed
abstract class TripMemberModel with _$TripMemberModel {
  const factory TripMemberModel({
    required String deviceId,
    required String displayName,
    required String role,
    required String joinedAt,
  }) = _TripMemberModel;
}
