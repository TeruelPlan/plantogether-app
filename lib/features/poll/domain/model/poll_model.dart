import 'package:freezed_annotation/freezed_annotation.dart';

part 'poll_model.freezed.dart';

enum PollStatus { open, locked }

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
    required String createdBy,
    required DateTime createdAt,
    @Default([]) List<PollSlotModel> slots,
  }) = _PollModel;
}
