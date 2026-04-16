import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_member_model.freezed.dart';

@freezed
abstract class TripMemberModel with _$TripMemberModel {
  const factory TripMemberModel({
    required String memberId,
    required String displayName,
    required String role,
    required DateTime joinedAt,
    required bool isMe,
  }) = _TripMemberModel;
}
