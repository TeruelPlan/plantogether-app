import 'package:freezed_annotation/freezed_annotation.dart';

part 'poll_model.freezed.dart';

enum PollStatus { open, locked }

enum VoteStatus { yes, maybe, no }

@freezed
abstract class PollSlotModel with _$PollSlotModel {
  const factory PollSlotModel({
    required String id,
    required DateTime startDate,
    required DateTime endDate,
    required int slotIndex,
  }) = _PollSlotModel;
}

@freezed
abstract class PollModel with _$PollModel {
  const factory PollModel({
    required String id,
    required String tripId,
    required String title,
    required PollStatus status,
    required String createdByMemberId,
    required DateTime createdAt,
    @Default([]) List<PollSlotModel> slots,
  }) = _PollModel;
}

@freezed
abstract class PollVoteModel with _$PollVoteModel {
  const factory PollVoteModel({
    required String tripMemberId,
    required VoteStatus status,
  }) = _PollVoteModel;
}

@freezed
abstract class PollSlotDetailModel with _$PollSlotDetailModel {
  const factory PollSlotDetailModel({
    required String id,
    required DateTime startDate,
    required DateTime endDate,
    required int slotIndex,
    required int score,
    @Default([]) List<PollVoteModel> votes,
  }) = _PollSlotDetailModel;
}

@freezed
abstract class PollMemberModel with _$PollMemberModel {
  const factory PollMemberModel({
    required String tripMemberId,
    required String role,
    required String displayName,
  }) = _PollMemberModel;
}

@freezed
abstract class PollDetailModel with _$PollDetailModel {
  const factory PollDetailModel({
    required String id,
    required String tripId,
    required String title,
    required PollStatus status,
    String? lockedSlotId,
    required String createdByMemberId,
    required DateTime createdAt,
    @Default([]) List<PollSlotDetailModel> slots,
    @Default([]) List<PollMemberModel> members,
  }) = _PollDetailModel;
}

extension PollSlotDetailModelX on PollSlotDetailModel {
  VoteStatus? myVoteFor(String myMemberId) {
    for (final vote in votes) {
      if (vote.tripMemberId == myMemberId) return vote.status;
    }
    return null;
  }
}
